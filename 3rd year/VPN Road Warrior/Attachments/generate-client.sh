!/bin/bash
# generate-client.sh - Create a new WireGuard client

CLIENT_NAME=$1
CLIENT_IP=$2
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
SERVER_ENDPOINT="vpn.company.com:51820"
DNS_SERVER="192.168.1.1"  # Internal DNS server

if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_IP" ]; then
    echo "Usage: $0 <client_name> <client_ip>"
    echo "Example: $0 john-laptop 10.10.0.2"
    exit 1
fi

# Create client directory
CLIENT_DIR="/etc/wireguard/clients/$CLIENT_NAME"
sudo mkdir -p "$CLIENT_DIR"
cd "$CLIENT_DIR"

# Generate client keys
umask 077
wg genkey | sudo tee private.key | wg pubkey | sudo tee public.key
CLIENT_PRIVATE=$(cat private.key)
CLIENT_PUBLIC=$(cat public.key)

# Create client configuration
sudo tee "$CLIENT_NAME.conf" << EOF
[Interface]
# Client's private key
PrivateKey = $CLIENT_PRIVATE
# Client's VPN IP address
Address = $CLIENT_IP/32
# DNS servers to use when connected
DNS = $DNS_SERVER

[Peer]
# Server's public key
PublicKey = $SERVER_PUBLIC_KEY
# Server's public endpoint
Endpoint = $SERVER_ENDPOINT
# Route all traffic through VPN (full tunnel)
# Use 10.10.0.0/24, 192.168.1.0/24 for split tunnel
AllowedIPs = 0.0.0.0/0
# Keep connection alive behind NAT
PersistentKeepalive = 25
EOF

# Generate QR code for mobile clients
qrencode -t ansiutf8 < "$CLIENT_NAME.conf"
qrencode -t png -o "$CLIENT_NAME.png" < "$CLIENT_NAME.conf"

echo ""
echo "Client configuration created: $CLIENT_DIR/$CLIENT_NAME.conf"
echo "QR code saved: $CLIENT_DIR/$CLIENT_NAME.png"
echo ""
echo "Add this peer configuration to the server:"
echo ""
echo "[Peer]"
echo "# $CLIENT_NAME"
echo "PublicKey = $CLIENT_PUBLIC"
echo "AllowedIPs = $CLIENT_IP/32"
