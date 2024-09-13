#!/bin/bash
sudo apt update -y
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
#!/bin/bash

# Update the package list and install dependencies
sudo apt update -y

# Install AdoptOpenJDK Temurin 17
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt update -y
sudo apt install temurin-17-jdk -y
/usr/bin/java --version

# Add Jenkins repository and install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y

# Start Jenkins service
sudo systemctl start jenkins

# Wait for Jenkins to start
while ! sudo systemctl status jenkins | grep "active (running)"; do
  sleep 5
done

# Initial Jenkins setup
sudo curl -LO http://localhost:8080/jnlpJars/jenkins-cli.jar

# Retrieve the initial admin password for Jenkins
ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "Initial Admin Password: $ADMIN_PASSWORD"

# Create an admin account using the Jenkins CLI
echo "jenkins.model.Jenkins.instance.securityRealm.createAccount('admin', 'admin')" | java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:$ADMIN_PASSWORD groovy =

# Install necessary plugins
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin install-plugin git matrix-auth workflow-aggregator docker-workflow blueocean credentials-binding

# Restart Jenkins safely to apply the changes
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth admin:admin safe-restart

# Check Jenkins status after restart
sudo systemctl status jenkins


##Install Docker and Run SonarQube as Container
sudo apt-get update
sudo apt-get install docker.io -y
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins  
newgrp docker
sudo chmod 777 /var/run/docker.sock
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

#install trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y
