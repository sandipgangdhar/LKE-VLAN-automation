#!/bin/bash

# Set Kubernetes context and fetch node IPs
export KUBECONFIG=
NODES=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}')

# Define SSH user
SSH_USER="root"

# Define SSH key path if needed
SSH_KEY=""

# Commands to be executed on each node
UPDATE_COMMANDS=$(cat <<EOF
set -e

# Increase limits in /etc/sysctl.conf
echo "net.core.rmem_max=83886080" >> /etc/sysctl.conf
echo "net.core.rmem_default=83886080" >> /etc/sysctl.conf
echo "net.core.wmem_max=83886080" >> /etc/sysctl.conf
echo "net.core.wmem_default=83886080" >> /etc/sysctl.conf
echo "kernel.sched_rt_runtime_us=-1" >> /etc/sysctl.conf
echo "net.unix.max_dgram_qlen=32768" >> /etc/sysctl.conf
echo "kernel.core_pattern=/dev/null" >> /etc/sysctl.conf
sysctl -p

# Modify containerd limits
mkdir -p /etc/systemd/system/containerd.service.d
echo "[Service]" > /etc/systemd/system/containerd.service.d/override.conf
echo "LimitMSGQUEUE=10000000" >> /etc/systemd/system/containerd.service.d/override.conf
echo "LimitMEMLOCK=infinity" >> /etc/systemd/system/containerd.service.d/override.conf

# Change Cgroup v2 to v1
if [ -f /etc/default/grub ]; then
  sed -i 's|GRUB_CMDLINE_LINUX="|GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=0 |' /etc/default/grub
  update-grub || { echo "Failed to update GRUB"; exit 1; }
else
  echo "/etc/default/grub not found."
fi

# Restart containerd and reload systemd
systemctl daemon-reload || { echo "Failed to reload systemd"; exit 1; }
systemctl restart containerd || { echo "Failed to restart containerd"; exit 1; }

# Reboot node
/sbin/reboot || { echo "Failed to reboot the node"; exit 1; }
EOF
)

# Loop through each node IP and apply the updates
for NODE_IP in $NODES; do
  echo "Updating node: $NODE_IP"
  ssh -i "$SSH_KEY" "$SSH_USER@$NODE_IP" "$UPDATE_COMMANDS"
done

echo "Configuration updates complete."
