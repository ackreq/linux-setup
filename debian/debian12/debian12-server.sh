#!/bin/bash

# Function to print in red
print_red() {
    echo -e "\e[31m$1\e[0m"
}

# Function to print status messages with colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "start")
            # Bold white brackets, yellow * symbol
            echo -e "\e[1;37m[ \e[33m** \e[1;37m]\e[0m ${message}..."
            ;;
        "ok")
            # Bold white brackets, green "OK"
            echo -e "\e[1;37m[ \e[32mOK \e[1;37m]\e[0m ${message}"
            ;;
        "failed")
            # Bold white brackets, red "FAILED"
            echo -e "\e[1;37m[ \e[31mFAILED \e[1;37m]\e[0m ${message}"
            ;;
    esac
    # Add delay
    if [[ "$status" == "start" || "$status" == "ok" ]]; then
        sleep 1
    fi
}

# Custom prompt function
custom_prompt() {
    local prompt_message=$1
    echo -ne "\e[33m>>> ${prompt_message} (y/n) \e[0m"
    read -r
}

# Check if we are running as root
if [ "$(id -u)" -ne 0 ]; then
    print_red "Please run as root 'sudo bash debian12-server.sh'"
    exit 1
fi

# Confirm before proceeding
custom_prompt "This script will install packages and modify your system. Continue?"
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

chown -R "$USERNAME:users" $logfile

# Ask the user if they want to setup directories
custom_prompt "Do you want to setup directories in /opt?"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create directories in /opt
    print_status "start" "Creating directories in /opt"
    if mkdir -p /opt/{softwares,sources}; then
        print_status "ok" "Directories created in /opt"
    else
        print_status "failed" "Failed to create directories in /opt"
        exit 1
    fi

    # Change ownership of directories
    print_status "start" "Changing ownership of /opt/softwares and /opt/sources to $USERNAME"
    if chown -R "$USERNAME:users" /opt/{softwares,sources}; then
        print_status "ok" "Ownership changed to $USERNAME"
    else
        print_status "failed" "Failed to change ownership"
        exit 1
    fi
fi

# ---------------------------------------------------------- #
# --------------- System Update And Upgrade ---------------- #
# ---------------------------------------------------------- #

# System updates
print_status "start" "Updating system packages"
if apt -y update && apt -y full-upgrade; then
    print_status "ok" "System updated and upgraded"
else
    print_status "failed" "Failed to update system"
    exit 1
fi

# ---------------------------------------------------------- #
# ------------------- Check dbus Status -------------------- #
# ---------------------------------------------------------- #

# Check dbus status
print_status "start" "Checking if dbus is enabled"
if ! systemctl is-active --quiet dbus; then
    print_status "start" "Installing dbus"
    if apt install -y dbus; then
        print_status "ok" "dbus installed"
    else
        print_status "failed" "Failed to install dbus"
        exit 1
    fi

    print_status "start" "Starting and enabling dbus"
    if systemctl enable --now dbus; then
        print_status "ok" "dbus started and enabled"
    else
        print_status "failed" "Failed to start and enable dbus"
        exit 1
    fi
else
    print_status "ok" "dbus is already enabled"
fi

# ---------------------------------------------------------- #
# --------- Install Debian apt Available Software ---------- #
# ---------------------------------------------------------- #

# Install software-properties-common
print_status "start" "Installing software-properties-common"
if apt install -y software-properties-common; then
    print_status "ok" "software-properties-common installed"
else
    print_status "failed" "Failed to install software-properties-common"
    exit 1
fi

# Add contrib non-free
print_status "start" "Adding repository components contrib non-free non-free-firmware"
if yes | apt-add-repository --component contrib non-free non-free-firmware; then
    print_status "ok" "Repository components added"
else
    print_status "failed" "Failed to add repository components"
    exit 1
fi

# General CLI tools
print_status "start" "Installing general CLI tools"
if apt install -y wget gpg curl rar unrar zip unzip jq tree net-tools bc htop btop duf tldr tmux exa bat ncdu locate lf neofetch bash-completion zsh; then
    print_status "ok" "General CLI tools installed"
else
    print_status "failed" "Failed to install general CLI tools"
    exit 1
fi

# Essential coding and packaging tools
print_status "start" "Installing essential coding and packaging tools"
if apt install -y gcc g++ build-essential make ninja-build cmake git dialog; then
    print_status "ok" "Essential coding and packaging tools installed"
else
    print_status "failed" "Failed to install essential coding and packaging tools"
    exit 1
fi

# Scripting tools
print_status "start" "Installing scripting tools and development files"
if apt install -y python3 perl libperl-dev libncurses-dev; then
    print_status "ok" "Scripting tools installed"
else
    print_status "failed" "Failed to install scripting tools"
    exit 1
fi

# Code Editors
print_status "start" "Installing code editors"
if apt install -y nano vim neovim; then
    print_status "ok" "Code editors installed"
else
    print_status "failed" "Failed to install code editors"
    exit 1
fi

