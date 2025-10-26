# Alpine Setup Scripts

These scripts automate the setup process for **Alpine Linux**, including:

- Installing a desktop environment
- Installing essential tools and utilities
- Installing development tools

They can be used to quickly configure a system for **Digital Forensics & Incident Response (DFIR)** labs, development, or general-purpose use.

## Prerequisites

- A fresh installation of Alpine
- A user account with root privileges

> [!Important]
> Before running the setup scripts, make sure `bash` is installed (and ideally set as your default shell). If you also prefer `sudo` instead of Alpine’s default `doas`, perform the following steps **as the root user**:
>
> 1. Install `bash` and set it as the default shell:
>
>    ```sh
>    apk update && apk add bash bash-completion shadow
>    chsh -s $(which bash) <USERNAME>
>    ```
>
> 2. Install the `sudo` package (as the equivalent to _doas_):
>
>    ```sh
>    apk add sudo
>    usermod -aG wheel <USERNAME>
>    ```
>
> 3. Reboot and log back in for the changes to take effect.

## Usage

Follow these steps to set up your Alpine system:

1. **Install Required Packages**

   Install essential tools for the setup scripts:

   ```shell
   sudo apk update && sudo apk add wget zip git
   ```

2. **Clone the Repository**

   Clone this repository to your local machine:

   ```shell
   git clone https://github.com/ackreq/linux-setup.git
   ```

3. **Navigate to the Repository Directory**

   Move into the folder corresponding to your Alpine version:

   ```shell
   cd linux-setup/alpine/alpine<VERSION>
   ```

4. **Run the Setup Script**

   Execute the desired setup script:

   ```shell
   sudo bash <SCRIPT>.sh
   ```

   Follow the prompts and provide any required input during execution.
