#!/bin/bash
set -e

# shellcheck source=/dev/null
source "$(dirname "$0")/config.sh"

PI_SSH="${PI_USER}@${PI_HOSTNAME}.${TAILSCALE_DOMAIN}"
LOCAL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Deploying Artemis Photo to Pi..."

ssh "$PI_SSH" "sudo mkdir -p $DEPLOY_DIR && sudo chown ${PI_USER}:${PI_USER} $DEPLOY_DIR"

scp "$LOCAL_DIR/server.js" \
    "$LOCAL_DIR/artemis-photo.html" \
    "$LOCAL_DIR/package.json" \
    "$PI_SSH:$DEPLOY_DIR/"

echo "Installing dependencies..."
ssh "$PI_SSH" "cd $DEPLOY_DIR && npm install --omit=dev"

echo "Configuring nginx..."
ssh "$PI_SSH" "cat > /tmp/nginx-artemis-photo << 'EOF'
server {
    listen 80;
    server_name artemis.${PI_HOSTNAME}.local artemis.${PI_HOSTNAME}.${TAILSCALE_DOMAIN};

    location / {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
sudo cp /tmp/nginx-artemis-photo /etc/nginx/sites-enabled/artemis-photo"

ssh "$PI_SSH" "sudo nginx -t && sudo systemctl reload nginx"

echo "Generating systemd service..."
ssh "$PI_SSH" "cat > /tmp/artemis-photo.service << 'EOF'
[Unit]
Description=Artemis Photo
After=network.target

[Service]
Type=simple
User=${PI_USER}
WorkingDirectory=${DEPLOY_DIR}
Environment=PORT=${PORT}
ExecStart=/usr/bin/node server.js
Restart=on-failure
StandardOutput=append:${DEPLOY_DIR}/server.log
StandardError=append:${DEPLOY_DIR}/server-error.log

[Install]
WantedBy=multi-user.target
EOF
sudo cp /tmp/artemis-photo.service /etc/systemd/system/artemis-photo.service"

echo ""
echo "To start the service (run on the Pi):"
echo "  ssh ${PI_SSH}"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable artemis-photo"
echo "  sudo systemctl start artemis-photo"
echo ""
echo "Access at:"
echo "  http://artemis.${PI_HOSTNAME}.local"
echo "  http://artemis.${PI_HOSTNAME}.${TAILSCALE_DOMAIN}"
