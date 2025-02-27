#!/bin/bash

# Define the nodes
NODES=("node1" "node2" "node3" "node4" "node5" "node6")

# Define services related to AAP
SERVICES=(
    "ansible-automation-platform"
    "automation-controller"
    "automation-hub"
    "receptor"
    "nginx"
    "postgresql"
    "redis"
)

# Define packages to remove
PACKAGES=(
    "ansible"
    "ansible-automation-platform"
    "ansible-tower"
    "ansible-hub"
    "receptor"
    "nginx"
    "postgresql"
    "redis"
    "podman"
    "python3-ansible*"
)

# Define directories to remove
DIRS=(
    "/var/lib/awx"
    "/etc/tower"
    "/var/log/tower"
    "/opt/rh/rh-postgresql*/root/var/lib/pgsql/data"
    "/var/lib/pgsql"
    "/var/lib/redis"
    "/etc/ansible"
    "/usr/share/ansible"
    "/root/.ansible"
    "/var/log/ansible"
)

# Function to uninstall AAP completely on a given node
uninstall_aap() {
    local NODE=$1
    echo "==== Uninstalling AAP on $NODE ===="

    # Stop and disable services
    for SERVICE in "${SERVICES[@]}"; do
        ssh "$NODE" "sudo systemctl stop $SERVICE 2>/dev/null || true"
        ssh "$NODE" "sudo systemctl disable $SERVICE 2>/dev/null || true"
        ssh "$NODE" "sudo systemctl mask $SERVICE 2>/dev/null || true"
    done

    # Uninstall all packages
    ssh "$NODE" "sudo yum remove -y ${PACKAGES[*]} && sudo yum autoremove -y"

    # Remove directories
    for DIR in "${DIRS[@]}"; do
        ssh "$NODE" "sudo rm -rf $DIR"
    done

    # Remove users and groups
    ssh "$NODE" "sudo userdel -r awx 2>/dev/null || true"
    ssh "$NODE" "sudo groupdel awx 2>/dev/null || true"

    # Flush firewall rules related to AAP
    ssh "$NODE" "sudo firewall-cmd --remove-service=ansible --permanent 2>/dev/null || true"
    ssh "$NODE" "sudo firewall-cmd --reload 2>/dev/null || true"

    # Reset SELinux policies
    ssh "$NODE" "sudo setenforce 0 2>/dev/null || true"
    ssh "$NODE" "sudo semodule -r ansible 2>/dev/null || true"

    # Remove Podman/Containerized services if used
    ssh "$NODE" "sudo podman system reset -f 2>/dev/null || true"
    ssh "$NODE" "sudo rm -rf /var/lib/containers /etc/containers"

    # Verify removal
    ssh "$NODE" "rpm -qa | grep ansible || echo '✅ AAP completely removed from $NODE'"
    
    echo "==== AAP Uninstallation Completed on $NODE ===="
}

# Iterate through all nodes and uninstall AAP
for NODE in "${NODES[@]}"; do
    uninstall_aap "$NODE"
done

echo "==== AAP Uninstallation Completed on All Nodes ===="