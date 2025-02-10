#!/bin/bash

LOG_FILE="/var/log/js_k8s_installation.log"
SUMMARY_FILE="/var/log/js_k8s_summary.log"
SUCCESS_LIST=()
FAILURE_LIST=()

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo).${NC}" | tee -a "$LOG_FILE"
   exit 1
fi

# Clear previous logs
echo "Installation started at $(date)" | tee "$LOG_FILE" "$SUMMARY_FILE"

echo "Updating system..." | tee -a "$LOG_FILE"
dnf update -y 2>&1 | tee -a "$LOG_FILE" || echo -e "${RED}⚠️ System update failed! Continuing...${NC}" | tee -a "$LOG_FILE"

echo "Installing dependencies..." | tee -a "$LOG_FILE"
dnf install -y curl tar git 2>&1 | tee -a "$LOG_FILE" || echo -e "${RED}⚠️ Some dependencies failed!${NC}" | tee -a "$LOG_FILE"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

install_package() {
    local package="$1"
    local install_cmd="$2"
    local check_cmd="$3"
    local version_cmd="$4"

    if command_exists "$check_cmd"; then
        version=$($version_cmd 2>/dev/null)
        echo -e "${GREEN}✅ $package is already installed: $version${NC}" | tee -a "$LOG_FILE"
        SUCCESS_LIST+=("${GREEN}✅ $package ($version)${NC}")
        return
    fi

    echo "Installing $package..." | tee -a "$LOG_FILE"
    eval "$install_cmd" 2>&1 | tee -a "$LOG_FILE" &
    PID=$!
    wait $PID

    if command_exists "$check_cmd"; then
        version=$($version_cmd 2>/dev/null)
        echo -e "${GREEN}✅ $package installed successfully: $version${NC}" | tee -a "$LOG_FILE"
        SUCCESS_LIST+=("${GREEN}✅ $package ($version)${NC}")
    else
        echo -e "${RED}❌ Failed to install $package! Skipping...${NC}" | tee -a "$LOG_FILE"
        FAILURE_LIST+=("${RED}❌ $package${NC}")
    fi
}

# Install Docker
install_package "Docker" \
    "dnf install -y docker && systemctl start docker && systemctl enable docker" \
    "docker" "docker --version"

# Add user to Docker group
echo "Adding user to Docker group..." | tee -a "$LOG_FILE"
groupadd docker 2>/dev/null
usermod -aG docker "$USER" && newgrp docker

# Install Node.js
install_package "Node.js 22" \
    "curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - && dnf install -y nodejs" \
    "node" "node -v"

# Install npm
install_package "npm" "npm install -g npm@11" "npm" "npm -v"

# Install yarn with retry logic
for attempt in {1..3}; do
    install_package "yarn" "npm install -g corepack && corepack enable && corepack prepare yarn@stable --activate" "yarn" "yarn -v"
    if command_exists "yarn"; then break; fi
    echo -e "${RED}Retrying Yarn installation (Attempt $attempt)...${NC}" | tee -a "$LOG_FILE"
    sleep 3
done

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
        npm install "$package" --silent 2>&1 | tee -a "$LOG_FILE" || echo -e "${RED}❌ Skipping $package.${NC}" | tee -a "$LOG_FILE"
    fi
done

# Install Vite 15.16
install_package "Vite 15.16" "npm install -g vite@15.16" "vite" "vite --version"

# Install Gatsby 15.1.6
install_package "Gatsby 15.1.6" "npm install -g gatsby-cli@15.1.6" "gatsby" "gatsby --version"

# Install kubectl
install_package "kubectl" \
    "curl -LO 'https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl' && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl" \
    "kubectl" "kubectl version --client --short"

# Install Minikube
install_package "Minikube" \
    "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && install minikube-linux-amd64 /usr/local/bin/minikube" \
    "minikube" "minikube version"

# Start Minikube with timeout
if command_exists "minikube"; then
    echo "Starting Minikube with Docker driver..." | tee -a "$LOG_FILE"
    timeout 180s minikube start --driver=docker 2>&1 | tee -a "$LOG_FILE" || echo -e "${RED}❌ Minikube start timed out.${NC}" | tee -a "$LOG_FILE"
fi

# Final Summary
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