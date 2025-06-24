#!/bin/bash

# Docker Installation and Configuration Script
# Usage: 
#   ./docker-setup.sh REGISTRY_URL [IMAGE_NAME]
#   wget -O - https://your-server.com/docker-setup.sh | bash -s -- REGISTRY_URL [IMAGE_NAME]

set -e  # Exit on any error

# Check if registry URL is provided
if [ -z "$1" ]; then
    echo "Error: Registry URL is required"
    echo "Usage: $0 REGISTRY_URL [IMAGE_NAME]"
    echo "Example: $0 192.168.1.100:5000 visitor-image:test"
    exit 1
fi

# Set parameters
REGISTRY_URL="$1"
IMAGE_NAME="${2:-visitor-image:test}"
FULL_IMAGE="${REGISTRY_URL}/${IMAGE_NAME}"

echo "Starting Docker installation and configuration..."
echo "Registry URL: $REGISTRY_URL"
echo "Image: $FULL_IMAGE"

# Update package list
echo "Updating package list..."
sudo apt-get update

# Install required packages
echo "Installing required packages..."
sudo apt-get install -y ca-certificates curl nano

# Create keyrings directory
echo "Setting up Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings

# Download Docker's GPG key
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again
sudo apt-get update

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker daemon
echo "Configuring Docker daemon..."
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "insecure-registries": ["$REGISTRY_URL"]
}
EOF

# Restart Docker service
echo "Restarting Docker service..."
sudo service docker restart

# Wait for Docker to start
echo "Waiting for Docker to start..."
sleep 5

# Pull the image
echo "Pulling Docker image..."
sudo docker pull $FULL_IMAGE

# Start Portainer Agent
echo "Starting Portainer Agent..."
sudo docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:2.21.1

echo "Docker installation and configuration completed successfully!"
echo "Image '$FULL_IMAGE' has been pulled."
echo "Portainer Agent is running on port 9001"
