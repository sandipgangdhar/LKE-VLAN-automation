
attach-vlan-to-linode.sh

This script automates the attachment of a VLAN interface to eth1 on all Linodes in a specified Linode Kubernetes Engine (LKE) cluster. It supports assigning custom IP addresses and ensures that configuration changes are only applied when VLAN is not already configured -- preventing unnecessary reboots during repeated runs (e.g., via cron).

Purpose
-------
- Automatically attach a specified VLAN (e.g., AWS-VLAN) to eth1 of each Linode in an LKE node pool.
- Assign custom ipam_address to each node interface.
- Prevent configuration changes and instance reboots if VLAN is already set.
- Maintain log file with timestamps and status of each operation.

Features
--------
- Automatically fetches node pool Linodes from a given LKE Cluster ID.
- Supports:
  - Hardcoded IP list (default)
  - Command-line IP input (--ips)
  - File input (--ip-file)
- Skips nodes that already have VLAN configured on eth1.
- Reboots Linodes only if changes are made.
- Logs every action to a timestamped log file.

Usage
-----
Default (hardcoded IP list inside script)
  ./attach-vlan-to-linode.sh

With IPs passed as arguments
  ./attach-vlan-to-linode.sh --ips "192.168.1.2/24 192.168.1.3/24 192.168.1.4/24"

With IPs from file (one per line)
  ./attach-vlan-to-linode.sh --ip-file /path/to/ip_list.txt

*Each IP must be CIDR-formatted, e.g., 192.168.1.2/24*

Behavior
--------
1. Fetches all node pools from the provided cluster ID.
2. Iterates over each Linode in each pool.
3. Checks current network interface configuration.
   - If eth1 is already configured with "purpose": "vlan", it skips.
   - Otherwise, builds a new configuration JSON and updates it via linode-cli.
4. Reboots only if config update is applied.
5. Logs every action with timestamps to attach-vlan.log.

Configuration
-------------
Modify these variables in the script as needed:

  CLUSTER_ID=415227
  VLAN_LABEL="AWS-VLAN"
  DEFAULT_IPS=("192.168.1.2/24" "192.168.1.3/24" "192.168.1.4/24")

Logging
-------
All output is logged to:

  ~/attach-vlan.log

Each line includes a timestamp and node ID, making it cron-safe and traceable.

Crontab Usage Example
---------------------
To schedule this script (safe for repeated use):

  0 3 * * * /path/to/attach-vlan-to-linode.sh >> /var/log/attach-vlan-cron.log 2>&1

Requirements
------------
- linode-cli (v5.57.0 or later)
- jq (for parsing JSON)

Ensure you have a valid Linode API token configured via:

  linode-cli configure

Example Output
--------------
[2025-05-01 00:27:36] Fetching all node pools in LKE cluster 415227...
[2025-05-01 00:27:40] eth1 on 76164481 already configured as VLAN. Skipping.
[2025-05-01 00:27:41] eth1 on 76164478 already configured as VLAN. Skipping.
[2025-05-01 00:27:43] eth1 on 76164479 already configured as VLAN. Skipping.

Support
-------
For issues, enhancements, or help -- contact the infrastructure automation team.