# ---------------------------------------------------------- #
# --------------------- Setup Dotfiles --------------------- #
# ---------------------------------------------------------- #

print_status "start" "Setting up dotfiles"

# Clone dotfiles repository
if git clone https://github.com/ackreq/dotfiles; then
    print_status "ok" "Dotfiles repository cloned"
else
    print_status "failed" "Failed to clone dotfiles repository"
    exit 1
fi

# Change dotfiles ownership
if chown -R "$USERNAME:users" dotfiles; then
    print_status "ok" "Ownership of dotfiles changed to $USERNAME"
else
    print_status "failed" "Failed to change ownership"
    exit 1
fi

# Copy .vimrc to home directory
if mv dotfiles/.vimrc /home/$USERNAME/; then
    print_status "ok" ".vimrc copied"
else
    print_status "failed" "Failed to copy .vimrc"
    exit 1
fi

# Copy lf configuration files
if mkdir -p /home/$USERNAME/.config/lf && mv dotfiles/config/lf/{colors,lfrc,scope} /home/$USERNAME/.config/lf; then
    print_status "ok" "lf configuration files copied"
else
    print_status "failed" "Failed to copy lf configuration files"
    exit 1
fi

# Copy zsh configuration files
if mkdir -p /home/$USERNAME/.config/zsh && mv dotfiles/config/zsh /home/$USERNAME/.config; then
    print_status "ok" "zsh configuration files copied"
else
    print_status "failed" "Failed to copy zsh configuration files"
    exit 1
fi

# Set ZDOTDIR for zsh
if echo "\nexport ZDOTDIR=/home/$USERNAME/.config/zsh" | sudo tee -a /etc/zsh/zshenv; then
    print_status "ok" "ZDOTDIR set for zsh"
else
    print_status "failed" "Failed to set ZDOTDIR for zsh"
    exit 1
fi

# Clean up dotfiles repository
if rm -rf dotfiles; then
    print_status "ok" "Dotfiles repository cleaned up"
else
    print_status "failed" "Failed to clean up dotfiles repository"
    exit 1
fi

# ---------------------------------------------------------- #
# ------------------ Change Default Shell ------------------ #
# ---------------------------------------------------------- #

# Ask the user if they want to change the default shell to Zsh
custom_prompt "Do you want to change the default shell to Zsh?"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "start" "Changing default shell to Zsh for user $USERNAME"
    if chsh -s $(which zsh) "$USERNAME"; then
        print_status "ok" "Default shell changed to Zsh for user $USERNAME"
    else
        print_status "failed" "Failed to change the default shell for user $USERNAME"
        exit 1
    fi
fi

# ---------------------------------------------------------- #
# ---------------------- Enable SSH ------------------------ #
# ---------------------------------------------------------- #

# Ask the user if they want to enable SSH
custom_prompt "Do you want to enable SSH?"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if openssh-server is installed
    if ! dpkg -s openssh-server > /dev/null 2>&1; then
        print_status "start" "Installing openssh-server"
        if apt install -y openssh-server; then
            print_status "ok" "openssh-server installed"
        else
            print_status "failed" "Failed to install openssh-server"
            exit 1
        fi
    else
        print_status "ok" "openssh-server is already installed"
    fi

    # Check if SSH service is enabled
    if ! systemctl is-enabled ssh > /dev/null 2>&1; then
        print_status "start" "Enabling and starting SSH service"
        if systemctl enable --now ssh; then
            print_status "ok" "SSH service enabled and started"
        else
            print_status "failed" "Failed to enable and start SSH service"
            exit 1
        fi
    else
        print_status "ok" "SSH service is already enabled"
    fi
fi

# ---------------------------------------------------------- #
# ------------------- PAM Configuration -------------------- #
# ---------------------------------------------------------- #

# Ask the user if they want to disable MOTD
custom_prompt "Do you want to disable the Message of the Day (MOTD)?"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "start" "Start disabling MOTD message"
    # Backup the original file
    for file in sshd login; do
        if ! cp /etc/pam.d/$file /etc/pam.d/$file.bak; then
            print_status "failed" "Failed to backup /etc/pam.d/$file"
            exit 1
        fi
    done
    print_status "ok" "PAM configuration files backed up"

    # Comment out the lines in /etc/pam.d/login
    if sed -i '/pam_motd.so/s/^/# /' /etc/pam.d/login; then
        print_status "ok" "MOTD disabled in login"
    else
        print_status "failed" "Failed to disable MOTD in login"
        exit 1
    fi
fi

    # Comment out the lines in /etc/pam.d/sshd
    if sed -i '/pam_motd.so/s/^/# /' /etc/pam.d/sshd; then
        print_status "ok" "MOTD disabled in SSH"
    else
        print_status "failed" "Failed to disable MOTD in SSH"
        exit 1
    fi

# ---------------------------------------------------------- #
# -------------------------- Done -------------------------- #
# ---------------------------------------------------------- #

echo "****************************************************"
echo " Debian 12 (Bookworm) Package Installation Complete "
echo "****************************************************"