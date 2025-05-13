#!/bin/bash

# Script to attach a VLAN to Linodes in an LKE cluster (eth1) only if not already configured

CLUSTER_ID=$1
VLAN_LABEL="AWS-VLAN"
LOG_FILE="vlan_attachment.log"

# Static IPs passed inline — can also be passed via --ips or file
IP_ADDRESSES=("192.168.1.2/24" "192.168.1.3/24" "192.168.1.4/24")

log() {
  echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"
}

log "🔍 Fetching all node pools in LKE cluster $CLUSTER_ID..."
NODE_POOLS=$(linode-cli lke pools-list "$CLUSTER_ID" --json)

if [[ -z "$NODE_POOLS" || "$NODE_POOLS" == "null" ]]; then
  log "❌ No node pools found or failed to fetch. Exiting."
  exit 1
fi

LINODE_IDS=($(echo "$NODE_POOLS" | jq -r '.[].nodes.instance_id'))

for i in "${!LINODE_IDS[@]}"; do
  LINODE_ID="${LINODE_IDS[$i]}"
  IP="${IP_ADDRESSES[$i]}"
  log "➡️  Processing Linode ID: $LINODE_ID with IP: $IP"

  # Get config ID
  CONFIGS=$(linode-cli linodes configs-list "$LINODE_ID" --json)
  CONFIG_ID=$(echo "$CONFIGS" | jq '.[0].id')

  if [[ -z "$CONFIG_ID" || "$CONFIG_ID" == "null" ]]; then
    log "❌ Failed to fetch config ID for Linode $LINODE_ID"
    continue
  fi

  # Check if eth1 is already a VLAN
  INTERFACE_PURPOSE=$(linode-cli linodes config-view "$LINODE_ID" "$CONFIG_ID" --json | jq -r '.[0].interfaces[1].purpose // empty')

  if [[ "$INTERFACE_PURPOSE" == "vlan" ]]; then
    log "⚠️  eth1 on $LINODE_ID already configured as VLAN. Skipping."
    continue
  fi

  log "🔧 Attaching VLAN '$VLAN_LABEL' to eth1..."

  # Build full JSON for interfaces
  INTERFACES_JSON=$(jq -n --arg ip "$IP" --arg vlan "$VLAN_LABEL" '
    [
      { "type": "public", "purpose": "public" },
      { "type": "vlan", "label": $vlan, "purpose": "vlan", "ipam_address": $ip }
    ]
  ')

  RESPONSE=$(linode-cli linodes config-update "$LINODE_ID" "$CONFIG_ID" \
    --interfaces "$INTERFACES_JSON" \
    --label "Boot Config" 2>&1)

  if echo "$RESPONSE" | grep -q "error"; then
    log "❌ Failed to update config for Linode $LINODE_ID"
    log "📋 CLI Output: $RESPONSE"
    continue
  fi

  log "🔄 Rebooting Linode $LINODE_ID..."
  linode-cli linodes reboot "$LINODE_ID" > /dev/null
  log "✅ VLAN attached and node rebooted: $LINODE_ID"
done
