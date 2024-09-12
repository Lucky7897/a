
#!/bin/bash

# Update and install dependencies
sudo apt update
sudo apt install -y openjdk-11-jdk wget unzip qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

# Set up the Android SDK
ANDROID_SDK_ROOT=$HOME/Android/Sdk
mkdir -p $ANDROID_SDK_ROOT
cd $HOME
wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip -O android_cmdline_tools.zip
unzip android_cmdline_tools.zip -d $ANDROID_SDK_ROOT
rm android_cmdline_tools.zip

# Set environment variables
echo "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >> ~/.bashrc
echo "export PATH=\$PATH:\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" >> ~/.bashrc
source ~/.bashrc

# Install Android SDK components
sdkmanager --sdk_root=$ANDROID_SDK_ROOT --install "platform-tools" "platforms;android-30" "emulator" "system-images;android-30;default;x86_64"

# Create a virtual device
AVD_NAME="AndroidVM"
echo "no" | avdmanager create avd -n $AVD_NAME -k "system-images;android-30;default;x86_64" --force

# Install a VNC server
sudo apt install -y xfce4 xfce4-terminal tightvncserver

# Create a startup script for the VNC server
echo "#!/bin/bash
export DISPLAY=:1
$ANDROID_SDK_ROOT/emulator/emulator -avd $AVD_NAME -no-audio -no-window -gpu swiftshader_indirect -m 2048 &" > $HOME/vnc_start.sh

chmod +x $HOME/vnc_start.sh

# Configure VNC Server
vncserver :1 -geometry 1280x720 -depth 24
echo "xfce4-session &" >> ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup

# Start VNC server and Android VM
$HOME/vnc_start.sh &
echo "Android VM and VNC server setup complete. You can connect using a VNC client to <your_server_ip>:1"
