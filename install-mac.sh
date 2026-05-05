#!/bin/bash
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SRC/config.sh" || { echo "Copy config.example.sh to config.sh and fill in your values." >&2; exit 1; }

SCRIPTS_DIR="$HOME/Library/Scripts/artemis-photo"
PLIST_DEST="$HOME/Library/LaunchAgents/com.user.artemis-wallpaper.plist"

mkdir -p "$SCRIPTS_DIR"

cp "$SRC/set-wallpaper.sh"      "$SCRIPTS_DIR/"
cp "$SRC/wallpaper-helper.swift" "$SCRIPTS_DIR/"
cp "$SRC/config.sh"             "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/set-wallpaper.sh"

# Generate plist with correct path
cat > "$PLIST_DEST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.artemis-wallpaper</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SCRIPTS_DIR/set-wallpaper.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>3600</integer>
  <key>StandardOutPath</key>
  <string>/tmp/artemis-wallpaper.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/artemis-wallpaper.log</string>
</dict>
</plist>
EOF

launchctl bootout gui/$(id -u) "$PLIST_DEST" 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$PLIST_DEST"
echo "Installed. Agent will run now and every hour thereafter."
