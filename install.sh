#!/bin/bash

# Colors for output
GREEN="\e[32m✔"
RED="\e[31m✘"
NC="\e[0m"  # No Color

# Log file for verification
LOG_FILE="./verification_log.txt"
> "$LOG_FILE"  # Clear the log file if it already exists

# Software list with the correct commands to check their version
declare -A version_commands=(
  ["NodeJS"]="node -v"
  ["React"]="npm list -g react --depth=0 | grep react"
  ["jwt-decode"]="npm list -g jwt-decode --depth=0 | grep jwt-decode"
  ["react-router-dom"]="npm list -g react-router-dom --depth=0 | grep react-router-dom"
  ["react-hot-toast"]="npm list -g react-hot-toast --depth=0 | grep react-hot-toast"
  ["material UI"]="npm list -g @mui/material --depth=0 | grep @mui/material"
  ["moment"]="npm list -g moment --depth=0 | grep moment"
  ["axios"]="npm list -g axios --depth=0 | grep axios"
  ["react-icon"]="npm list -g react-icons --depth=0 | grep react-icons"
  ["react-hook-form"]="npm list -g react-hook-form --depth=0 | grep react-hook-form"
  ["NextJS"]="npm list -g next --depth=0 | grep next"
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