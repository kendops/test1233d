#!/bin/bash

# Define colors
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# List of URLs to check
URLS=(
    "https://www.google.com"
    "https://www.github.com"
    "https://www.amazon.com"
    "https://www.microsoft.com"
    "https://www.linkedin.com"
    "https://www.apple.com"
    "https://www.cnn.com"
    "https://www.bbc.com"
    "https://www.wikipedia.org"
    "https://www.netflix.com"
)

# Function to check URL reachability
check_url() {
    local url=$1
    if curl --head --silent --fail "$url" > /dev/null; then
        echo -e "${GREEN}✔️  $url is reachable${RESET}"
    else
        echo -e "${RED}❌  $url is NOT reachable${RESET}"
    fi
}

# Loop through each URL and check
for url in "${URLS[@]}"; do
    check_url "$url"
done
