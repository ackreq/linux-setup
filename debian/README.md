# Debian Setup Scripts

These scripts automate the setup of a **Debian system**, including:

- Installing essential software packages
- Setting up development tools
- Configuring the system for general-purpose use

They are designed to quickly spin up a Debian system for development, server tasks, or other general workflows.

## Prerequisites

- A fresh installation of Debian
- A user account with root privileges

> [!Important]
> If you assigned a password to the root account during Debian installation, your regular user might not have root privileges. To grant `sudo` access to your regular user, perform the following steps **as the root user**:
>
> 1. Install `sudo` (if not already installed):
>
>    ```sh
>    apt update
>    apt install sudo
>    ```
>
> 2. Add your user to the `sudo` group:
>
>    ```sh
>    usermod -aG sudo <username>
>    ```
>
>    Replace `<username>` with your actual username.
>
> 3. Log out and log back in for the changes to take effect.

## Usage

Follow these steps to spin up your Debian system:

1. **Install Required Packages**

   Install essential tools needed for the setup scripts:

   ```sh
   sudo apt update && sudo apt install -y wget zip git
   ```

2. **Clone the Repository**

   Clone this repository to your local system:

   ```shell
   git clone https://github.com/ackreq/linux-setup.git
   ```

3. **Navigate to the Repository Directory**

   Move into the folder corresponding to your Debian version:

   ```shell
   cd linux-setup/debian/debian<VERSION>
   ```

4. **Run the Setup Script**

   Execute the desired setup script:

   ```shell
   sudo bash <SCRIPT>.sh
   ```

   Follow the prompts and provide any required input during execution.
