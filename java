#!/bin/bash

echo "Updating system packages..."
sudo dnf update -y

echo "Checking for available Java versions..."
sudo dnf list java-*

echo "Installing OpenJDK 21..."
sudo dnf install -y java-21-openjdk java-21-openjdk-devel

echo "Verifying Java installation..."
java -version

if java -version 2>&1 | grep -q "21"; then
    echo -e "[✔] Java 21 installed successfully."
else
    echo -e "[X] Java 21 installation failed."
fi