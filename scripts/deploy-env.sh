#!/bin/bash

# This script does the following:
# - places symlinks for all files in the current directory, including
# directories, dotfiles and dot directories, to HOME_DIR (default is $HOME);
# - creates backups of existing files in HOME_DIR by renaming them and
# appending a timestamp + ".bak";

set -euo pipefail  # exit on error

# Default values
SOURCE_DIR=$PWD
HOME_DIR=$HOME/test
DRY_RUN=false
VERSION="1.1.0"

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options
  -t <dir>    Set target directory (default: \$HOME/dir)
  -h          Show this help message
  -v          Show version
EOF
}

show_version() {
  echo "$(basename "$0") version $VERSION"
}

# Parse options
while getopts ":t:hv" opt; do
  case $opt in
    t) HOME_DIR="$OPTARG" ;;
    h) show_help; exit 0 ;;
    v) show_version; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done
shift $((OPTIND-1))

deploy_dotfiles() {
  # Include hidden files (dotfiles) and ignore patterns that match nothing
  shopt -s dotglob nullglob

  # Loop through every file or directory in SOURCE_DIR.
  for item in "$SOURCE_DIR"/*; do

    # Extract a file name from the full path to the file.
    base=$(basename "$item")

    # Build the target path
    target="$HOME_DIR/$base"

    # Skip if already correctly linked
    if [[ -L "$target" && "$(readlink "$target")" == "$item" ]]; then
      echo "Already linked: $target"
      continue
    fi

    # Backup if file or symlink exists
    if [[ -e "$target" || -L "$target" ]]; then
      timestamp=$(date +'%F_%H-%M-%S')
      mv "$target" "$target.$timestamp.bak" 
      echo "Backed up: $target -> $target.$timestamp.bak"
    fi

    # Create symlink
    ln -s "$item" "$target"
    echo "Symlinked: $item to $target"

  done
  shopt -u dotglob nullglob
}

deploy_dotfiles

