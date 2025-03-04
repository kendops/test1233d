# Download Java 21 RPM package
wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.rpm

# Install Java 21
sudo rpm -ivh jdk-21_linux-x64_bin.rpm

# Verify installation
java -version

# Set Java 21 as default (if needed)
sudo alternatives --install /usr/bin/java java /usr/java/jdk-21/bin/java 1
sudo alternatives --config java

# Check Java path
which java

# Set environment variables (optional)
echo 'export JAVA_HOME=/usr/java/jdk-21' | sudo tee -a /etc/profile
echo 'export PATH=$JAVA_HOME/bin:$PATH' | sudo tee -a /etc/profile
source /etc/profile
