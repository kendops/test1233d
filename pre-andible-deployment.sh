#!/bin/bash

# Log file location
LOGFILE="/var/log/setup_servers.log"

# Server and user details
SERVERS=("10.0.0.1" "10.0.0.2" "10.0.0.3" "10.0.0.4" "10.0.0.5" "10.0.0.6")
USERNAME="demo"

# NFS Mount Info
NFS_SERVER="dhdkskaaaa"
NFS_PATH="/stoddeds"
NFS_MOUNT="/enable /var/lib/pulp/"

# Subscription Credentials
RH_USERNAME="id@company.com"
RH_PASSWORD="mysecurepassword"

# Ansible Automation Platform Download Link
ANSIBLE_SETUP_BUNDLE_URL="https://access.redhat.com/downloads/content/480/ver=2.5/rhel---9/x86_64/product-software"

# Function to log messages
log_message() {
    echo "$(date) - $1" | tee -a $LOGFILE
}

log_message "===== Starting Server Setup ====="

# Loop through each server and perform setup tasks
for SERVER in "${SERVERS[@]}"; do
    log_message "===== Configuring $SERVER ====="

    ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" "bash -s" <<EOF

    set -e  # Exit script if any command fails

    # Task 2: Configure /etc/hosts
    log_message "Updating /etc/hosts..."
    sudo tee /etc/hosts <<EOL
    10.0.0.1 example1.com example1
    10.0.0.2 example2.com example2
    10.0.0.3 example3.com example3
    10.0.0.4 example4.com example4
    10.0.0.5 example5.com example5
    10.0.0.6 example6.com example6
    EOL

    # Task 3: Enable PasswordAuthentication in SSH
    sudo sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd

    # Task 4: Change root password
    echo "root:demo123" | sudo chpasswd

    # Task 5: Create partition 5 and extend rootvg
    echo -e "n\n5\n\n\nw" | sudo fdisk /dev/sda
    sudo partprobe /dev/sda
    sudo pvcreate /dev/sda5
    sudo vgextend rootvg /dev/sda5
    sudo lvextend -L+40G /dev/mapper/rootvg-rootlv
    sudo lvextend -L+10G /dev/mapper/rootvg-tmplv
    sudo resize2fs /dev/mapper/rootvg-rootlv
    sudo resize2fs /dev/mapper/rootvg-tmplv
    df -h

EOF

done

# Task 6: Set correct hostnames on each server
log_message "Setting correct hostnames on all servers..."

declare -A HOSTNAMES
HOSTNAMES=(
    ["10.0.0.1"]="example1.com"
    ["10.0.0.2"]="example2.com"
    ["10.0.0.3"]="example3.com"
    ["10.0.0.4"]="example4.com"
    ["10.0.0.5"]="example5.com"
    ["10.0.0.6"]="example6.com"
)

for SERVER in "${!HOSTNAMES[@]}"; do
    HOSTNAME="${HOSTNAMES[$SERVER]}"
    log_message "Setting hostname for $SERVER to $HOSTNAME..."
    
    ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" "sudo hostnamectl set-hostname $HOSTNAME"

    if [ $? -eq 0 ]; then
        log_message "✅ Successfully set hostname for $SERVER to $HOSTNAME"
    else
        log_message "❌ Failed to set hostname for $SERVER"
    fi
done

log_message "✅ All hostname changes completed!"

# Task 7: Mount NFS on each server
for SERVER in "${SERVERS[@]}"; do
    ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" "sudo mkdir -p /var/lib/pulp/ && sudo mount -t nfs $NFS_SERVER:$NFS_PATH $NFS_MOUNT -o vers=4,minorversion=1,sec=sys,nconnect=4"
done

# Task 8: Update /etc/fstab on each server
for SERVER in "${SERVERS[@]}"; do
    ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" "sudo cp /etc/fstab /etc/fstab.bak && echo \"$NFS_SERVER:$NFS_PATH $NFS_MOUNT nfs vers=4,minorversion=1,sec=sys,nconnect=4 0 0\" | sudo tee -a /etc/fstab"
done

# Task 9: Register servers with subscription manager
for SERVER in "${SERVERS[@]}"; do
    ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" "sudo subscription-manager register --username $RH_USERNAME --password $RH_PASSWORD --auto-attach && sudo subscription-manager repos --enable ansible-automation-platform-2.5-for-rhel-9-x86_64-rpms"
done

# Task 10: Fix repo issues and install required packages
for SERVER in "${SERVERS[@]}"; do
    ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" "sudo dnf update -y ca-certificates && sudo update-ca-trust extract && sudo update-ca-trust enable && sudo dnf remove -y rhui-azure-rhel9 && sudo dnf install -y rhui-azure-rhel9 && sudo yum install -y postgresql nfs-utils"
done

# Task 11: Download Ansible Automation Platform setup bundle on the first server
log_message "Downloading Ansible Automation Platform setup bundle..."
ssh -o StrictHostKeyChecking=no "$USERNAME@${SERVERS[0]}" "cd /opt && sudo curl -O $ANSIBLE_SETUP_BUNDLE_URL/ansible-automation-platform-setup-bundle-2.5-1-x86_64.tar.gz"

# Task 12: Create and append server list file
log_message "Creating /opt/server.txt on the first server..."
ssh -o StrictHostKeyChecking=no "$USERNAME@${SERVERS[0]}" "echo -e '${SERVERS[@]}' | tr ' ' '\n' | sudo tee /opt/server.txt"

# Task 13: Verification Step
for SERVER in "${SERVERS[@]}"; do
    log_message "Verifying setup on $SERVER..."
    ssh -o StrictHostKeyChecking=no "$USERNAME@$SERVER" "bash -s" <<EOF
    echo "===== Verification on $SERVER ====="
    echo "Checking hostname:" && hostnamectl status | grep "Static hostname" | grep "${HOSTNAMES[$SERVER]}"
    echo "Checking SSH config:" && grep "PasswordAuthentication" /etc/ssh/sshd_config
    echo "Checking root password change:" && sudo cat /etc/shadow | grep root
    echo "Checking partition and volume groups:" && lsblk | grep sda5 && sudo pvs && sudo vgs && sudo lvs && df -h
    echo "Checking /etc/hosts:" && cat /etc/hosts | grep "$SERVER"
    echo "Checking repo fix:" && sudo dnf repolist | grep rhui-azure-rhel9
    echo "Checking NFS mount:" && mount | grep /var/lib/pulp
EOF
done

log_message "===== All Tasks Completed Successfully ====="