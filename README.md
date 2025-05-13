
# LKE VLAN Automation

This repository contains automation scripts to simplify the configuration of VLANs and VPN routes on Linode Kubernetes Engine (LKE) worker nodes.

---

## 📌 **Contents**
- [attach-vlan-to-linode.sh](#attach-vlan-to-linode)
- [lke-add-vpn-route.sh](#lke-vpn-route-automation)
- [Usage Examples](#usage-examples)
- [Crontab Scheduling](#crontab-usage-example)
- [Requirements](#requirements)
- [Logging](#logging)
- [Support](#support)

---

## 🚀 **attach-vlan-to-linode**
This script automates the attachment of a VLAN interface to `eth1` on all Linodes in a specified LKE cluster. It supports assigning custom IP addresses and ensures configuration changes are only applied if VLAN is not already configured—preventing unnecessary reboots during repeated runs (e.g., via cron).

### **Purpose**
- Automatically attach a specified VLAN (e.g., `AWS-VLAN`) to `eth1` of each Linode in an LKE node pool.
- Assign custom `ipam_address` to each node interface.
- Prevent configuration changes and instance reboots if VLAN is already set.
- Maintain a log file with timestamps and status of each operation.

### **Features**
- Automatically fetches node pool Linodes from a given LKE Cluster ID.
- Supports:
  - Hardcoded IP list (default)
  - Command-line IP input (`--ips`)
  - File input (`--ip-file`)
- Skips nodes that already have VLAN configured on `eth1`.
- Reboots Linodes only if changes are made.
- Logs every action to a timestamped log file.

### **Usage**
#### Default (hardcoded IP list inside script):
```bash
./attach-vlan-to-linode.sh
```

#### With IPs passed as arguments:
```bash
./attach-vlan-to-linode.sh --ips "192.168.1.2/24 192.168.1.3/24 192.168.1.4/24"
```

#### With IPs from a file (one per line):
```bash
./attach-vlan-to-linode.sh --ip-file /path/to/ip_list.txt
```

> **Note:** Each IP must be CIDR-formatted, e.g., `192.168.1.2/24`.

---

## 🔄 **Behavior**
1. Fetches all node pools from the provided cluster ID.
2. Iterates over each Linode in each pool.
3. Checks current network interface configuration:
   - If `eth1` is already configured with `"purpose": "vlan"`, it **skips**.
   - Otherwise, it builds a new configuration JSON and updates it via `linode-cli`.
4. Reboots only if configuration changes are applied.
5. Logs every action with timestamps to `attach-vlan.log`.

---

## 🔌 **LKE VPN Route Automation**
**Script Name:** `lke-add-vpn-route.sh`  
This script automates the process of adding a VPN route (`172.31.0.0/16 via 192.168.1.1`) on all LKE worker nodes. It uses SSH to connect to each node and checks if the route already exists. If it does, it logs a message. If not, it adds the route.

### **Features**
- Accepts **LKE Cluster ID** as input.
- Fetches all worker node public IPs.
- SSH into each node using root access (with key-based authentication).
- Adds the route only if it is not already present.
- Logs status and timestamps for audit and debugging.

### **Usage**
```bash
./lke-add-vpn-route.sh <LKE_CLUSTER_ID>
```

#### Example:
```bash
./lke-add-vpn-route.sh 415227
```

### **Manual Verification**
To verify if the route is present:
```bash
ssh -i ~/.ssh/lke-root-key root@<NODE_PUBLIC_IP> "ip route | grep -q '172.31.0.0/16' && echo '[OK] Route is present' || echo '[MISSING] Route is missing'"
```

---

## 📅 **Crontab Usage Example**
To schedule the VLAN attachment script (safe for repeated use):
```bash
0 3 * * * /path/to/attach-vlan-to-linode.sh >> /var/log/attach-vlan-cron.log 2>&1
```

To schedule the VPN route script:
```bash
0 3 * * * /path/to/lke-add-vpn-route.sh <LKE_CLUSTER_ID> >> /var/log/lke-vpn-route-cron.log 2>&1
```

---

## ⚙️ **Configuration**
Modify these variables in the `attach-vlan-to-linode.sh` script as needed:
```bash
CLUSTER_ID=415227
VLAN_LABEL="AWS-VLAN"
DEFAULT_IPS=("192.168.1.2/24" "192.168.1.3/24" "192.168.1.4/24")
```

---

## 📌 **Requirements**
- `linode-cli` (v5.57.0 or later)
- `jq` for parsing JSON
- Passwordless SSH configured for `root` access:
    - Private Key Path: `~/.ssh/lke-root-key`
    - User: `root`

Ensure you have a valid Linode API token configured via:
```bash
linode-cli configure
```

---

## 📋 **Logging**
All logs are timestamped for easy troubleshooting:
- VLAN attachment logs: `~/attach-vlan.log`
- VPN route logs: `~/vpn-route-status.log`

To redirect script logs:
```bash
./attach-vlan-to-linode.sh >> vlan-attachment.log 2>&1
./lke-add-vpn-route.sh 415227 >> vpn-route-status.log 2>&1
```

---

## 💡 **Support**
For issues, enhancements, or help — contact the infrastructure automation team.

---
