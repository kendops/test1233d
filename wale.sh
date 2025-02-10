#!/bin/bash

LOG_FILE="/var/log/js_k8s_installation.log"
SUMMARY_FILE="/var/log/js_k8s_summary.log"
SUCCESS_LIST=()
FAILURE_LIST=()

# Color codes
GREEN='\033[0;32m'  # Green for success
RED='\033[0;31m'    # Red for failure
NC='\033[0m'        # No color

# Ensure the script runs with root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo).${NC}" | tee -a "$LOG_FILE"
   exit 1
fi

# Create/clear log files
echo "Installation started at $(date)" | tee "$LOG_FILE" "$SUMMARY_FILE"

echo "Updating system and setting up repositories..." | tee -a "$LOG_FILE"
dnf update -y 2>&1 | tee -a "$LOG_FILE"

echo "Installing required dependencies..." | tee -a "$LOG_FILE"
dnf install -y curl tar git 2>&1 | tee -a "$LOG_FILE"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

install_package() {
    package=$1
    install_cmd=$2
    check_cmd=$3
    version_cmd=$4

    if command_exists "$check_cmd"; then
        version=$($version_cmd 2>/dev/null)
        echo -e "${GREEN}✅ $package is already installed: $version${NC}" | tee -a "$LOG_FILE"
        SUCCESS_LIST+=("${GREEN}✅ $package ($version)${NC}")
    else
        echo "Installing $package..." | tee -a "$LOG_FILE"
        eval "$install_cmd" 2>&1 | tee -a "$LOG_FILE"
        
        if command_exists "$check_cmd"; then
            version=$($version_cmd 2>/dev/null)
            echo -e "${GREEN}✅ $package installed successfully: $version${NC}" | tee -a "$LOG_FILE"
            SUCCESS_LIST+=("${GREEN}✅ $package ($version)${NC}")
        else
            echo -e "${RED}❌ Failed to install $package!${NC}" | tee -a "$LOG_FILE"
            FAILURE_LIST+=("${RED}❌ $package${NC}")
        fi
    fi
}

# Install Node.js
install_package "Node.js 22" \
    "curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - && dnf install -y nodejs" \
    "node" "node -v"

# Install npm and yarn
install_package "npm" "npm install -g npm@latest" "npm" "npm -v"
install_package "yarn" "npm install -g corepack && corepack enable && corepack prepare yarn@stable --activate" "yarn" "yarn -v"

# JavaScript Dependencies
JS_DEPENDENCIES=("react@19" "react-dom@19" "react-router-dom@7.1.3" "react-hot-toast@2.5.1"
                 "@mui/material@6.4.2" "moment@2.30.1" "axios@1.7.9" "react-icons@1"
                 "react-hook-form@7.54.2" "next@15.1.6" "jwt-decode@1.0.2")

echo "Creating JavaScript project directory..." | tee -a "$LOG_FILE"
mkdir -p ~/js_project && cd ~/js_project || exit

echo "Initializing package.json..." | tee -a "$LOG_FILE"
npm init -y 2>&1 | tee -a "$LOG_FILE"

for package in "${JS_DEPENDENCIES[@]}"; do
    if npm list "$package" --depth=0 &>/dev/null; then
        echo -e "${GREEN}✅ $package is already installed.${NC}" | tee -a "$LOG_FILE"
        SUCCESS_LIST+=("${GREEN}✅ $package (Already Installed)${NC}")
    else
        echo "Installing $package..." | tee -a "$LOG_FILE"
        npm install "$package" 2>&1 | tee -a "$LOG_FILE"
        
        if npm list "$package" --depth=0 &>/dev/null; then
            echo -e "${GREEN}✅ $package installed successfully.${NC}" | tee -a "$LOG_FILE"
            SUCCESS_LIST+=("${GREEN}✅ $package${NC}")
        else
            echo -e "${RED}❌ Failed to install $package!${NC}" | tee -a "$LOG_FILE"
            FAILURE_LIST+=("${RED}❌ $package${NC}")
        fi
    fi
done

# Install Vite and Gatsby
install_package "Vite" "npm install -g vite@latest" "vite" "vite --version"
install_package "Gatsby" "npm install -g gatsby-cli@latest" "gatsby" "gatsby --version"

# Install kubectl
install_package "kubectl" \
    "curl -LO 'https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl' && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl" \
    "kubectl" "kubectl version --client --short"

# Install Minikube
install_package "Minikube" \
    "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && install minikube-linux-amd64 /usr/local/bin/minikube" \
    "minikube" "minikube version"

# Start Minikube
if command_exists "minikube"; then
    echo "Starting Minikube with Docker driver..." | tee -a "$LOG_FILE"
    minikube start --driver=docker 2>&1 | tee -a "$LOG_FILE"

    echo "Verifying Minikube Status..." | tee -a "$LOG_FILE"
    minikube status 2>&1 | tee -a "$LOG_FILE"
fi

# Final Summary with Colors
echo "------------------------------------------------" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
echo -e "${GREEN}✅ Successfully Installed:${NC}" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
for success in "${SUCCESS_LIST[@]}"; do
    echo -e "   - $success" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
done

echo "" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
echo -e "${RED}❌ Failed to Install:${NC}" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
for fail in "${FAILURE_LIST[@]}"; do
    echo -e "   - $fail" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
done

echo "" | tee -a "$LOG_FILE" "$SUMMARY_FILE"
echo "Installation completed at $(date)." | tee -a "$LOG_FILE" "$SUMMARY_FILE"
echo "Check logs at $LOG_FILE and summary at $SUMMARY_FILE." | tee -a "$LOG_FILE" "$SUMMARY_FILE"