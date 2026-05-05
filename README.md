# Artemis Daily

A self-hosted daily photo viewer built around NASA's [Gateway to Astronaut Photography](https://eol.jsc.nasa.gov). Each day a photograph from the Artemis II mission is randomly selected and served via a Raspberry Pi — viewable in a browser and optionally set as your Mac desktop wallpaper.

## How it works

- A seeded random picks one photograph per day from the full Artemis II catalogue (1,000+ frames)
- The Pi downloads the image from NASA once and caches it locally
- The web app serves the cached image — zero repeat NASA requests regardless of how many devices load the page
- An "Another" button picks a different random photo on demand (loads directly from NASA)
- A macOS LaunchAgent downloads the daily image from the Pi at login and sets it as the Desktop 1 wallpaper on the built-in display

## Requirements

- Raspberry Pi running Raspberry Pi OS with Node.js and nginx
- Tailscale installed on both the Pi and any remote devices
- macOS with Xcode Command Line Tools (for the Swift wallpaper helper)

## Pi setup

### 1. Configure

Copy `config.example.sh` to `config.sh` and fill in your values:

```bash
cp config.example.sh config.sh
```

```bash
PI_USER="pi"
PI_HOSTNAME="your-pi-hostname"
PI_LOCAL_IP="10.0.x.x"
TAILSCALE_DOMAIN="xxxx.ts.net"
DEPLOY_DIR="/var/www/artemis-photo"
```

### 2. Deploy

```bash
./deploy.sh
```

This transfers all files, installs dependencies, configures nginx, and reloads it.

### 3. Start the service

SSH into the Pi and enable the systemd service:

```bash
ssh pi@your-pi-hostname.your-tailscale-domain.ts.net
sudo systemctl daemon-reload
sudo systemctl enable artemis-photo
sudo systemctl start artemis-photo
```

### 4. Add to your hosts file (local access)

On each Mac that will use the local address, add an entry to `/etc/hosts`:

```bash
sudo sh -c 'echo "10.0.x.x    artemis.your-pi-hostname.local" >> /etc/hosts'
```

The app will then be available at:

- `http://artemis.your-pi-hostname.local`
- `http://artemis.your-pi-hostname.your-tailscale-domain.ts.net`

## Mac wallpaper setup

Install the LaunchAgent — this also compiles the Swift wallpaper helper on first run:

```bash
./install-mac.sh
```

The agent runs at login and every hour thereafter. On its first run each day it downloads today's image from the Pi and sets it as the Desktop 1 wallpaper on the built-in display. Subsequent runs that day reuse the local cached file.

Images are saved to `~/Pictures/Artemis/` and cleaned up after 7 days.

If the Pi is unreachable on the local network the agent falls back to the Tailscale address. If both are unreachable it exits silently and the existing wallpaper is kept.

## Adapting for a different mission

The frame list in `server.js` and `artemis-photo.html` is specific to the Artemis II catalogue. To use a different mission, replace the `FRAMES` array with frame numbers from [Gateway to Astronaut Photography](https://eol.jsc.nasa.gov/SearchPhotos/) and update the mission/roll identifiers in the NASA URL strings.

## Acknowledgements

Photographs sourced from NASA's [Gateway to Astronaut Photography of Earth](https://eol.jsc.nasa.gov), maintained by the Earth Science and Remote Sensing Unit at NASA Johnson Space Center.
