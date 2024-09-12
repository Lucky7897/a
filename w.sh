#!/bin/bash

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Create the user 'k' with password 'lollol' and give root privileges
sudo useradd -m -s /bin/bash k
echo 'k:lollol' | sudo chpasswd
sudo usermod -aG sudo k

# Install Xfce Desktop Environment
sudo apt install xfce4 xfce4-goodies -y

# Install LightDM display manager
sudo apt install lightdm -y
sudo systemctl enable lightdm

# Install SSH server for remote access
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# Configure SSH for password authentication and root login
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Install and configure XRDP for remote desktop access
sudo apt install xrdp -y
sudo systemctl enable xrdp
sudo systemctl start xrdp
echo xfce4-session > ~/.xsession

# Firewall Configuration
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 3389/tcp # XRDP
sudo ufw reload

# Optimize system performance
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo systemctl disable bluetooth.service
sudo systemctl disable cups.service
sudo apt install preload -y

# Install Waydroid (for running virtual Androids)
sudo apt install curl lxd -y
sudo systemctl start lxd
sudo lxd init --auto

# Waydroid installation
curl https://raw.githubusercontent.com/waydroid/waydroid/main/scripts/waydroid-init.sh | sudo bash

# Enable root access for Waydroid
sudo waydroid prop set persist.waydroid.root 1
sudo systemctl restart waydroid-container

# Install and configure VNC server to control Android session
sudo apt install tightvncserver -y
sudo apt install xfce4 xfce4-goodies -y

# Set up VNC for Android session
echo "export DISPLAY=:1" >> /home/k/.bashrc
sudo -u k vncserver :1 -geometry 1280x720 -depth 24

# Set up VNC password for 'k' user
sudo -u k vncpasswd

# Install necessary tools for VNC to control Waydroid session
sudo apt install x11vnc -y

# Create Waydroid desktop shortcut
DESKTOP_FILE="/home/k/Desktop/Waydroid.desktop"
echo "[Desktop Entry]
Version=1.0
Name=Waydroid
Comment=Run Android with Waydroid
Exec=waydroid show-full-ui
Icon=waydroid
Terminal=false
Type=Application
Categories=Utility;Application;" | sudo tee $DESKTOP_FILE

# Make the shortcut executable
sudo chmod +x $DESKTOP_FILE
sudo chown k:k $DESKTOP_FILE

# Ensure VNC server starts on boot
sudo crontab -l | { cat; echo "@reboot sudo -u k vncserver :1 -geometry 1280x720 -depth 24"; } | sudo crontab -

# Reboot to apply changes
sudo reboot
