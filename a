#!/bin/bash

# Script to install GUI and configure a Linux server

# Ensure the script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Prompt for username and password
echo "1. Please enter your username:"
read username
echo "2. Please enter your password:"
read -s password

# List of top 15 Linux distributions
declare -a distros=("Ubuntu" "Debian" "Fedora" "CentOS" "Arch Linux" "OpenSUSE" "Kali Linux" "Linux Mint" "Manjaro" "Pop!_OS" "Elementary OS" "Zorin OS" "MX Linux" "Solus" "PCLinuxOS")

# Function to install GUI based on distribution
install_gui() {
    case $1 in
        "Ubuntu"|"Debian")
            apt-get update
            apt-get install -y ubuntu-desktop
            ;;
        "Fedora")
            dnf install -y @cinnamon-desktop-environment
            ;;
        "CentOS")
            yum groupinstall -y "GNOME Desktop"
            ;;
        "Arch Linux")
            pacman -Syu --noconfirm gnome
            ;;
        "OpenSUSE")
            zypper install -t pattern gnome
            ;;
        # Add other distros here...
        *)
            echo "Distribution not supported yet."
            ;;
    esac
}

# Function to install Docker and configure Selenium with proxy rotation
setup_docker_selenium_proxy() {
    echo "8. Do you want to run Selenium with proxy rotation using Docker? (yes/no)"
    read docker_selenium_proxy

    case $docker_selenium_proxy in
        "yes")
            # Install Docker if not already installed
            echo "Installing Docker..."
            case $distro in
                "Ubuntu"|"Debian")
                    apt-get update
                    apt-get install -y docker.io
                    ;;
                "Fedora")
                    dnf install -y docker
                    systemctl start docker
                    systemctl enable docker
                    ;;
                "CentOS")
                    yum install -y docker-ce
                    systemctl start docker
                    systemctl enable docker
                    ;;
                "Arch Linux")
                    pacman -Syu --noconfirm docker
                    systemctl start docker
                    systemctl enable docker
                    ;;
                "OpenSUSE")
                    zypper install -y docker
                    systemctl start docker
                    systemctl enable docker
                    ;;
                *)
                    echo "Docker installation not supported for this distribution."
                    return
                    ;;
            esac

            # Run Selenium with proxy rotation using Docker
            echo "Setting up Selenium with proxy rotation using Docker..."
            docker run -d -p 4444:4444 --name selenium-hub selenium/hub:4.0.0-beta-3-prerelease-20210310
            docker run -d --link selenium-hub:hub --name selenium-node -e HUB_HOST=hub selenium/node-chrome:4.0.0-beta-3-prerelease-20210310
            echo "Selenium with proxy rotation is now running."
            ;;
        "no")
            echo "Skipping Docker setup for Selenium with proxy rotation."
            ;;
        *)
            echo "Invalid option. Skipping Docker setup for Selenium with proxy rotation."
            ;;
    esac
}

# Prompt for Linux distribution
echo "3. Which Linux distribution do you want to install GUI on? (Choose a number)"
select distro in "${distros[@]}"; do
    echo "Installing GUI for $distro..."
    install_gui $distro
    break
done

# Prompt for SSH configuration
echo "4. Do you want to adjust SSH to use public key or username/password? (publickey/usernamepassword)"
read ssh_config

# Function to adjust SSH settings
adjust_ssh() {
    case $ssh_config in
        "publickey")
            sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
            systemctl restart sshd
            ;;
        "usernamepassword")
            sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
            systemctl restart sshd
            ;;
        *)
            echo "Invalid option. SSH settings not changed."
            ;;
    esac
}

adjust_ssh

# Prompt for RDP/VNC activation
echo "5. Do you want to activate RDP or VNC? (rdp/vnc/none)"
read remote_access

# Function to install and configure RDP/VNC
setup_remote_access() {
    case $remote_access in
        "rdp")
            case $distro in
                "Ubuntu"|"Debian"|"Fedora"|"CentOS"|"Arch Linux"|"OpenSUSE")
                    systemctl enable --now xrdp
                    ;;
                *)
                    echo "RDP not supported for this distribution."
                    ;;
            esac
            ;;
        "vnc")
            case $distro in
                "Ubuntu"|"Debian"|"Fedora"|"CentOS"|"Arch Linux"|"OpenSUSE")
                    systemctl enable --now vncserver
                    ;;
                *)
                    echo "VNC not supported for this distribution."
                    ;;
            esac
            ;;
        "none")
            echo "No remote access tools will be installed."
            ;;
        *)
            echo "Invalid option. No remote access tools will be installed."
            ;;
    esac
}

setup_remote_access

# Prompt for control panel installation
declare -a control_panels=("Webmin" "cPanel" "Plesk" "ISPConfig" "Ajenti" "VestaCP" "CentOS Web Panel" "Froxlor" "DirectAdmin" "CyberPanel" "none")

