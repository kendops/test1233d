#!/bin/bash

# Define nodes in the cluster
NODES=("node1" "node2" "node3" "node4" "node5" "node6")

# Define services related to AAP 2.5
SERVICES=(
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

# Define directories to remove (including /etc/nginx)
DIRS=(
    "/var/lib/awx"
    "/etc/tower"
    "/var/log/tower"
    "/var/lib/pulp"
    "/var/lib/pgsql"
    "/var/lib/redis"
    "/etc/ansible"
    "/usr/share/ansible"
    "/root/.ansible"
    "/var/log/ansible"
    "/opt/rh/rh-postgresql*/root/var/lib/pgsql/data"
    "/etc/nginx"  # Added /etc/nginx to ensure Nginx is fully removed
)

# Function to uninstall AAP 2.5
uninstall_aap() {
    local NODE=$1
    echo "==== Uninstalling AAP 2.5 on $NODE ===="

    # Stop and disable services
    for SERVICE in "${SERVICES[@]}"; do
        ssh "$NODE" "sudo systemctl stop $SERVICE 2>/dev/null || true"
        ssh "$NODE" "sudo systemctl disable $SERVICE 2>/dev/null || true"
        ssh "$NODE" "sudo systemctl mask $SERVICE 2>/dev/null || true"
    done

    # Uninstall all packages
    ssh "$NODE" "sudo yum remove -y ${PACKAGES[*]} && sudo yum autoremove -y"

    # Unmount and remove Pulp directory
    ssh "$NODE" "if mountpoint -q /var/lib/pulp; then echo 'Unmounting /var/lib/pulp on $NODE'; sudo umount /var/lib/pulp; fi"
    ssh "$NODE" "sudo rm -rf /var/lib/pulp/*"

    # Remove directories
    for DIR in "${DIRS[@]}"; do
        ssh "$NODE" "sudo rm -rf $DIR"
    done

    # Remove users and groups
    ssh "$NODE" "sudo userdel -r awx 2>/dev/null || true"
    ssh "$NODE" "sudo groupdel awx 2>/dev/null || true"

    # Flush firewall rules
    ssh "$NODE" "sudo firewall-cmd --remove-service=ansible --permanent 2>/dev/null || true"
    ssh "$NODE" "sudo firewall-cmd --reload 2>/dev/null || true"

    # Reset SELinux policies
    ssh "$NODE" "sudo setenforce 0 2>/dev/null || true"
    ssh "$NODE" "sudo semodule -r ansible 2>/dev/null || true"

    # Reset Podman (if used)
    ssh "$NODE" "sudo podman system reset -f 2>/dev/null || true"
    ssh "$NODE" "sudo rm -rf /var/lib/containers /etc/containers"

    echo "==== AAP 2.5 Manual Uninstallation Completed on $NODE ===="
}

# Function to verify uninstallation
verify_uninstall() {
    local NODE=$1
    echo "==== Verifying AAP 2.5 Removal on $NODE ===="

    # Check running services
    for SERVICE in "${SERVICES[@]}"; do
        ssh "$NODE" "if systemctl is-active --quiet $SERVICE; then echo '❌ Service $SERVICE is still running'; else echo '✅ Service $SERVICE is stopped'; fi"
    done

    # Check installed packages
    ssh "$NODE" "INSTALLED_PACKAGES=\$(rpm -qa | grep -E 'ansible|awx|automation|tower|nginx|receptor|postgresql|redis'); if [[ -z \"\$INSTALLED_PACKAGES\" ]]; then echo '✅ All AAP-related packages are removed'; else echo '❌ Found installed packages: \$INSTALLED_PACKAGES'; fi"

    # Check directories (including /etc/nginx)
    for DIR in "${DIRS[@]}"; do
        ssh "$NODE" "[ ! -d $DIR ] && echo '✅ $DIR is removed' || echo '❌ $DIR still exists'"
    done

    # Check users and groups
    ssh "$NODE" "if id 'awx' &>/dev/null; then echo '❌ awx user still exists'; else echo '✅ awx user is removed'; fi"
    ssh "$NODE" "if getent group 'awx' &>/dev/null; then echo '❌ awx group still exists'; else echo '✅ awx group is removed'; fi"

    # Check firewall rules
    ssh "$NODE" "if firewall-cmd --list-services | grep -q 'ansible'; then echo '❌ Ansible firewall rule still exists'; else echo '✅ Ansible firewall rule is removed'; fi"

    # Verify /var/lib/pulp is empty
    ssh "$NODE" "if [ -d /var/lib/pulp ] && [ \"\$(ls -A /var/lib/pulp 2>/dev/null)\" ]; then echo '❌ /var/lib/pulp is NOT empty on $NODE'; else echo '✅ /var/lib/pulp is completely empty on $NODE'; fi"

    echo "==== Verification Completed on $NODE ===="
}

# Iterate through all nodes and uninstall AAP 2.5
for NODE in "${NODES[@]}"; do
    uninstall_aap "$NODE"
    verify_uninstall "$NODE"
done

echo "==== AAP 2.5 Uninstallation and Verification Completed on All Nodes ===="