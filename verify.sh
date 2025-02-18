#!/bin/bash

# Define a list of software to check
declare -A packages=(
    ["java"]="java -version"
    ["maven"]="mvn -version"
    ["spring-boot"]="mvn dependency:tree | grep spring-boot"
    ["spring-boot-jpa"]="mvn dependency:tree | grep spring-data-jpa"
    ["spring-boot-oauth2-client"]="mvn dependency:tree | grep spring-security-oauth2-client"
    ["spring-boot-oauth2-resource-server"]="mvn dependency:tree | grep spring-security-oauth2-resource-server"
    ["spring-boot-security"]="mvn dependency:tree | grep spring-security"
    ["spring-boot-web"]="mvn dependency:tree | grep spring-boot-starter-web"
    ["spring-boot-webflux"]="mvn dependency:tree | grep spring-boot-starter-webflux"
    ["mysql-connector"]="mvn dependency:tree | grep mysql-connector-java"
    ["lombok"]="mvn dependency:tree | grep lombok"
    ["spring-boot-test"]="mvn dependency:tree | grep spring-boot-starter-test"
    ["reactor-test"]="mvn dependency:tree | grep reactor-test"
    ["spring-boot-security-test"]="mvn dependency:tree | grep spring-security-test"
    ["spring-boot-email"]="mvn dependency:tree | grep spring-boot-starter-mail"
    ["jwt-jackson"]="mvn dependency:tree | grep jackson"
    ["jwt-impl"]="mvn dependency:tree | grep jwt-impl"
    ["jwt-api"]="mvn dependency:tree | grep jwt-api"
)

# Function to check installation status
check_installation() {
    eval "$1" &>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "[✔] $2 is installed"
    else
        echo -e "[X] $2 is NOT installed"
    fi
}

echo "Verifying installed software on RHEL 8..."

# Iterate over packages
for package in "${!packages[@]}"; do
    check_installation "${packages[$package]}" "$package"
done

echo "Verification process completed!"