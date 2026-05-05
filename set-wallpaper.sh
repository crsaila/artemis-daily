#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/config.sh" || { echo "config.sh not found" >&2; exit 1; }

WALLPAPER_DIR="$HOME/Pictures/Artemis"
TODAY=$(date +%Y%m%d)
WALLPAPER_FILE="$WALLPAPER_DIR/$TODAY.jpg"
LOCAL_URL="http://artemis.${PI_HOSTNAME}.local/today.jpg"
TAILSCALE_URL="http://${PI_HOSTNAME}.${TAILSCALE_DOMAIN}/artemis/today.jpg"
HELPER="$SCRIPT_DIR/wallpaper-helper"

mkdir -p "$WALLPAPER_DIR"

# Compile Swift helper on first run
if [ ! -f "$HELPER" ]; then
  swiftc "$SCRIPT_DIR/wallpaper-helper.swift" -o "$HELPER" 2>/dev/null || exit 0
fi

# Download today's image if not already cached
if [ ! -f "$WALLPAPER_FILE" ]; then
  curl -sf --max-time 10 -o "$WALLPAPER_FILE" "$LOCAL_URL" || \
  curl -sf --max-time 30 -o "$WALLPAPER_FILE" "$TAILSCALE_URL" || {
    rm -f "$WALLPAPER_FILE"
    exit 0
  }
fi

"$HELPER" "$WALLPAPER_FILE"

# Remove wallpapers older than 7 days
find "$WALLPAPER_DIR" -name "*.jpg" -mtime +7 -delete
