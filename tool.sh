#!/bin/bash

LOG_FILE="/var/log/js_k8s_installation.log"

# Ensure the script runs with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)." | tee -a "$LOG_FILE"
   exit 1
fi

# Create/clear the log file
echo "Installation started at $(date)" | tee "$LOG_FILE"

echo "Updating system and setting up repositories..." | tee -a "$LOG_FILE"
dnf update -y 2>&1 | tee -a "$LOG_FILE"

echo "Installing required dependencies..." | tee -a "$LOG_FILE"
dnf install -y curl tar git 2>&1 | tee -a "$LOG_FILE"

echo "Setting up Node.js 22 repository..." | tee -a "$LOG_FILE"
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - 2>&1 | tee -a "$LOG_FILE"
dnf install -y nodejs 2>&1 | tee -a "$LOG_FILE"

echo "Verifying Node.js installation..." | tee -a "$LOG_FILE"
node_version=$(node -v)
if [[ $node_version == "v22"* ]]; then
    echo "Node.js 22 installed successfully: $node_version" | tee -a "$LOG_FILE"
else
    echo "Node.js installation failed or incorrect version installed!" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Installing npm and yarn..." | tee -a "$LOG_FILE"
npm install -g npm@latest 2>&1 | tee -a "$LOG_FILE"
npm install -g corepack 2>&1 | tee -a "$LOG_FILE"
corepack enable 2>&1 | tee -a "$LOG_FILE"
corepack prepare yarn@stable --activate 2>&1 | tee -a "$LOG_FILE"

echo "Creating a React/Next.js project directory..." | tee -a "$LOG_FILE"
mkdir -p ~/js_project && cd ~/js_project || exit

echo "Initializing package.json..." | tee -a "$LOG_FILE"
npm init -y 2>&1 | tee -a "$LOG_FILE"

echo "Installing dependencies..." | tee -a "$LOG_FILE"
npm install react@19 react-dom@19 react-router-dom@7.1.3 react-hot-toast@2.5.1 \
            @mui/material@6.4.2 moment@2.30.1 axios@1.7.9 react-icons@1 \
            react-hook-form@7.54.2 next@15.1.6 jwt-decode@1.0.2 2>&1 | tee -a "$LOG_FILE"

echo "------------------------------------------------" | tee -a "$LOG_FILE"
echo "Installing Kubernetes Tools (kubectl & Minikube)..." | tee -a "$LOG_FILE"
echo "------------------------------------------------" | tee -a "$LOG_FILE"

echo "Installing kubectl..." | tee -a "$LOG_FILE"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" 2>&1 | tee -a "$LOG_FILE"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl 2>&1 | tee -a "$LOG_FILE"

echo "Installing Minikube..." | tee -a "$LOG_FILE"
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 2>&1 | tee -a "$LOG_FILE"
install minikube-linux-amd64 /usr/local/bin/minikube 2>&1 | tee -a "$LOG_FILE"

echo "------------------------------------------------" | tee -a "$LOG_FILE"
echo "Starting Minikube with Docker driver..." | tee -a "$LOG_FILE"
echo "------------------------------------------------" | tee -a "$LOG_FILE"

minikube start --driver=docker 2>&1 | tee -a "$LOG_FILE"

echo "------------------------------------------------" | tee -a "$LOG_FILE"
echo "Verifying Installations..." | tee -a "$LOG_FILE"
echo "------------------------------------------------" | tee -a "$LOG_FILE"

# Check npm version
npm_version=$(npm -v)
echo "npm Version: $npm_version" | tee -a "$LOG_FILE"

# Check yarn version
yarn_version=$(yarn -v 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "Yarn Version: $yarn_version" | tee -a "$LOG_FILE"
else
    echo "Yarn is not installed." | tee -a "$LOG_FILE"
fi

# Check installed package versions
echo "------------------------------------------------" | tee -a "$LOG_FILE"
echo "Checking installed package versions in js_project..." | tee -a "$LOG_FILE"
npm list --depth=0 | grep -E 'react@|react-dom@|react-router-dom@|react-hot-toast@|@mui/material@|moment@|axios@|react-icons@|react-hook-form@|next@|jwt-decode@' | tee -a "$LOG_FILE"

echo "------------------------------------------------" | tee -a "$LOG_FILE"
echo "Verifying Kubernetes Installations..." | tee -a "$LOG_FILE"
echo "------------------------------------------------" | tee -a "$LOG_FILE"

kubectl_version=$(kubectl version --client --short 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "kubectl Version: $kubectl_version" | tee -a "$LOG_FILE"
else
    echo "kubectl is not installed or not configured correctly." | tee -a "$LOG_FILE"
fi

minikube_status=$(minikube status 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "Minikube Status: " | tee -a "$LOG_FILE"
    echo "$minikube_status" | tee -a "$LOG_FILE"
else
    echo "Minikube is not running or not installed correctly." | tee -a "$LOG_FILE"
fi

echo "------------------------------------------------" | tee -a "$LOG_FILE"
echo "Checking repository sources..." | tee -a "$LOG_FILE"
echo "------------------------------------------------" | tee -a "$LOG_FILE"
for package in react react-dom react-router-dom react-hot-toast @mui/material moment axios react-icons react-hook-form next jwt-decode; do
    echo "$package: $(npm view $package dist.tarball)" | tee -a "$LOG_FILE"
done

echo "------------------------------------------------" | tee -a "$LOG_FILE"
echo "Installation and verification complete! Log file: $LOG_FILE" | tee -a "$LOG_FILE"