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
EXTENSIONS=(flac mp3 wav aiff)
DRY_RUN=0

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
                          Default: flac mp3 wav aiff
  -n, --dry-run          Show what would happen without moving anything
  -h, --help             Show this help and exit

EXAMPLES:
  # Preview what would happen first (always do this on a new library)
  music-sorter.sh -s ~/Music/Incoming -d ~/Music/Sorted --dry-run

  # Actually sort it
  music-sorter.sh -s ~/Music/Incoming -d ~/Music/Sorted

  # Only handle mp3 and flac, custom fallback folder name
  music-sorter.sh -s . -d /Volumes/PRI/_Tracks -u "No Genre" -e mp3 -e flac

WARNING:
  This MOVES files, it does not copy them. Run with --dry-run first,
  especially the first time you use it on a given folder.
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

UNSORTED_DIR="${DEST%/}/${UNSORTED_NAME}"

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
    -p '${FileName} -> '"${DEST%/}"'/${Genre;s/\// - /g;$_ ||= "'"$UNSORTED_NAME"'"}' \
    "$SOURCE"
  exit 0
fi

# ---- the real move --------------------------------------------------
echo "Sorting audio files from: $SOURCE"
echo "Into:                     ${DEST%/}"
echo "Files without a Genre tag go to: $UNSORTED_DIR"
echo ""

exiftool -m -r "${EXT_ARGS[@]}" \
  -Directory="$UNSORTED_DIR" \
  '-Directory<'"${DEST%/}"'/${Genre;s/\// - /g}' \
  "$SOURCE"

echo ""
echo "Done."
