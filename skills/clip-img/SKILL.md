---
name: clip-img
description: "macOS-only Raycast script to paste clipboard images into a terminal-based AI agent as file attachments. Use when the user wants to paste/attach a screenshot or clipboard image to a terminal agent like Claude Code. Requires macOS with Raycast installed."
user-invokable: true
args: []
---

# Paste Image to Agent

A Raycast script that lets you paste clipboard images into a terminal-based AI agent as proper file attachments.

## The Problem

Terminal-based AI agents can't receive raw image data from the clipboard — pressing Cmd+V just types a "v". This script bridges the gap.

## How It Works

1. Reads the image from your clipboard
2. Saves it to `~/Pictures/clip-img/`
3. Puts the saved file back on the clipboard as a file reference
4. Simulates Cmd+V — the agent sees it as a file attachment, same as copying a file from Finder

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

The "Paste Image to Agent" command will appear immediately under Script Commands.

### 3. Assign a hotkey

Click the command row and set a hotkey in the Hotkey column (e.g. `⌥⇧V`).

### 4. Grant Accessibility permission

The script uses `System Events` to simulate Cmd+V, which requires Accessibility access.

Go to **System Settings → Privacy & Security → Accessibility** and ensure **Raycast** is enabled.

### 5. Allow the agent to read images

Add the image directory to your agent's allowed read paths. For example, in your agent's settings, allow reads from `~/Pictures/clip-img/*`.

## Usage

1. Copy any image to your clipboard (screenshot, browser image, etc.)
2. Click into the agent's terminal input
3. Press your hotkey (`⌥⇧V`)
4. The image attaches above the prompt — same as pasting a file from Finder

## Gotchas

- macOS only — won't work on Linux or Windows
- Requires Accessibility permission for Raycast — without it, the Cmd+V simulation fails silently
- If the clipboard contains text (not an image), the script exits with an error but the agent won't see it
- Images accumulate in ~/Pictures/clip-img/ — clean up periodically

## Files

- `scripts/clip-img.sh` — the Raycast script
- Saved images land in `~/Pictures/clip-img/` (override with `CLIP_IMG_DIR` env var)
