#!/bin/bash

# Define nodes in the cluster
NODES=("node1" "node2" "node3" "node4" "node5" "node6")

# Ansible Automation Platform services
SERVICES=(
    "ansible-automation-platform"
    "automation-controller"
    "automation-hub"
    "receptor"
    "nginx"
    "postgresql"
    "redis"
)

# Function to uninstall AAP on a given node
uninstall_aap() {
    local NODE=$1

    echo "==== Uninstalling AAP on $NODE ===="
    
    # Stop AAP services
    for SERVICE in "${SERVICES[@]}"; do
        ssh "$NODE" "sudo systemctl stop $SERVICE 2>/dev/null || true"
        ssh "$NODE" "sudo systemctl disable $SERVICE 2>/dev/null || true"
    done

    # Remove packages
    ssh "$NODE" "sudo yum remove -y ansible ansible-automation-platform ansible-tower ansible-hub receptor nginx postgresql redis"

    # Remove directories
    ssh "$NODE" "sudo rm -rf /var/lib/awx /etc/tower /var/log/tower /opt/rh/rh-postgresql*/root/var/lib/pgsql/data"
    
    # Remove users and groups
    ssh "$NODE" "sudo userdel -r awx 2>/dev/null || true"
    ssh "$NODE" "sudo groupdel awx 2>/dev/null || true"

    # Clear firewall rules
    ssh "$NODE" "sudo firewall-cmd --remove-service=ansible --permanent 2>/dev/null || true"
    ssh "$NODE" "sudo firewall-cmd --reload 2>/dev/null || true"

    # Reset SELinux settings
    ssh "$NODE" "sudo setenforce 0 2>/dev/null || true"
    
    echo "==== AAP Uninstallation Completed on $NODE ===="
}

# Iterate through all nodes and uninstall AAP
for NODE in "${NODES[@]}"; do
    uninstall_aap "$NODE"
done

echo "==== AAP Uninstallation Completed on All Nodes ===="