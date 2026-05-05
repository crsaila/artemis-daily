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
    "$LOCAL_DIR/artemis-photo.service" \
    "$LOCAL_DIR/patch-landing-nginx.py" \
    "$PI_SSH:$DEPLOY_DIR/"

echo "Installing dependencies..."
ssh "$PI_SSH" "cd $DEPLOY_DIR && npm install --omit=dev"

echo "Configuring nginx..."
# Generate nginx config with correct hostnames
ssh "$PI_SSH" "cat > /tmp/nginx-artemis-photo << 'EOF'
server {
    listen 80;
    server_name artemis.${PI_HOSTNAME}.local artemis.${PI_HOSTNAME}.${TAILSCALE_DOMAIN};

    location / {
        proxy_pass http://localhost:8513;
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

ssh "$PI_SSH" "sudo python3 $DEPLOY_DIR/patch-landing-nginx.py"
ssh "$PI_SSH" "sudo nginx -t && sudo systemctl reload nginx"

echo ""
echo "Setting up systemd service (run on the Pi):"
echo "  sudo cp $DEPLOY_DIR/artemis-photo.service /etc/systemd/system/"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable artemis-photo"
echo "  sudo systemctl start artemis-photo"
echo ""
echo "Access at:"
echo "  http://artemis.${PI_HOSTNAME}.local"
echo "  http://${PI_HOSTNAME}.${TAILSCALE_DOMAIN}/artemis"
