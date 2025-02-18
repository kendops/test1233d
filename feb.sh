#!/bin/bash

# Define an associative array with package names and their respective versions
declare -A packages=(
    ["java"]="https://www.oracle.com/java/technologies/javase-jdk11-downloads.html 3.9.5"
    ["maven"]="https://maven.apache.org/download.cgi 3.4.1"
    ["spring-boot"]="https://spring.io/projects/spring-boot 3.4.1"
    ["spring-boot-jpa"]="https://spring.io/projects/spring-data-jpa 3.4.1"
    ["spring-boot-oauth2-client"]="https://spring.io/guides/tutorials/spring-boot-oauth2/ 3.4.1"
    ["spring-boot-oauth2-resource-server"]="https://spring.io/guides/tutorials/spring-boot-oauth2/ 3.4.1"
    ["spring-boot-security"]="https://spring.io/projects/spring-security 3.4.1"
    ["spring-boot-web"]="https://spring.io/guides/gs/serving-web-content/ 3.4.1"
    ["spring-boot-webflux"]="https://spring.io/projects/spring-webflux 3.4.1"
    ["mysql-connector"]="https://dev.mysql.com/downloads/connector/ 3.4.1"
    ["lombok"]="https://projectlombok.org/download 3.4.1"
    ["spring-boot-test"]="https://docs.spring.io/spring-boot/docs/current/reference/html/boot-features-testing.html 3.4.1"
    ["reactor-test"]="https://projectreactor.io/ 3.4.1"
    ["spring-boot-security-test"]="https://spring.io/projects/spring-security-test 3.4.1"
    ["spring-boot-email"]="https://spring.io/guides/gs/email/ 3.4.1"
    ["jwt-jackson"]="https://github.com/auth0/java-jwt 0.12.6"
    ["jwt-impl"]="https://github.com/auth0/java-jwt 0.12.6"
    ["jwt-api"]="https://github.com/auth0/java-jwt 0.12.6"
)

# Function to check installation status
check_installation() {
    command -v "$1" &>/dev/null && echo -e "[✔] $1 installed successfully" || echo -e "[X] $1 installation failed"
}

echo "Starting installation on RHEL 8..."

# Ensure system is up to date
sudo dnf update -y

# Iterate over packages
for package in "${!packages[@]}"; do
    url_version=(${packages[$package]})
    url=${url_version[0]}
    version=${url_version[1]}

    echo "Installing $package (Version: $version) from $url..."

    case $package in
        "java")
            sudo dnf install java-11-openjdk-devel -y
            ;;
        "maven")
            sudo dnf install maven -y
            ;;
        "mysql-connector")
            sudo dnf install mysql-connector-java -y
            ;;
        *)
            echo "Maven dependency: Adding $package ($version) to project dependencies..."
            ;;
    esac

    # Validate installation
    check_installation "$package"
done

echo "Installation process completed!"