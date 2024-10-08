#!/bin/bash

# Variables
DISPLAY_NUMBER=":1"
VNC_PORT="5901"
ANDROID_VERSION="android-11"  # Android 11 lite version
AVD_NAME="cloud_android_${ANDROID_VERSION}"
ANDROID_SDK_ROOT="/opt/android-sdk"
ANDROID_SDK_TOOLS="$ANDROID_SDK_ROOT/cmdline-tools/bin"
DEBUG_LOG_FILE="/var/log/android_setup_debug.log"

# Redirect stdout and stderr to debug log file
exec > >(tee -a "$DEBUG_LOG_FILE") 2>&1

echo "Starting Android with VNC and Fluxbox setup script on Ubuntu 22.04..."

# Update system
echo "Updating system packages..."
sudo apt update -y && sudo apt upgrade -y || { echo "Failed to update packages"; exit 1; }

# Install minimal window manager (Fluxbox)
echo "Installing Fluxbox window manager..."
sudo apt install -y fluxbox || { echo "Failed to install Fluxbox"; exit 1; }

# Install VNC server (TigerVNC)
echo "Installing VNC server (TigerVNC)..."
sudo apt install -y tigervnc-standalone-server || { echo "Failed to install VNC server"; exit 1; }

# Install X11 utilities
echo "Installing X11 utilities..."
sudo apt install -y xorg xauth x11-apps || { echo "Failed to install X11 utilities"; exit 1; }

# Install Java 11 (required for Android SDK)
echo "Installing Java 11 (JDK)..."
sudo apt install -y openjdk-11-jdk || { echo "Failed to install Java"; exit 1; }

# Set Java 11 as default
echo "Configuring Java 11 as default..."
sudo update-alternatives --config java || { echo "Failed to configure Java alternatives"; exit 1; }

# Install Android SDK tools
echo "Installing Android SDK tools..."
sudo apt install -y wget unzip || { echo "Failed to install wget and unzip"; exit 1; }
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O android_sdk.zip || { echo "Failed to download Android SDK"; exit 1; }
    sudo mkdir -p $ANDROID_SDK_ROOT
    sudo unzip android_sdk.zip -d $ANDROID_SDK_ROOT || { echo "Failed to unzip Android SDK"; exit 1; }
    rm android_sdk.zip
fi

# Set up environment variables
echo "Setting up environment variables..."
echo 'export ANDROID_SDK_ROOT=/opt/android-sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/bin:$ANDROID_SDK_ROOT/platform-tools' >> ~/.bashrc
source ~/.bashrc

# Install additional dependencies for Android SDK
sudo apt install -y libvirt-daemon libvirt-clients bridge-utils || { echo "Failed to install KVM dependencies"; exit 1; }

# Enable KVM (Kernel-based Virtual Machine)
echo "Enabling KVM for Android Emulator..."
sudo adduser $USER kvm || { echo "Failed to add user to kvm group"; exit 1; }

# Update Android SDK components
echo "Updating Android SDK components..."
yes | sdkmanager --licenses || { echo "Failed to accept SDK licenses"; exit 1; }
sdkmanager "platform-tools" "emulator" || { echo "Failed to install platform-tools or emulator"; exit 1; }

# Install the system image for the new Android version (lite version)
echo "Installing system image for Android version $ANDROID_VERSION..."
sdkmanager "system-images;$ANDROID_VERSION;google_apis;x86_64" || { echo "Failed to install system image"; exit 1; }

# Handle JNI errors: Reinstall or update emulator
echo "Checking and updating emulator..."
sdkmanager --uninstall emulator || { echo "Failed to uninstall emulator"; exit 1; }
sdkmanager --install emulator || { echo "Failed to install emulator"; exit 1; }

# Create or delete old AVD
if avdmanager list avd | grep -q "$AVD_NAME"; then
    echo "Deleting old AVD named $AVD_NAME..."
    avdmanager delete avd -n "$AVD_NAME" || { echo "Failed to delete old AVD"; exit 1; }
fi

# Create a new AVD
echo "Creating a new AVD named $AVD_NAME..."
echo no | avdmanager create avd -n "$AVD_NAME" -k "system-images;$ANDROID_VERSION;google_apis;x86_64" --device "pixel_3" || { echo "Failed to create AVD"; exit 1; }

# Configure KVM for Android Emulator
echo "Configuring KVM for Android Emulator..."
sudo setfacl -m u:$USER:rwx /dev/kvm || { echo "Failed to configure KVM"; exit 1; }

# Increase swap memory if not already configured
echo "Configuring swap memory..."
if ! grep -q '/swapfile' /etc/fstab; then
    sudo fallocate -l 8G /swapfile || { echo "Failed to create swap file"; exit 1; }
    sudo chmod 600 /swapfile || { echo "Failed to set swap file permissions"; exit 1; }
    sudo mkswap /swapfile || { echo "Failed to set up swap file"; exit 1; }
    sudo swapon /swapfile || { echo "Failed to enable swap file"; exit 1; }
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab || { echo "Failed to add swap file to fstab"; exit 1; }
    sudo sysctl vm.swappiness=10 || { echo "Failed to set swap swappiness"; exit 1; }
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf || { echo "Failed to set swap swappiness in sysctl.conf"; exit 1; }
fi

# Configure the VNC startup script
echo "Creating VNC startup script..."
mkdir -p ~/.vnc
cat <<EOL > ~/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec fluxbox &
EOL
chmod +x ~/.vnc/xstartup

# Start the VNC server
echo "Starting VNC server..."
vncserver $DISPLAY_NUMBER -geometry 1280x720 -depth 24 || { echo "Failed to start VNC server"; exit 1; }

# Configure firewall to allow VNC connections
echo "Configuring firewall to allow VNC connections..."
sudo ufw allow $VNC_PORT/tcp || { echo "Failed to configure firewall"; exit 1; }
sudo ufw reload || { echo "Failed to reload firewall"; exit 1; }

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
