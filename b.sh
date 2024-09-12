#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Step 1: Adjust SSH to use username/password instead of key
echo "Configuring SSH to use username/password authentication..."
sudo sed -i 's/#\?\(PasswordAuthentication\s*\).*/\1 yes/' /etc/ssh/sshd_config
sudo sed -i 's/#\?\(PubkeyAuthentication\s*\).*/\1 no/' /etc/ssh/sshd_config
sudo sed -i 's/#\?\(ChallengeResponseAuthentication\s*\).*/\1 no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Step 2: Install and configure VNC
echo "Installing and configuring VNC server..."
sudo apt-get update
sudo apt-get install -y tigervnc-standalone-server xfce4 xfce4-goodies
mkdir -p ~/.vnc
vncpasswd
echo "startxfce4 &" > ~/.vnc/xstartup
chmod +x ~/.vnc/xstartup
vncserver :1

# Step 3: Install and configure XRDP for RDP support
echo "Installing XRDP for Remote Desktop support..."
sudo apt-get install -y xrdp
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Ensure XRDP uses the XFCE desktop environment
echo "Configuring XRDP to use XFCE..."
echo xfce4-session >~/.xsession
sudo sed -i 's/port=-1/port=3389/' /etc/xrdp/xrdp.ini  # Set default RDP port to 3389
sudo systemctl restart xrdp

# Step 4: Install top 10 tools for Ubuntu including OpenSSL
echo "Installing top tools for Ubuntu including OpenSSL..."
sudo apt-get install -y htop curl git vim net-tools ufw wget tmux tree build-essential openssl

# Step 5: Install the lightweight XFCE GUI
echo "Installing the lightweight XFCE GUI..."
sudo apt-get install -y xfce4 xfce4-goodies

# Step 6: Optimize Ubuntu Server for performance

# Optimize CPU usage
echo "Optimizing CPU settings for multi-core usage..."
sudo apt-get install -y cpufrequtils
sudo cpufreq-set -r -g performance  # Set CPU governor to 'performance'

# Disable unnecessary services
echo "Disabling unnecessary services..."
sudo systemctl disable bluetooth.service
sudo systemctl disable cups.service
sudo systemctl disable ModemManager.service

# Tune the filesystem for performance
echo "Tuning filesystem for better I/O performance..."
sudo tune2fs -o journal_data_writeback /dev/sda1 || echo "Failed to tune filesystem"
sudo mount -o remount,noatime,nodiratime / || echo "Failed to remount filesystem"

# Adjust swappiness to optimize RAM usage (set to 10, using more RAM and less swap)
echo "Adjusting swappiness for optimal RAM usage..."
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Optimize disk I/O with noatime
echo "Applying 'noatime' mount option to reduce I/O overhead..."
sudo sed -i 's/ defaults/ defaults,noatime/' /etc/fstab

# Increase file descriptor limits to optimize for high concurrency
echo "Increasing file descriptor limits..."
echo "fs.file-max = 100000" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
echo "* soft nofile 100000" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 100000" | sudo tee -a /etc/security/limits.conf

# Enable UFW firewall with basic rules
echo "Setting up UFW firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 5901/tcp  # Allow VNC
sudo ufw allow 3389/tcp  # Allow RDP
sudo ufw --force enable

# Clean up
echo "Cleaning up unnecessary files..."
sudo apt-get autoremove -y
sudo apt-get clean

# Display final message
echo "Setup complete! SSH is using password authentication. VNC server is running on :1 (port 5901), XRDP is running on port 3389. Lightweight XFCE GUI is installed, OpenSSL is ready, and the system is optimized for performance."