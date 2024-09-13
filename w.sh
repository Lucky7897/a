
#!/bin/bash

# Step 1: Update the system
echo "Updating system packages..."
sudo dnf update -y

# Step 2: Install KVM and virtualization tools
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

# Step 6: Install Android SDK tools
echo "Installing Android SDK tools..."
sudo dnf install -y wget unzip

# Download Android SDK command-line tools
ANDROID_SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
wget $ANDROID_SDK_URL -O android_sdk.zip

# Create SDK directory and unzip tools
sudo mkdir -p /opt/android-sdk
sudo unzip android_sdk.zip -d /opt/android-sdk

# Set up environment variables
echo "Setting up environment variables..."
echo 'export ANDROID_SDK_ROOT=/opt/android-sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/bin:$ANDROID_SDK_ROOT/platform-tools' >> ~/.bashrc
source ~/.bashrc

# Step 7: Install Android SDK components for Android 11
echo "Installing Android SDK components for Android 11..."
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-30" "emulator" "system-images;android-30;google_apis;x86_64"

# Step 8: Create an Android Virtual Device (AVD) for Android 11
echo "Creating an Android Virtual Device (AVD)..."
echo no | avdmanager create avd -n cloud_android -k "system-images;android-30;google_apis;x86_64" --device "pixel_3"

# Step 9: Configure KVM for Android Emulator
echo "Configuring KVM for Android Emulator..."
sudo setfacl -m u:$USER:rwx /dev/kvm

# Step 10: Install ADB (Android Debug Bridge)
echo "Installing ADB..."
sudo dnf install -y android-tools

# Step 11: Increase swap memory to improve performance
echo "Configuring swap memory..."
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Step 12: Optimize swappiness to 10 (use swap only when necessary)
echo "Optimizing swappiness..."
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Step 13: Start the Android emulator with maximum resources
echo "Starting the Android emulator with maximum resources..."
nohup emulator -avd cloud_android -no-boot-anim -no-snapshot -no-window -gpu on -memory 4096 -cores 1 -port 5554 &

# Step 14: Enable ADB over the network
echo "Enabling ADB over network..."
adb -s emulator-5554 tcpip 5555
adb connect localhost:5555

# Step 15: Install VNC server for remote access
echo "Installing VNC server..."
sudo dnf install -y tigervnc-server

# Step 16: Set up VNC server
mkdir -p ~/.vnc
echo "#!/bin/bash" > ~/.vnc/xstartup
echo "xsetroot -solid grey" >> ~/.vnc/xstartup
echo "emulator -avd cloud_android -no-boot-anim -no-snapshot -gpu on" >> ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup

# Step 17: Start VNC server
vncserver :1 -geometry 1280x720 -depth 16

# Step 18: Open necessary ports in the firewall
echo "Opening ports for ADB and VNC..."
sudo firewall-cmd --zone=public --add-port=5555/tcp --permanent  # ADB
sudo firewall-cmd --zone=public --add-port=5901/tcp --permanent  # VNC
sudo firewall-cmd --reload

# Step 19: Verify ADB and emulator setup
echo "Verifying ADB and emulator..."
adb devices

echo "Android virtual cloud environment setup is complete!"
echo "Use VNC to connect to :1 for graphical access and ADB to connect to port 5555 for command-line access."
