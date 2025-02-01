# Debian Setup Scripts

These scripts automates the setup process for a Debian system, installing various software packages and setting up development tools.

## Prerequisites

- A fresh installation of Debian.
- Access to a user account with root privileges.

**Important:** If you assigned a password to the root account during the Debian installation, your regular user account may not have root privileges. To grant root privileges to your regular user, add the user to the `sudo` group as follows:

1. Install the `sudo` package:

   ```shell
   apt install sudo
   ```

2. Add your user to the `sudo` group:

   ```shell
   usermod -aG sudo <username>
   ```

   Replace `<username>` with your actual username.

3. Log out and log back in for the changes to take effect.

## Usage

To set up your Debian system, follow these steps:

1. **Install Required Packages**

   Run the following command to install necessary tools:

   ```shell
   apt install -y wget zip git
   ```

2. **Clone the Repository**

   Use `git` to clone this repository:

   ```shell
   git clone https://github.com/slash071/linux-setup.git
   ```

3. **Navigate to the Repository Directory**

   Change to the directory corresponding to your Debian version:

   ```shell
   cd linux-setup/debian/debian<version>
   ```

4. **Run the Setup Script**
   Execute the desired setup script:

   ```shell
   sudo bash <script>.sh
   ```

   Follow the prompts during execution and provide any required inputs.

## Contributing

Contributions are welcome! If you have any improvements or bug fixes, feel free to open an issue or submit a pull request.

## Disclaimer

Please use this script at your own risk. It is recommended to review the script and ensure it aligns with your system requirements before running it. We are not responsible for any damages or data loss caused by the use of this script.

Inspired from [1](https://github.com/b-sullender/debian-setup)
