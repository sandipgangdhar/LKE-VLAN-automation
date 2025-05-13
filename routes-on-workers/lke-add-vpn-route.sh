#!/bin/bash

# LKE VPN Route Setup Script
# This script connects to all worker nodes in a given Linode LKE cluster,
# checks if a specific VPN route is present, and adds it if not.
# Requirements:
# - linode-cli must be authenticated and configured
# - jq installed
# - SSH access to worker nodes via root and correct SSH key

CLUSTER_ID="$1"
VPN_ROUTE="172.31.0.0/16"
GATEWAY="192.168.1.1"
INTERFACE="eth1"
LOG_FILE="vpn-route-status.log"

if [[ -z "$CLUSTER_ID" ]]; then
  echo "Usage: $0 <LKE_CLUSTER_ID>"
  exit 1
fi

# Logging function
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Fetch public IPs of all worker nodes in the LKE cluster
log "🔍 Fetching public IPs of worker nodes in cluster $CLUSTER_ID..."

NODE_IPS=$(linode-cli lke pools-list "$CLUSTER_ID" --json |
  jq -r '.[].nodes.instance_id' |
  xargs -I{} linode-cli linodes view {} --json |
  jq -r '.[0].ipv4[]' |
  grep -v "192.168")

if [[ -z "$NODE_IPS" ]]; then
  log "❌ No worker node public IPs found. Exiting."
  exit 1
fi

# Loop over all nodes
for IP in $NODE_IPS; do
  log "➡️  Connecting to $IP..."

  # Check if route already exists
  if ssh -o StrictHostKeyChecking=no -i ~/.ssh/lke-root-key root@"$IP" ip route | grep -q "$VPN_ROUTE"; then
    log "⚠️  Route $VPN_ROUTE already present on $IP. Skipping."
  else
    log "🔧 Adding route $VPN_ROUTE via $GATEWAY on $IP..."
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/lke-root-key root@"$IP" \
      "ip route add $VPN_ROUTE via $GATEWAY dev $INTERFACE"
    log "✅ Route added on $IP."
  fi

done
