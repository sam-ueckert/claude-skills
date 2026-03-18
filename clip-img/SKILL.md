---
name: clip-img
description: Paste clipboard images into Claude Code as file attachments using a Raycast hotkey. Not a Claude skill — a Raycast script utility that bridges the terminal image paste gap.
---

# Paste Image to Claude

A Raycast script that lets you paste clipboard images into Claude Code as proper file attachments.

## The Problem

Claude Code runs in a terminal. Terminals can't receive raw image data from the clipboard — pressing Cmd+V just types a "v". This script bridges the gap.

## How It Works

1. Reads the image from your clipboard
2. Saves it to `~/Pictures/clip-img/`
3. Puts the saved file back on the clipboard as a file reference
4. Simulates Cmd+V — Claude Code sees it as a file attachment, same as copying a file from Finder

## Setup

### 1. Place the script

Copy `scripts/clip-img.sh` to `~/raycast-scripts/` and make it executable:

```bash
mkdir -p ~/raycast-scripts
cp scripts/clip-img.sh ~/raycast-scripts/
chmod +x ~/raycast-scripts/clip-img.sh
```

### 2. Add the directory to Raycast

Open Raycast Settings → Extensions → Script Commands. Click **Add Directories** and select `~/raycast-scripts`.

The "Paste Image to Claude" command will appear immediately under Script Commands.

### 3. Assign a hotkey

Click the **Paste Image to Claude** row and set a hotkey in the Hotkey column (e.g. `⌥⇧V`).

![Raycast script command with hotkey assigned]

### 4. Grant Accessibility permission

The script uses `System Events` to simulate Cmd+V, which requires Accessibility access.

Go to **System Settings → Privacy & Security → Accessibility** and ensure **Raycast** is enabled.

### 5. Allow Claude Code to read images without prompting

Add this to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Read(/Users/<you>/Pictures/clip-img/*)"
    ]
  }
}
```

## Usage

1. Copy any image to your clipboard (screenshot, browser image, etc.)
2. Click into the Claude Code input
3. Press your hotkey (`⌥⇧V`)
4. The image attaches above the prompt — same as pasting a file from Finder

## Files

- `scripts/clip-img.sh` — the Raycast script
- Saved images land in `~/Pictures/clip-img/` (override with `CLIP_IMG_DIR` env var)
