#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Paste Image to Claude
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🖼️
# @raycast.packageName Utilities

OUTDIR="$HOME/Pictures/clip-img"
mkdir -p "$OUTDIR"
OUTFILE="$OUTDIR/$(date +%Y%m%d-%H%M%S).png"

osascript << EOF
try
  set png_data to the clipboard as «class PNGf»
  set fileRef to open for access POSIX file "$OUTFILE" with write permission
  write png_data to fileRef
  close access fileRef
on error
  display notification "No image found in clipboard" with title "Paste Image to Claude"
  error "No image found in clipboard"
end try

-- Put the saved file on the clipboard as a file reference (same as Finder copy)
set the clipboard to (POSIX file "$OUTFILE")

delay 0.3

-- Simulate Cmd+V so Claude Code picks it up as a file attachment
tell application "System Events"
  keystroke "v" using command down
end tell
EOF
