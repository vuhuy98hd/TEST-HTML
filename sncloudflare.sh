#!/bin/bash
echo "--------- 🟢 Stop Docker compose (n8n) -----------"
sudo -E docker compose down

echo "--------- 🟢 Install Cloudflare Tunnel -----------"
curl -fsSL https://pkg.cloudflare.com/install.sh | sudo bash
sudo apt install cloudflared -y

echo "🔵🔵🔵 Nhập thông tin Cloudflare của bạn:"
read -p "Cloudflare Token: " token
read -p "Domain (ví dụ n8n.example.com): " domain

echo "--------- 🟢 Login Cloudflare -----------"
cloudflared tunnel login --token $token

echo "--------- 🟢 Create Tunnel -----------"
cloudflared tunnel create n8n-tunnel

TUNNEL_ID=$(cloudflared tunnel list | grep n8n-tunnel | awk '{print $1}')

echo "--------- 🟢 Writing Tunnel Config -----------"
sudo mkdir -p /etc/cloudflared

sudo tee /etc/cloudflared/config.yml > /dev/null <<EOF
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $domain
    service: http://localhost:5678
  - service: http_status:404
EOF

echo "--------- 🟢 Routing domain trên Cloudflare -----------"
cloudflared tunnel route dns n8n-tunnel $domain

echo "--------- 🟢 Start Tunnel in background -----------"
sudo cloudflared --config /etc/cloudflared/config.yml --no-autoupdate service install
sudo systemctl enable cloudflared
sudo systemctl restart cloudflared

echo "--------- 🟢 Start Docker (n8n) -----------"
sudo -E docker compose up -d

echo "--------- 🟢 DONE! Truy cập N8N tại https://$domain -----------"
