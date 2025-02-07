#!/bin/bash

# Ensure the script runs with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)." 
   exit 1
fi

echo "Updating system packages..."
dnf update -y

echo "Installing Node.js 22 from NodeSource repository..."
echo "Source: https://rpm.nodesource.com/"
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs

echo "Installing npm and yarn from npm registry..."
echo "Source: https://registry.npmjs.org/"
npm install -g npm@latest
npm install -g yarn

echo "Creating a React/Next.js project directory..."
mkdir -p ~/js_project
cd ~/js_project || exit

echo "Initializing a package.json file..."
npm init -y

echo "Installing React and dependencies from npm registry..."
npm install react@19 react-dom@19 \
            react-router-dom@7.1.3 react-hot-toast@2.5.1 \
            @mui/material@6.4.2 moment@2.30.1 axios@1.7.9 \
            react-icons@1 react-hook-form@7.54.2 \
            next@15.1.6 jwt-decode@1.0.2

echo "------------------------------------------------"
echo "Verifying installations and sources..."
echo "------------------------------------------------"

# Check Node.js version and source
node_version=$(node -v)
echo "Node.js Version: $node_version"
echo "Installed from: https://rpm.nodesource.com/"

# Check npm version and source
npm_version=$(npm -v)
echo "npm Version: $npm_version"
echo "Installed from: https://registry.npmjs.org/"

# Check yarn version
yarn_version=$(yarn -v 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "Yarn Version: $yarn_version"
    echo "Installed from: https://registry.npmjs.org/"
else
    echo "Yarn is not installed."
fi

# Display sources for installed npm packages
echo "------------------------------------------------"
echo "Installed JavaScript packages and their sources:"
for package in react react-dom react-router-dom react-hot-toast \
               @mui/material moment axios react-icons \
               react-hook-form next jwt-decode; do
    source_url="https://www.npmjs.com/package/$package"
    echo "$package: $source_url"
done

echo "------------------------------------------------"
echo "Installation and verification complete!"

