
#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update and install necessary packages
echo "Updating packages..."
apt update && apt upgrade -y

# Install Docker
echo "Installing Docker..."
apt install -y docker.io
systemctl start docker
systemctl enable docker

# Pull Android image (e.g., android-x86)
echo "Pulling Android Docker image..."
docker pull jfloff/alpine-x86

# Create a directory for Android container
mkdir -p /opt/android-docker
cd /opt/android-docker

# Dockerfile for Android x86 with VNC server
echo "Creating Dockerfile..."
cat <<EOF > Dockerfile
FROM jfloff/alpine-x86

# Install required packages
RUN apk update && apk add openbox xfce4-terminal x11vnc xvfb

# Set environment variables
ENV DISPLAY :1

# Expose VNC port
EXPOSE 5901

# Start VNC server
CMD ["xvfb-run", "-s", "'-screen 0 1280x720x16'", "x11vnc", "-forever", "-usepw", "-create"]
EOF

# Build Docker image
echo "Building Docker image..."
docker build -t android-vnc .

# Run the Android container with VNC support
echo "Running Android container..."
docker run -d -p 5901:5901 --name android-vnc android-vnc

# Set VNC password
echo "Setting VNC password..."
docker exec -it android-vnc x11vnc -storepasswd

# Display connection instructions
echo "Setup complete! You can connect to your Android VM using a VNC client on port 5901."
