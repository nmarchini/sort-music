# 🎧 music-sorter

A small Bash + [ExifTool](https://exiftool.org/) script that sorts a messy folder of DJ tracks into subfolders by **Genre** tag — built for feeding a Rekordbox library (other Music programs too).

## Contents

- [Why do you need this?](#why-do-you-need-this)
- [The tool](#the-tool)
- [Requirements](#requirements)
- [Usage](#usage)
- [How it works](#how-it-works)
- [License](#license)

## 🤔 Why do you need this?

I download music tracks for DJing from lots of different places and then import them into my music tool (Rekordbox). As I'm not that disciplined, the files stay in the folder they were downloaded to until I manually move them somewhere else — usually by just copying the whole folder onto my external 1TB USB drive where I keep my Rekordbox library. That leaves me with a mess of folders.

Almost all the music I download has a Genre tag, or I'll add one in Rekordbox myself. That tag is what this script uses to organize and move the tracks to their destination.

Once I run the tool, I use Rekordbox's **Missing Files** menu option to relink the moved files.

**Before**

```text
── beatport_tracks_2026-02
│   ├── Matthew Sona - Troja  (Original Mix).aiff
│   ├── Maximo Gambini, JUAN BUITRAGO, Julian Moreno - Blended (Original Mix).aiff
│   └── Nils Nuernberg - Seduction (Original).aiff
├── beatport_tracks_2026-06
│   ├── M-Sol DEEP, AALEX - Illusions (Instrumental Mix).aiff
│   └── M-Sol DEEP, AALEX - Illusions (Original Mix).aiff
├── Benja_Molina__Ilias_Katelanos__Plecta-Pandora-Original_Mix-77716483.mp3
├── Bicep - Glue (COQUEIT & After Burn Unnoficial remix).wav
├── Binary Finary - 1998 (MOSHIC 2022 REMIX).aiff
├── Born Slippy - Underworld (Cristian Caro Unofficial Remix).wav
├── Breeder - Tyrantanic (Federico Cabrera & Martin Gardoqui Unofficial Remix).wav
├── Deep Progressive - Organic
│   ├── 3.14 (AR) - Reminder (Juan Deminicis & NUFECTS Remix).mp3
│   ├── 84 Avenue - Delight (Extended Mix).mp3
│   ├── Above & Beyond, PROFF - Palermo (Extended Mix) (2).mp3
│
```

**After**

```text
├── Nu Disco  -  Indie Dance
├── Organic House
├── Progressive
├── Progressive Electronic
├── Progressive House
├── Progressive Trance
├── Psy-Trance
├── Soulful House
├── Tech House
├── Tech House - Tribal
├── Tech Trance
├── Techno
├── Techno - Melodic - Progressive House
├── Techno (Deep)
├── Techno (Peak Time  -  Driving)
├── Techno (Peak Time)
├── Techno (Psy)
├── Unsorted
```

## 🛠️ The tool

Files with no genre metadata fall back to an "Unsorted" folder instead of causing an error, so a first-pass run never leaves anything behind.

> ⚠️ **This moves files, not copies them.** Run with `--dry-run` first, especially the first time you point it at a real library.

## 📦 Requirements

- **ExifTool**
  - macOS: `brew install exiftool`
  - Debian/Ubuntu: `sudo apt install libimage-exiftool-perl`
  - Fedora: `sudo dnf install perl-Image-ExifTool`
- Bash (macOS and Linux ship with a compatible version)

## 🚀 Usage

```bash
chmod +x music-sorter.sh

# Preview first — always do this before a real run
./music-sorter.sh -s ~/Music/Incoming -d ~/Music/Sorted --dry-run

# Actually sort the files
./music-sorter.sh -s ~/Music/Incoming -d ~/Music/Sorted
```

Example of Dry run
```bash
./music-sorter.sh -s /Users/username/Downloads/JasonStill -d /Volumes/PRI/_tracks --dry-run
Dry run — no files will be moved.
Source:    /Users/username/Downloads/JasonStill
Dest base: /Volumes/PRI/_tracks
Fallback:  /Volumes/PRI/_tracks/Unsorted
Extensions: flac mp3 wav aiff m4a

Jason Still - Solar Promise - 05 Festival Continuum.aiff -> /Volumes/PRI/_tracks/Progressive House
Jason Still - Solar Promise - 01 Clubbing Lantern.aiff -> /Volumes/PRI/_tracks/Trance (Raw - Deep - Hypnotic)
Jason Still - Solar Promise - 06 Modern Vision.aiff -> /Volumes/PRI/_tracks/Progressive House
Jason Still - Solar Promise - 04 Electric Alignment.aiff -> /Volumes/PRI/_tracks/Progressive House
Jason Still - Solar Promise - 08 Nightfall Elevation.aiff -> /Volumes/PRI/_tracks/Progressive House
Jason Still - Solar Promise - 02 Dancing Mirage.aiff -> /Volumes/PRI/_tracks/Progressive House
Jason Still - Solar Promise - 10 Starlit Twilight.aiff -> /Volumes/PRI/_tracks/Progressive House
Jason Still - Solar Promise - 07 Moonlit Compass.aiff -> /Volumes/PRI/_tracks/Progressive House
Jason Still - Solar Promise - 03 Dynamic Tides.aiff -> /Volumes/PRI/_tracks/Progressive House
Jason Still - Solar Promise - 09 Solar Promise.aiff -> /Volumes/PRI/_tracks/Progressive House
```


### Options

| Flag             | Description                                                   | Default                        |
|------------------|-----------------------------------------------------------------|--------------------------------|
| `-s, --source`   | Folder to scan recursively for audio files (**required**)      | —                              |
| `-d, --dest`     | Base folder to sort files into; each genre becomes a subfolder (**required**) | —                              |
| `-u, --unsorted` | Subfolder name (under `dest`) for files with no Genre tag      | `Unsorted`                     |
| `-e, --ext`      | File extension to include. Repeatable                          | `flac` `mp3` `wav` `aiff` `m4a` |
| `-n, --dry-run`  | Print what would happen without moving anything                | off                            |
| `-h, --help`     | Show usage                                                      | —                              |

### Examples

```bash
# Only sort mp3 and flac, with a custom fallback folder name
./music-sorter.sh -s . -d /Volumes/PRI/_Tracks -u "No Genre" -e mp3 -e flac

# Nested genres (e.g. Genre tag "Electronic/Techno") become
# "Electronic - Techno" subfolders, since "/" isn't safe in a path
./music-sorter.sh -s ~/Downloads/NewTracks -d ~/Music/Library
```

## ⚙️ How it works

ExifTool's `-Directory` tag can be assigned twice in one command. The first
assignment sets a fallback destination; the second tries to overwrite it
using the file's `Genre` tag. If a file has no Genre tag, the second
assignment silently fails and the fallback from the first sticks — so files
without genre metadata land in the fallback folder instead of erroring out.

Genre values containing `/` (e.g. `Hip Hop/Rap`) are rewritten to use ` - `
instead, since `/` would otherwise be read as a folder separator.

## 📄 License

MIT — see [LICENSE](LICENSE).
