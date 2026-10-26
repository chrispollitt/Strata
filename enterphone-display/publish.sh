#!/bin/bash
# Rebuild the directory image and copy it to the Pi.
# Usage: publish.sh [user@]pi-host   (default: pi@enterphone)
host="${1:-pi@enterphone}"
cd "${BASH_SOURCE[0]%/*}" || exit 1
node directory.mjs --cols 3 --out directory || exit 1
scp directory.png "$host:/var/lib/enterphone-display/directory.png"
