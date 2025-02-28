#!/bin/bash

# Define nodes in the AAP 2.5 cluster
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

# Define packages to remove, including PostgreSQL server and client
PACKAGES=(
    "ansible"
    "ansible-automation-platform"
    "ansible-tower"
    "automation-controller"
    "automation-hub"
    "receptor"
    "nginx"
    "postgresql"
    "postgresql-server"
    "postgresql-client"
    "redis"
    "pulp-server"
    "pulp-worker"
    "pulp-resource-manager"
    "pulp-content"
    "pulp-api"
    "podman"
    "python3-ansible*"
)

# Define directories to remove, including /etc/nginx and /etc/ansible-automation-platform
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
    "/etc/nginx"  # Ensure nginx configuration is removed
    "/etc/ansible-automation-platform"  # Ensure ansible-automation-platform configuration is removed
    "/etc/receptor"
    "/etc/redis"
    "/etc/pulp"
)

# Function to uninstall AAP 2.5 on each node
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
    ssh "$NODE" "sudo userdel -r pulp 2>/dev/null || true"
    ssh "$NODE" "sudo userdel -r automation-controller 2>/dev/null || true"
    ssh "$NODE" "sudo groupdel awx 2>/dev/null || true"
    ssh "$NODE" "sudo groupdel pulp 2>/dev/null || true"
    ssh "$NODE" "sudo groupdel automation-controller 2>/dev/null || true"

    # Flush firewall rules
    ssh "$NODE" "sudo firewall-cmd --remove-service=ansible --permanent 2>/dev/null || true"
    ssh "$NODE" "sudo firewall-cmd --reload 2>/dev/null || true"

    # Reset SELinux policies
    ssh "$NODE" "sudo setenforce 0 2>/dev/null || true"
    ssh "$NODE" "sudo semodule -r ansible 2>/dev/null || true"

    # Reset Podman (if used)
    ssh "$NODE" "sudo podman system reset -f 2>/dev/null || true"
    ssh "$NODE" "sudo rm -rf /var/lib/containers /etc/containers"

    echo "==== AAP 2.5 Uninstallation Completed on $NODE ===="
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
    ssh "$NODE" "INSTALLED_PACKAGES=\$(rpm -qa | grep -E 'ansible|awx|automation|tower|nginx|receptor|postgresql|redis|pulp'); if [[ -z \"\$INSTALLED_PACKAGES\" ]]; then echo '✅ All AAP-related packages are removed'; else echo '❌ Found installed packages: \$INSTALLED_PACKAGES'; fi"

    # Check directories (including /etc/nginx and /etc/ansible-automation-platform)
    for DIR in "${DIRS[@]}"; do
        ssh "$NODE" "[ ! -d $DIR ] && echo '✅ $DIR is removed' || echo '❌ $DIR still exists'"
    done

    # Check users and groups
    ssh "$NODE" "if id 'awx' &>/dev/null; then echo '❌ User awx still exists'; else echo '✅ User awx is removed'; fi"
    ssh "$NODE" "if id 'pulp' &>/dev/null; then echo '❌ User pulp still exists'; else echo '✅ User pulp is removed'; fi"
    ssh "$NODE" "if id 'automation-controller' &>/dev/null; then echo '❌ User automation-controller still exists'; else echo '✅ User automation-controller is removed'; fi"

    # Check firewall rules
    ssh "$NODE" " 