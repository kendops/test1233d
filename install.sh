#!/bin/bash

# Colors for output
GREEN="\e[32m✔"
RED="\e[31m✘"
NC="\e[0m"  # No Color

# Log file for verification
LOG_FILE="./verification_log.txt"
> "$LOG_FILE"  # Clear the log file if it already exists

# Software list with the commands to check their version
declare -A version_commands=(
  ["NodeJS"]="node --version"
  ["React"]="npm list -g react | grep react"
  ["jwt-decode"]="npm list -g jwt-decode | grep jwt-decode"
  ["react-router-dom"]="npm list -g react-router-dom | grep react-router-dom"
  ["react-hot-toast"]="npm list -g react-hot-toast | grep react-hot-toast"
  ["material UI"]="npm list -g @mui/material | grep @mui/material"
  ["moment"]="npm list -g moment | grep moment"
  ["axios"]="npm list -g axios | grep axios"
  ["react-icon"]="npm list -g react-icons | grep react-icons"
  ["react-hook-form"]="npm list -g react-hook-form | grep react-hook-form"
  ["NextJS"]="npm list -g next | grep next"
  ["Vite"]="vite --version"
  ["Gatsby"]="gatsby --version"
  ["kubectl"]="kubectl version --client --short"
  ["Docker"]="docker --version"
  ["Minikube"]="minikube version"
  ["MySQL Client"]="mysql --version"
)

# Header for verification output
echo -e "Software Installation Verification\n" | tee -a "$LOG_FILE"
echo -e "Software\t\tVersion\t\tStatus" | tee -a "$LOG_FILE"
echo "-----------------------------------------------------" | tee -a "$LOG_FILE"

# Check each software and its version
for software in "${!version_commands[@]}"; do
  version=$(${version_commands[$software]} 2>/dev/null)

  if [ $? -eq 0 ]; then
    echo -e "$software\t\t$version\t\t${GREEN}Installed${NC}" | tee -a "$LOG_FILE"
  else
    echo -e "$software\t\tN/A\t\t${RED}Not Installed${NC}" | tee -a "$LOG_FILE"
  fi
done

# Summary
echo -e "\nVerification completed. Check $LOG_FILE for detailed results."