#!/bin/bash
#
# This script sets up a new system by:
# 1. Reading the .env file to see which applications are enabled.
# 2. Installing the necessary system packages for those applications.
# 3. Running post-install setups (e.g., lazy.nvim, Nerd Fonts).
# 4. Applying the collected dotfiles and the selected theme using the Makefile.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
ENV_FILE=".env"

# Check for the .env file.
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE file not found."
    echo "Please create one with an ENABLED variable, for example:"
    echo "ENABLED = nvim tmux bash alacritty"
    exit 1
fi

ENABLED=$(grep '^[[:space:]]*ENABLED' "$ENV_FILE" | cut -d '=' -f 2- | xargs)

if [ -z "$ENABLED" ]; then
    echo "Error: The ENABLED variable is not set in your .env file."
    exit 1
fi
echo "Found enabled configurations: $ENABLED"

# --- Prerequisite Checks ---
# Check for root privileges and get the original user.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo or as root."
   exit 1
fi
SUDO_USER=${SUDO_USER:-$(whoami)}

# --- Package Manager Detection ---
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    UPDATE_CMD="apt-get update"
    INSTALL_CMD="apt-get install -y"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    UPDATE_CMD="pacman -Syy"
    INSTALL_CMD="pacman -S --noconfirm"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    UPDATE_CMD="dnf check-update"
    INSTALL_CMD="dnf install -y"
else
    echo "Unsupported package manager. Please install packages manually."
    exit 1
fi
echo "Detected package manager: $PKG_MANAGER"

# --- Dynamic Package List Creation ---
PACKAGES_TO_INSTALL=()
# 'make' and 'git' are essential for the dotfile management workflow itself.
PACKAGES_TO_INSTALL+=("make" "git")

for app in $ENABLED; do
    case "$app" in
        nvim)
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                # Neovim stable PPA is outdated; use unstable for >= 0.8.0 (required by lazy.nvim).
                if ! grep -q "neovim-ppa/unstable" /etc/apt/sources.list.d/*.list 2>/dev/null; then
                    echo "Adding Neovim unstable PPA..."
                    apt-get install -y software-properties-common
                    add-apt-repository -y ppa:neovim-ppa/unstable
                fi
            fi
            PACKAGES_TO_INSTALL+=("neovim" "curl")
            ;;
        tmux)       PACKAGES_TO_INSTALL+=("tmux") ;;
        alacritty)
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                # Alacritty is not in Ubuntu's default repos; add the PPA.
                if ! grep -q "aslatter/ppa" /etc/apt/sources.list.d/*.list 2>/dev/null; then
                    echo "Adding Alacritty PPA..."
                    apt-get install -y software-properties-common
                    add-apt-repository -y ppa:aslatter/ppa
                fi
            fi
            PACKAGES_TO_INSTALL+=("alacritty")
            ;;
        hyprland)   PACKAGES_TO_INSTALL+=("hyprland") ;;
        waybar)     PACKAGES_TO_INSTALL+=("waybar") ;;
        zathura)    PACKAGES_TO_INSTALL+=("zathura") ;;
        latex)      PACKAGES_TO_INSTALL+=("texlive-full") ;;
        rclone)     PACKAGES_TO_INSTALL+=("rclone") ;;
        bash)       ;;
        *)          echo "Warning: No installation rule for '$app'. Please install it manually if needed." ;;
    esac
done

# --- Install System Packages ---
if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
    echo "Updating package lists..."
    $UPDATE_CMD
    echo "Installing required packages: ${PACKAGES_TO_INSTALL[*]}..."
    $INSTALL_CMD "${PACKAGES_TO_INSTALL[@]}"
    echo "System packages installed."
else
    echo "No new packages to install."
fi

# --- Install tree-sitter-cli (npm/cargo, not available via apt) ---
if [[ " $ENABLED " =~ " nvim " ]]; then
    if ! command -v tree-sitter &> /dev/null; then
        if command -v npm &> /dev/null; then
            echo "Installing tree-sitter-cli via npm..."
            npm install -g tree-sitter-cli
        elif command -v cargo &> /dev/null; then
            echo "Installing tree-sitter-cli via cargo..."
            sudo -u "$SUDO_USER" cargo install tree-sitter-cli
        else
            echo "Warning: tree-sitter-cli requires npm or cargo. Please install it manually."
        fi
    else
        echo "tree-sitter-cli is already installed."
    fi
fi

# --- Application-Specific Setups ---
# Install Neovim Plugin Manager (lazy.nvim) if nvim is enabled.
if [[ " $ENABLED " =~ " nvim " ]]; then
    LAZY_DIR="/home/$SUDO_USER/.local/share/nvim/lazy/lazy.nvim"
    if [ ! -d "$LAZY_DIR" ]; then
        echo "Installing lazy.nvim for Neovim..."
        # Run as the original user to avoid permission issues.
        sudo -u "$SUDO_USER" git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZY_DIR"
    else
        echo "lazy.nvim is already installed."
    fi
fi

# Install Nerd Font if a GUI or TUI app that benefits from it is enabled.
if [[ " $ENABLED " =~ (nvim|alacritty|hyprland|waybar) ]]; then
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
    USER_HOME=$(eval echo ~"$SUDO_USER")
    FONT_DIR="$USER_HOME/.local/share/fonts"
    EXPECTED_FONT_FILE="$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf"

    if [ -f "$EXPECTED_FONT_FILE" ]; then
        echo "JetBrains Mono Nerd Font already appears to be installed."
    else
        echo "Downloading and installing JetBrains Mono Nerd Font..."
        sudo -u "$SUDO_USER" mkdir -p "$FONT_DIR"
        curl -L -f -o /tmp/JetBrainsMono.zip "$FONT_URL"
        sudo -u "$SUDO_USER" unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR"
        rm /tmp/JetBrainsMono.zip
        echo "Updating font cache..."
        sudo -u "$SUDO_USER" fc-cache -f
    fi
fi

# --- Apply Dotfiles ---
echo # Add a newline for better formatting.
read -p "System setup complete. Apply dotfiles now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Applying dotfiles for: $ENABLED..."
    # Run 'make apply' as the original user to ensure correct file ownership.
    sudo -u "$SUDO_USER" make apply
    # The configs import a generated theme file, so it must exist before first use.
    sudo -u "$SUDO_USER" make theme
else
    echo "Skipping dotfile application. You can run 'make apply && make theme' later to finish."
fi

echo "All done!"
