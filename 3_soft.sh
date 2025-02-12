#!/bin/bash

# Colors for output
GREEN="\e[32m✔"
RED="\e[31m✘"
NC="\e[0m"  # No Color

# Log file
LOG_FILE="./installation_log.txt"
> "$LOG_FILE"  # Clear the log file if it already exists

# Step 1: Install npm first
echo -e "\nInstalling npm..." | tee -a "$LOG_FILE"
sudo yum install -y npm &>> "$LOG_FILE"
if [ $? -eq 0 ]; then
  echo -e "${GREEN} npm installed successfully${NC}" | tee -a "$LOG_FILE"
else
  echo -e "${RED} npm installation failed${NC}" | tee -a "$LOG_FILE"
  exit 1  # Exit if npm installation fails
fi

# Software list
declare -A software_list=(
  ["NodeJS"]="curl -sL https://rpm.nodesource.com/setup_22.x | sudo bash - && sudo yum install -y nodejs"
  ["React"]="npm install -g react@19"
  ["jwt-decode"]="npm install -g jwt-decode@1.0.2"
  ["react-router-dom"]="npm install -g react-router-dom@7.1.3"
  ["react-hot-toast"]="npm install -g react-hot-toast@2.5.1"
  ["material UI"]="npm install -g @mui/material@6.4.2"
  ["moment"]="npm install -g moment@2.30.1"
  ["axios"]="npm install -g axios@1.7.9"
  ["react-icon"]="npm install -g react-icons@1"
  ["react-hook-form"]="npm install -g react-hook-form@7.54.2"
  ["NextJS"]="npm install -g next@15.1.6"
  ["Vite"]="npm install -g vite@5"
  ["Gatsby"]="npm install -g gatsby-cli@15.1.6"
  ["kubectl"]="sudo yum install -y kubectl"
  ["Docker"]="sudo yum install -y docker"
  ["Minikube"]="curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube"
  ["MySQL Client"]="sudo yum install -y mysql"
)

# Installation function
install_software() {
  local name="$1"
  local command="$2"

  echo -e "\nInstalling $name..." | tee -a "$LOG_FILE"
  eval "$command" &>> "$LOG_FILE"
  if [ $? -eq 0 ]; then
    echo -e "${GREEN} $name installed successfully${NC}" | tee -a "$LOG_FILE"
    return 0
  else
    echo -e "${RED} $name failed to install${NC}" | tee -a "$LOG_FILE"
    return 1
  fi
}

# Track installation results
declare -A install_results

# Install all software
for software in "${!software_list[@]}"; do
  install_software "$software" "${software_list[$software]}"
  install_results["$software"]=$?
done

# Docker post-install steps
if [ "${install_results["Docker"]}" -eq 0 ]; then
  echo -e "\nConfiguring Docker..." | tee -a "$LOG_FILE"
  sudo groupadd docker &>> "$LOG_FILE" || true  # Ignore if group already exists
  sudo usermod -aG docker root &>> "$LOG_FILE"
  sudo systemctl start docker &>> "$LOG_FILE"
  sudo systemctl enable docker &>> "$LOG_FILE"
  sudo systemctl is-active --quiet docker
  if [ $? -eq 0 ]; then
    echo -e "${GREEN} Docker is running${NC}" | tee -a "$LOG_FILE"
  else
    echo -e "${RED} Docker failed to start${NC}" | tee -a "$LOG_FILE"
  fi
fi

# Summary
echo -e "\nInstallation Summary:" | tee -a "$LOG_FILE"
for software in "${!install_results[@]}"; do
  if [ "${install_results[$software]}" -eq 0 ]; then
    echo -e "${GREEN} $software: Installed successfully${NC}" | tee -a "$LOG_FILE"
  else
    echo -e "${RED} $software: Failed to install${NC}" | tee -a "$LOG_FILE"
  fi
done

exit 0