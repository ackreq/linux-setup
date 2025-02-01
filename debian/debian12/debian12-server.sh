#!/bin/bash

# Function to print in red
print_red() {
    echo -e "\e[31m$1\e[0m"
}

# Check if we are running as root
if [ "$(id -u)" -ne 0 ]; then
    print_red "Please run as root 'sudo bash bookworm-server.sh'"
    exit 1
fi

# Confirm before proceeding
read -p "This script will install packages and modify your system. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Save both stdout and stderr to a single file through tee
logfile="bookworm_server_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee "$logfile") 2>&1

# Exit on error
set -e

# ---------------------------------------------------------- #
# ----------- Setup Directories And Permissions ------------ #
# ---------------------------------------------------------- #

# Ask the user for username
read -p "Enter your username: " USERNAME

# Check if the user exists
if ! id -u "$USERNAME" > /dev/null 2>&1; then
    print_red "User $USERNAME does not exist. Please enter a valid username."
    exit 1
fi

# Ask the user if they want to setup directories
read -p "Do you want to setup directories in /opt? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create directories in /opt
    echo "Creating directories in /opt"
    mkdir -p /opt/{softwares,sources}

    # Change ownership of directories
    echo "Changing ownership of /opt/softwares and /opt/sources to $USERNAME"
    chown -R "$USERNAME:users" /opt/{softwares,sources}
fi

# ---------------------------------------------------------- #
# --------------- System Update And Upgrade ---------------- #
# ---------------------------------------------------------- #

# System updates
echo "Updating system packages"
apt -y update
apt -y full-upgrade

# ---------------------------------------------------------- #
# --------- Install Debian apt Available Software ---------- #
# ---------------------------------------------------------- #

# Check dbus status
echo "Checking if dbus is enabled"
if ! systemctl is-active --quiet dbus; then
    echo "Installing dbus"
    apt install -y dbus
    echo "Starting and enabling dbus"
    systemctl enable --now dbus
fi

# Install software-properties-common (for apt-add-repository)
echo "Installing software-properties-common"
apt install -y software-properties-common

# Add contrib non-free (rar, etc)
echo "Adding repository components contrib non-free non-free-firmware"
yes | apt-add-repository --component contrib non-free non-free-firmware

# General CLI tools
echo "Installing general CLI tools"
apt install -y wget gpg curl speedtest-cli rar unrar zip unzip jq tree net-tools bc
apt install -y htop btop duf tldr tmux exa bat ncdu lf neofetch bash-completion zsh

# Essential coding and packaging tools
echo "Installing essential coding and packaging tools"
apt install -y gcc g++ build-essential make ninja-build llvm cmake git dialog

# Scripting tools
echo "Installing scripting tools and development files"
apt install -y python3 perl libperl-dev libncurses-dev libssl-dev libcurl4-openssl-dev

# Code Editors, IDE's and GUI designers
echo "Installing code editors"
apt install -y nano vi vim neovim

# General software and tools
echo "Installing general software and tools"
apt install -y mediainfo locate

# Quick Emulator & Virtual Machine Manager
#echo "Installing kvm/qemu components"
#apt install -y qemu-system libvirt-clients libvirt-daemon-system

# ---------------------------------------------------------- #
# --------------------- Setup Dotfiles --------------------- #
# ---------------------------------------------------------- #

echo "Setting up dotfiles"

# Clone dotfiles repository
echo "Cloning dotfiles repository"
if ! git clone https://github.com/slash071/dotfiles; then
    print_red "Failed to clone dotfiles repository. Please check the URL and try again."
    exit 1
fi

# Copy .vimrc to home directory
echo "Copying .vimrc to home directory"
cp dotfiles/.vimrc ~/

# Copy lf configuration files
echo "Copying lf configuration files"
mkdir -p ~/.config/lf
cp dotfiles/config/lf/{colors,lfrc,scope} ~/.config/lf

# Copy zsh configuration files
echo "Copying zsh configuration files"
mkdir -p ~/.config/zsh
cp -r dotfiles/config/zsh ~/.config

echo "Setting ZDOTDIR for zsh"
echo "export ZDOTDIR=$HOME/.config/zsh" | sudo tee -a /etc/zsh/zshenv

# Clean up dotfiles repository
echo "Cleaning up dotfiles repository"
rm -rf dotfiles

# ---------------------------------------------------------- #
# ------------------ Change Default Shell ------------------ #
# ---------------------------------------------------------- #

# Ask the user if they want to change the default shell to Zsh
read -p "Do you want to change the default shell to Zsh? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Change the default shell to Zsh
    if chsh -s $(which zsh) "$USERNAME"; then
        echo "Default shell changed to Zsh for user $USERNAME"
    else
        print_red "Failed to change the default shell for user $USERNAME"
        exit 1
    fi
fi

# ---------------------------------------------------------- #
# ------------------- PAM Configuration -------------------- #
# ---------------------------------------------------------- #

# Ask the user if they want to disable MOTD
read -p "Do you want to disable the Message of the Day (MOTD)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup the original file
    echo "Backing up PAM configuration files (sshd and login)"
    for file in sshd login; do
        if ! cp /etc/pam.d/$file /etc/pam.d/$file.bak; then
            print_red "Failed to backup /etc/pam.d/$file. Aborting."
            exit 1
        fi
    done

    # Comment out the lines in /etc/pam.d/sshd
    echo "Disabling MOTD in SSH by commenting out pam_motd.so lines"
    if ! sed -i '/pam_motd.so/s/^/# /' /etc/pam.d/sshd; then
        print_red "Failed to modify /etc/pam.d/sshd. Aborting."
        exit 1
    fi

    # Comment out the lines in /etc/pam.d/login
    echo "Disabling MOTD in login by commenting out pam_motd.so lines"
    if ! sed -i '/pam_motd.so/s/^/# /' /etc/pam.d/login; then
        print_red "Failed to modify /etc/pam.d/login. Aborting."
        exit 1
    fi
fi

# ---------------------------------------------------------- #
# ---------------------- Enable SSH ------------------------ #
# ---------------------------------------------------------- #

# Ask the user if they want to enable SSH
read -p "Do you want to enable SSH? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Install SSH if not already installed
    echo "Installing SSH package"
    apt install -y openssh-server

    # Check if SSH service is running
    if systemctl is-active --quiet ssh; then
        echo "SSH is already running."
    else
        echo "Starting and enabling SSH service"
        systemctl enable --now ssh
    fi
fi

# ---------------------------------------------------------- #
# -------------------------- Done -------------------------- #
# ---------------------------------------------------------- #

echo "****************************************************"
echo " Debian 12 (Bookworm) Package Installation Complete "
echo "****************************************************"