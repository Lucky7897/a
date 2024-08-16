#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Step 1: Adjust SSH to use username/password instead of key
echo "Configuring SSH to use username/password authentication only..."
sudo sed -i 's/#\?\(PasswordAuthentication\s*\).*/\1yes/' /etc/ssh/sshd_config
sudo sed -i 's/#\?\(PubkeyAuthentication\s*\).*/\1no/' /etc/ssh/sshd_config
sudo sed -i 's/#\?\(ChallengeResponseAuthentication\s*\).*/\1no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Step 2: Install and configure VNC
echo "Installing and configuring VNC server..."
sudo apt-get update
sudo apt-get install -y tigervnc-standalone-server xfce4 xfce4-goodies
vncpasswd
echo "startxfce4 &" > ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup
vncserver :1

# Step 3: Install top 10 tools for Ubuntu
echo "Installing top 10 tools for Ubuntu..."
sudo apt-get install -y htop curl git vim net-tools ufw wget tmux tree build-essential

# Step 4: Install the most lightweight GUI
echo "Installing the lightweight XFCE GUI..."
sudo apt-get install -y xfce4 xfce4-goodies

# Step 5: Optimize Ubuntu Server for performance
echo "Optimizing system performance..."

# Disable unnecessary services
echo "Disabling unnecessary services..."
sudo systemctl disable bluetooth.service
sudo systemctl disable cups.service
sudo systemctl disable ModemManager.service

# Tune the filesystem for performance
echo "Tuning filesystem..."
sudo tune2fs -o journal_data_writeback /dev/sda1
sudo mount -o remount,noatime,nodiratime / # For ext4

# Adjust swappiness (use less swap)
echo "Adjusting swappiness..."
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Enable UFW firewall with basic rules
echo "Setting up UFW firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 5901/tcp  # Allow VNC
sudo ufw --force enable

# Clean up
echo "Cleaning up unnecessary files..."
sudo apt-get autoremove -y
sudo apt-get clean

# Display final message
echo "Setup complete! SSH is now using password authentication. VNC server is running on :1 (port 5901). Lightweight XFCE GUI is installed and system is optimized for performance."
