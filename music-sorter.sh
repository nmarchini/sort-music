#!/usr/bin/env bash
#
# music-sorter.sh — sort audio files into folders by their Genre tag
#
# Uses exiftool's -Directory tag to MOVE files (not copy) into
# subfolders named after their Genre metadata, with a fallback
# folder for anything missing that tag.
#
# https://github.com/<you>/music-sorter

set -euo pipefail

# ---- defaults ---------------------------------------------------
SOURCE=""
DEST=""
UNSORTED_NAME="Unsorted"
EXTENSIONS=(flac mp3 wav aiff m4a)
DRY_RUN=0
VERBOSE=0

# ---- helpers ------------------------------------------------------
usage() {
  cat <<'EOF'
music-sorter.sh — sort audio files into folders by Genre tag

USAGE:
  music-sorter.sh -s SOURCE -d DEST [OPTIONS]

REQUIRED:
  -s, --source DIR       Folder to scan recursively for audio files
  -d, --dest DIR         Base folder to sort files INTO
                          (each genre becomes a subfolder here)

OPTIONS:
  -u, --unsorted NAME    Subfolder name (under DEST) for files with no
                          Genre tag. Default: "Unsorted"
  -e, --ext EXT          File extension to include. Repeatable.
                          Default: flac mp3 wav aiff m4a
  -n, --dry-run          Show what would happen without moving anything
  -v, --verbose          Also print each file as it's moved (source name
                          and the tag exiftool used), on top of the
                          live progress count shown by default
  -h, --help             Show this help and exit

EXAMPLES:
  # Preview what would happen first (always do this on a new library)
  music-sorter.sh -s ~/Music/Incoming -d ~/Music/Sorted --dry-run

  # Actually sort it
  music-sorter.sh -s ~/Music/Incoming -d ~/Music/Sorted

  # Only handle mp3 and flac, custom fallback folder name
  music-sorter.sh -s . -d /Volumes/PRI/_Tracks -u "No Genre" -e mp3 -e flac

  # Watch every file move by name (useful when tracking down a
  # specific file, or just to see it working on a small batch)
  music-sorter.sh -s ~/Music/Incoming -d ~/Music/Sorted --verbose

PROGRESS:
  A real run shows a live "N of M files complete" counter by default,
  since sorting a large library can otherwise run silently for a long
  time. Pass --verbose to also see each file's name as it's moved.
  ExifTool prints a final summary line (files updated / unchanged /
  errors) once the run finishes either way.

WARNING:
  This MOVES files, it does not copy them. Run with --dry-run first,
  especially the first time you use it on a given folder.

KNOWN LIMITATIONS:
  - Genre matching is exact after normalization (trimmed, collapsed
    whitespace, title-cased). Wildly inconsistent tagging (e.g. "rock",
    "Rock ", "ROCK") is merged into one folder, but tags that differ in
    more than case/whitespace still create separate folders.
  - If two source files would land at the same destination path,
    exiftool's default behavior is to skip the move for the conflicting
    file and report an error for it, rather than overwrite. Check the
    output for "Error" lines after a real run.
EOF
}

err() { echo "Error: $*" >&2; exit 1; }

# ---- parse args -----------------------------------------------------
CUSTOM_EXT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--source)   SOURCE="$2"; shift 2 ;;
    -d|--dest)     DEST="$2"; shift 2 ;;
    -u|--unsorted) UNSORTED_NAME="$2"; shift 2 ;;
    -e|--ext)
      if [[ $CUSTOM_EXT -eq 0 ]]; then EXTENSIONS=(); CUSTOM_EXT=1; fi
      EXTENSIONS+=("$2"); shift 2 ;;
    -n|--dry-run)  DRY_RUN=1; shift ;;
    -v|--verbose)  VERBOSE=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) err "Unknown option: $1 (see --help)" ;;
  esac
done

# ---- validate -----------------------------------------------------
command -v exiftool >/dev/null 2>&1 || err "exiftool is not installed.
  macOS:  brew install exiftool
  Linux:  sudo apt install libimage-exiftool-perl   (Debian/Ubuntu)
          sudo dnf install perl-Image-ExifTool      (Fedora)"

[[ -n "$SOURCE" ]] || err "Missing required -s/--source. See --help."
[[ -n "$DEST"   ]] || err "Missing required -d/--dest. See --help."
[[ -d "$SOURCE" ]] || err "Source folder does not exist: $SOURCE"

# --unsorted gets embedded directly into a Perl expression that exiftool
# evaluates (see the dry-run -p format below). Reject anything that could
# break out of that string instead of trying to escape it correctly.
if [[ "$UNSORTED_NAME" =~ [\"\'\\\;\$\`] ]]; then
  err "--unsorted may not contain quotes, backslashes, \$, \`, or ;. Got: $UNSORTED_NAME"
fi

UNSORTED_DIR="${DEST%/}/${UNSORTED_NAME}"

# Make sure we can actually write to the destination before touching
# anything. mkdir -p is a no-op if it already exists.
mkdir -p -- "$DEST" 2>/dev/null || err "Cannot create/access destination: $DEST"
[[ -w "$DEST" ]] || err "Destination is not writable: $DEST"

# ---- build the ext flags array -------------------------------------
EXT_ARGS=()
for ext in "${EXTENSIONS[@]}"; do
  EXT_ARGS+=(-ext "$ext")
done

# ---- dry run: preview only, no writes ------------------------------
if [[ $DRY_RUN -eq 1 ]]; then
  echo "Dry run — no files will be moved."
  echo "Source:    $SOURCE"
  echo "Dest base: ${DEST%/}"
  echo "Fallback:  $UNSORTED_DIR"
  echo "Extensions: ${EXTENSIONS[*]}"
  echo ""
  exiftool -m -r "${EXT_ARGS[@]}" -q \
    -p '${FileName} -> '"${DEST%/}"'/${Genre;s/[\/\\:]/ - /g;s/^\s+|\s+$//g;s/\s+/ /g;s/(\w+)/\u\L$1/g;$_ ||= "'"$UNSORTED_NAME"'"}' \
    "$SOURCE"
  exit 0
fi

# ---- the real move --------------------------------------------------
echo "Sorting audio files from: $SOURCE"
echo "Into:                     ${DEST%/}"
echo "Files without a Genre tag go to: $UNSORTED_DIR"
echo ""

# -progress shows a live "N of M files complete" counter so a large
# library doesn't run silently for minutes with no feedback. -v0 adds
# a line per file (name + new location) on top of that, if requested.
MOVE_FLAGS=(-progress)
[[ $VERBOSE -eq 1 ]] && MOVE_FLAGS+=(-v0)

exiftool -m -r "${EXT_ARGS[@]}" "${MOVE_FLAGS[@]}" \
  -Directory="$UNSORTED_DIR" \
  '-Directory<'"${DEST%/}"'/${Genre;s/[\/\\:]/ - /g;s/^\s+|\s+$//g;s/\s+/ /g;s/(\w+)/\u\L$1/g}' \
  "$SOURCE"

echo ""
echo "Done."