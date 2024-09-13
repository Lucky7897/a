#!/bin/bash

# Variables
NEW_ANDROID_VERSION="android-12"  # Change to the desired version (e.g., "android-11" or "android-12")
NEW_AVD_NAME="cloud_android_${NEW_ANDROID_VERSION}"
ANDROID_SDK_ROOT="/opt/android-sdk"
ANDROID_SDK_TOOLS="$ANDROID_SDK_ROOT/cmdline-tools/bin"

# Step 1: Update the system
echo "Updating system packages..."
sudo dnf update -y

# Step 2: Install KVM and virtualization tools if not already installed
echo "Installing KVM and virtualization tools..."
sudo dnf install -y qemu-kvm libvirt virt-install bridge-utils virt-manager

# Step 3: Start and enable libvirtd service
echo "Enabling libvirtd service..."
sudo systemctl enable libvirtd
sudo systemctl start libvirtd

# Step 4: Verify KVM installation
echo "Verifying KVM installation..."
if ! lsmod | grep -i kvm; then
    echo "KVM is not installed or not supported on this machine."
    exit 1
fi

# Step 5: Install Java (required for Android SDK)
echo "Installing Java (JDK)..."
sudo dnf install -y java-1.8.0-openjdk-devel

# Step 6: Install Android SDK tools if not already installed
echo "Installing Android SDK tools..."
sudo dnf install -y wget unzip

# Download Android SDK command-line tools if not already present
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

# Step 7: Update Android SDK components
echo "Updating Android SDK components..."
yes | sdkmanager --licenses
sdkmanager "platform-tools" "emulator"

# Install the system image for the new Android version
echo "Installing system image for Android version $NEW_ANDROID_VERSION..."
sdkmanager "system-images;$NEW_ANDROID_VERSION;google_apis;x86_64"

# Step 8: Delete old AVD if it exists
if avdmanager list avd | grep -q "$NEW_AVD_NAME"; then
    echo "Deleting old AVD named $NEW_AVD_NAME..."
    avdmanager delete avd -n "$NEW_AVD_NAME"
fi

# Step 9: Create a new AVD with the desired Android version
echo "Creating a new AVD named $NEW_AVD_NAME..."
echo no | avdmanager create avd -n "$NEW_AVD_NAME" -k "system-images;$NEW_ANDROID_VERSION;google_apis;x86_64" --device "pixel_3"

# Step 10: Configure KVM for Android Emulator
echo "Configuring KVM for Android Emulator..."
sudo setfacl -m u:$USER:rwx /dev/kvm

# Step 11: Increase swap memory to improve performance if not already configured
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

# Step 12: Start the new Android emulator with maximum resources
echo "Starting the new Android emulator with maximum resources..."
nohup emulator -avd "$NEW_AVD_NAME" -no-boot-anim -gpu on -no-window -memory 4096 -cores 2 &

# Step 13: Enable ADB over the network
echo "Enabling ADB over network..."
adb -s emulator-5554 tcpip 5555
adb connect localhost:5555

# Step 14: Install VNC server for remote access if not already installed
if ! rpm -q tigervnc-server; then
    echo "Installing VNC server..."
    sudo dnf install -y tigervnc-server
fi

# Step 15: Set up and start VNC server
echo "Setting up VNC server..."
mkdir -p ~/.vnc
echo "#!/bin/bash" > ~/.vnc/xstartup
echo "xsetroot -solid grey" >> ~/.vnc/xstartup
echo "startxfce4 &" >> ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup

echo "Starting VNC server..."
vncserver :1 -geometry 1280x720 -depth 16

# Step 16: Open necessary ports in the firewall
echo "Opening ports for ADB and VNC..."
sudo firewall-cmd --zone=public --add-port=5555/tcp --permanent  # ADB
sudo firewall-cmd --zone=public --add-port=5901/tcp --permanent  # VNC
sudo firewall-cmd --reload

# Step 17: Verify ADB and emulator setup
echo "Verifying ADB and emulator..."
adb devices

echo "Android virtual device setup with Android version $NEW_ANDROID_VERSION is complete!"
echo "Use VNC to connect to :1 for graphical access and ADB to connect to port 5555 for command-line access."
