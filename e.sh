#!/bin/bash

# Variables
DISPLAY_NUMBER=":1"
VNC_PORT="5901"
DESKTOP_ENVIRONMENT="Xfce"
ANDROID_VERSION="android-12"  # Adjust as needed
AVD_NAME="cloud_android_${ANDROID_VERSION}"
ANDROID_SDK_ROOT="/opt/android-sdk"
ANDROID_SDK_TOOLS="$ANDROID_SDK_ROOT/cmdline-tools/bin"

# Update system
echo "Updating system packages..."
sudo dnf update -y

# Install Desktop Environment
echo "Installing $DESKTOP_ENVIRONMENT desktop environment..."
sudo dnf groupinstall "$DESKTOP_ENVIRONMENT" -y

# Install VNC Server
echo "Installing VNC server..."
sudo dnf install -y tigervnc-server

# Create VNC startup script
echo "Creating VNC startup script..."
mkdir -p ~/.vnc
cat <<EOL > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4 &
EOL
chmod +x ~/.vnc/xstartup

# Start VNC server
echo "Starting VNC server..."
vncserver $DISPLAY_NUMBER -geometry 1280x720 -depth 24

# Configure Firewall
echo "Configuring firewall to allow VNC connections..."
sudo firewall-cmd --zone=public --add-port=$VNC_PORT/tcp --permanent
sudo firewall-cmd --reload

# Install Java (required for Android SDK)
echo "Installing Java (JDK)..."
sudo dnf install -y java-1.8.0-openjdk-devel

# Install Android SDK tools
echo "Installing Android SDK tools..."
sudo dnf install -y wget unzip
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O android_sdk.zip
    sudo mkdir -p $ANDROID_SDK_ROOT
    sudo unzip android_sdk.zip -d $ANDROID_SDK_ROOT
    rm android_sdk.zip
fi

# Set up environment variables
echo "Setting up environment variables..."
echo 'export ANDROID_SDK_ROOT=/opt/android-sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/bin:$ANDROID_SDK_ROOT/platform-tools' >> ~/.bashrc
source ~/.bashrc

# Update Android SDK components
echo "Updating Android SDK components..."
yes | sdkmanager --licenses
sdkmanager "platform-tools" "emulator"

# Install the system image for the new Android version
echo "Installing system image for Android version $ANDROID_VERSION..."
sdkmanager "system-images;$ANDROID_VERSION;google_apis;x86_64"

# Create or delete old AVD
if avdmanager list avd | grep -q "$AVD_NAME"; then
    echo "Deleting old AVD named $AVD_NAME..."
    avdmanager delete avd -n "$AVD_NAME"
fi

# Create a new AVD
echo "Creating a new AVD named $AVD_NAME..."
echo no | avdmanager create avd -n "$AVD_NAME" -k "system-images;$ANDROID_VERSION;google_apis;x86_64" --device "pixel_3"

# Configure KVM for Android Emulator
echo "Configuring KVM for Android Emulator..."
sudo setfacl -m u:$USER:rwx /dev/kvm

# Increase swap memory if not already configured
echo "Configuring swap memory..."
if ! grep -q '/swapfile' /etc/fstab; then
    sudo fallocate -l 8G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    sudo sysctl vm.swappiness=10
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
fi

# Create desktop start script for Android emulator
echo "Creating start script for Android emulator on desktop..."
cat <<EOL > ~/Desktop/start_android_emulator.sh
#!/bin/bash
emulator -avd "$AVD_NAME" -no-boot-anim -gpu on -no-window
EOL
chmod +x ~/Desktop/start_android_emulator.sh

# Print VNC connection information
echo "VNC server setup is complete."
echo "Connect to your server's IP address at port $VNC_PORT (e.g., 192.168.1.100:5901)."
echo "Use the script 'start_android_emulator.sh' on the desktop to start the Android emulator."