echo "6. Do you want to install a control panel? (Choose a number or type 'none')"
select control_panel in "${control_panels[@]}"; do
    case $control_panel in
        "Webmin")
            # Installation steps for Webmin
            wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -
            echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
            apt-get update
            apt-get install -y webmin
            ;;
        "cPanel")
            # Installation steps for cPanel
            cd /home
            curl -o latest -L https://securedownloads.cpanel.net/latest
            sh latest
            ;;
        "Plesk")
            # Installation steps for Plesk
            sh <(curl http://autoinstall.plesk.com/one-click-installer)
            ;;
        "ISPConfig")
            # Installation steps for ISPConfig
            wget -O - https://get.ispconfig.org | sh
            ;;
        "Ajenti")
            # Installation steps for Ajenti
            apt-get update && apt-get install -y wget apt-transport-https
            wget http://repo.ajenti.org/debian/key -O- | apt-key add -
            echo "deb http://repo.ajenti.org/ng/debian main main ubuntu" >> /etc/apt/sources.list
            apt-get update
            apt-get install -y ajenti
            ;;
        "VestaCP")
            # Installation steps for VestaCP
            curl -O http://vestacp.com/pub/vst-install.sh
            bash vst-install.sh
            ;;
        "CentOS Web Panel")
            # Installation steps for CentOS Web Panel
            cd /usr/local/src
            wget http://centos-webpanel.com/cwp-el7-latest
            sh cwp-el7-latest
            ;;
        "Froxlor")
            # Installation steps for Froxlor
            apt-get install -y froxlor
            ;;
        "DirectAdmin")
            # Installation steps for DirectAdmin
            wget -O setup.sh https://www.directadmin.com/setup.sh
            chmod 755 setup.sh
            ./setup.sh auto
            ;;
        "CyberPanel")
            # Installation steps for CyberPanel
            sh <(curl -s https://cyberpanel.net/install.sh)
            ;;
        "none")
            echo "No control panel will be installed."
            break
            ;;
        *)
            echo "Invalid option. No control panel will be installed."
            break
            ;;
    esac
done

# Prompt for popular packages/toolkits installation
declare -a packages=("Git" "Docker" "Node.js" "Python" "Java" "Ruby" "PHP" "MySQL" "PostgreSQL" "Nginx" "Apache" "MongoDB" "Redis" "Elasticsearch" "Kubernetes" "none")

echo "7. Do you want to install popular packages/toolkits? (Choose a number or type 'none')"
select package in "${packages[@]}"; do
    case $package in
        "Git")
            apt-get install -y git
            ;;
        "Docker")
            apt-get install -y docker.io
            ;;
        "Node.js")
            apt-get install -y nodejs npm
            ;;
        "Python")
            apt-get install -y python3 python3-pip
            ;;
        "Java")
            apt-get install -y default-jdk
            ;;
        "Ruby")
            apt-get install -y ruby
            ;;
        "PHP")
            apt-get install -y php libapache2-mod-php
            ;;
        "MySQL")
            apt-get install -y mysql-server
            ;;
        "PostgreSQL")
            apt-get install -y postgresql postgresql-contrib
            ;;
        "Nginx")
            apt-get install -y nginx
            ;;
        "Apache")
            apt-get install -y apache2
            ;;
        "MongoDB")
            apt-get install -y mongodb
            ;;
        "Redis")
            apt-get install -y redis-server
            ;;
        "Elasticsearch")
            apt-get install -y elasticsearch
            ;;
        "Kubernetes")
            apt-get install -y kubectl
            ;;
        "none")
            echo "No additional packages/toolkits will be installed."
            break
            ;;
        *)
            echo "Invalid option. No additional packages/toolkits will be installed."
            break
            ;;
    esac
done

# Docker container with Selenium and proxy rotation setup
setup_docker_selenium_proxy

# Perform system update and upgrade
echo "Updating and upgrading the system..."
case $distro in
    "Ubuntu"|"Debian")
        apt-get update && apt-get upgrade -y
        ;;
    "Fedora")
        dnf update -y && dnf upgrade -y
        ;;
    "CentOS")
        yum update -y && yum upgrade -y
        ;;
    "Arch Linux")
        pacman -Syu --noconfirm
        ;;
    "OpenSUSE")
        zypper update -y && zypper upgrade -y
        ;;
    *)
        echo "Update and upgrade not supported for this distribution."
        ;;
esac

# Display system statistics
echo "System statistics:"
echo "Disk usage:"
df -h
echo "Memory usage:"
free -h
echo "CPU information:"
lscpu

# Summary of actions
echo "Installation complete. Summary of actions performed:"
echo "1. Installed GUI for $distro."
echo "2. Configured SSH with $ssh_config authentication."
echo "3. Setup remote access using $remote_access."

if [ "$remote_access" == "rdp" ]; then
    echo "RDP is reachable at: your_server_ip:3389"
elif [ "$remote_access" == "vnc" ]; then
    echo "VNC is reachable at: your_server_ip:5901"
fi

if [ "$control_panel" != "none" ]; then
    echo "4. Installed control panel: $control_panel."
fi

echo "SSH is reachable at: your_server_ip:22"

# Reboot prompt
echo "9. Please reboot your system to apply all changes."
echo "Would you like to reboot now? (yes/no)"
read reboot_now
if [ "$reboot_now" == "yes" ]; then
    reboot
else
    echo "Reboot skipped. Please remember to reboot your system later to apply changes."
fi
