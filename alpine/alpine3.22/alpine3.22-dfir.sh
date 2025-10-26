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
    print_red "Please run as root 'sudo bash debian13-server.sh'"
    exit 1
fi

# Confirm before proceeding
custom_prompt "This script will install packages and modify your system. Continue?"
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Save both stdout and stderr to a single file through tee
logfile="trixie_server_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee "$logfile") 2>&1

# Exit on error
set -e


# ---------------------------------------------------------- #
# -------------- Install Desktop Environment --------------- #
# ---------------------------------------------------------- #

# Ask the user for username
read -p "Enter your username: " USERNAME

# Check if the user exists
if ! id -u "$USERNAME" > /dev/null 2>&1; then
    print_red "User $USERNAME does not exist. Please enter a valid username."
    exit 1
fi

chown -R "$USERNAME:users" $logfile

# Ask the user if they want to install a desktop environment
custom_prompt "Do you want to install a desktop environment of your choice?"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Start installing the desktop environment
    print_status "start" "Installing desktop environment"
    if setup-desktop; then
        print_status "ok" "Desktop installed successfully"
    else
        print_status "failed" "Failed to install desktop environment"
        exit 1
    fi
fi


# ---------------------------------------------------------- #
# --------------- System Update And Upgrade ---------------- #
# ---------------------------------------------------------- #

# System updates
print_status "start" "Updating system packages"
if apk update && apk upgrade --available; then
    print_status "ok" "System updated and upgraded"
else
    print_status "failed" "Failed to update system"
    exit 1
fi


# ---------------------------------------------------------- #
# --------------- Install Essential Packages --------------- #
# ---------------------------------------------------------- #

# General CLI tools
print_status "start" "Installing general CLI tools"
if apk add wget gpg curl 7zip zip unzip net-tools htop mlocate lf zsh; then
    print_status "ok" "General CLI tools installed"
else
    print_status "failed" "Failed to install general CLI tools"
    exit 1
fi

# Code Editors
print_status "start" "Installing code editors"
if apk add nano vim neovim; then
    print_status "ok" "Code editors installed"
else
    print_status "failed" "Failed to install code editors"
    exit 1
fi


# ---------------------------------------------------------- #
# -------------------------- Done -------------------------- #
# ---------------------------------------------------------- #

echo "****************************************************"
echo "             Alpine 3.22 Setup Complete!            "
echo "****************************************************"