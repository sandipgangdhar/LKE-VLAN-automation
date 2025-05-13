
LKE VPN Route Automation Script
===============================

**Script Name:** `lke-add-vpn-route.sh`  
**Generated On:** 2025-04-30 19:49:57

Overview:
---------
This script is used to automate the process of adding a VPN route (`172.31.0.0/16 via 192.168.1.1`) on all Linode Kubernetes Engine (LKE) worker nodes. It uses SSH to connect to each node and checks if the route already exists. If it does, it logs a message. If it does not, it adds the route.

Features:
---------
- Accepts LKE Cluster ID as input
- Fetches all worker node public IPs
- SSH into each node using root access (with key-based authentication)
- Adds route only if it's not already present
- Logs status and timestamps for audit and debugging

Usage:
------
```bash
./lke-add-vpn-route.sh <LKE_CLUSTER_ID>
```

Example:
```bash
./lke-add-vpn-route.sh 415227
```

SSH Key Requirements:
---------------------
Ensure that passwordless SSH access is set up using the key provided in `pub-keys.yaml`:
- Private Key Path: `~/.ssh/lke-root-key`
- User: `root`

To verify if the route is present manually:
```bash
ssh -i ~/.ssh/lke-root-key root@<NODE_PUBLIC_IP> "ip route | grep -q '172.31.0.0/16' && echo '[OK] Route is present' || echo '[MISSING] Route is missing'"
```

Logging:
--------
- The script outputs timestamped logs to stdout.
- You may redirect it to a file using:
```bash
./lke-add-vpn-route.sh 415227 >> vpn-route-log.txt 2>&1
```

Dependencies:
-------------
- `linode-cli` must be installed and configured
- `jq` for parsing JSON
- Passwordless SSH should be in place for `root` user on worker nodes

Note:
-----
Make sure the pubkey has been pushed to all nodes using:
- `pub-keys.yaml` (ConfigMap)
- `pub-keys-to-node-daemonset.yaml` (DaemonSet for distribution)
