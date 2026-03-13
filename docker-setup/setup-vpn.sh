#!/usr/bin/env bash

# Free VPN Setup for Frappe Server
set -e

echo "=========================================="
echo "Free VPN Setup Options"
echo "=========================================="

echo "Choose VPN option:"
echo "1) Tailscale (Easiest - Recommended)"
echo "2) ZeroTier (Good for small networks)"
echo "3) WireGuard (Advanced - Self-hosted)"
echo "4) Skip VPN setup"

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "Setting up Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | sh
        sudo tailscale up
        echo "Tailscale installed!"
        echo "Your Tailscale IP: $(tailscale ip -4)"
        echo "Install Tailscale on other devices and log in with same account"
        ;;
    2)
        echo "Setting up ZeroTier..."
        curl -s https://install.zerotier.com | sudo bash
        sudo systemctl start zerotier-one
        sudo systemctl enable zerotier-one
        echo "ZeroTier installed!"
        echo "Create network at https://my.zerotier.com and join with:"
        echo "sudo zerotier-cli join YOUR_NETWORK_ID"
        ;;
    3)
        echo "Setting up WireGuard..."
        sudo apt install -y wireguard
        wg genkey | sudo tee /etc/wireguard/server-private.key
        sudo chmod 600 /etc/wireguard/server-private.key
        sudo cat /etc/wireguard/server-private.key | wg pubkey | sudo tee /etc/wireguard/server-public.key
        echo "WireGuard installed!"
        echo "Server public key: $(sudo cat /etc/wireguard/server-public.key)"
        echo "Configure /etc/wireguard/wg0.conf manually"
        ;;
    4)
        echo "Skipping VPN setup"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
