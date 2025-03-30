#!/usr/bin/env bash
# AliasMate v2 - Installation Script

set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define variables
REPO="akhshyganesh/aliasmate-v2"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/aliasmate"
USER_CONFIG_DIR="$HOME/.config/aliasmate"
DATA_DIR="$HOME/.local/share/aliasmate"
TEMP_DIR=$(mktemp -d)

echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│       AliasMate v2 Installer           │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# Function to detect the OS and architecture
detect_os() {
    local os="unknown"
    local arch=$(uname -m)
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        os="windows"
    fi
    
    echo "Detected: $os on $arch"
    
    case "$os" in
        linux|macos)
            # These platforms are supported
            ;;
        *)
            echo -e "${RED}Error: Unsupported operating system: $os${NC}"
            echo "AliasMate currently supports Linux and macOS."
            exit 1
            ;;
    esac
}

# Function to check for dependencies
check_dependencies() {
    echo -e "\n${CYAN}Checking dependencies...${NC}"
    
    local deps=("curl" "bash" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Missing dependencies: ${missing[*]}${NC}"
        
        case $(get_package_manager) in
            apt)
                echo -e "${YELLOW}Installing dependencies with apt...${NC}"
                sudo apt-get update
                sudo apt-get install -y "${missing[@]}"
                ;;
            dnf|yum)
                echo -e "${YELLOW}Installing dependencies with dnf/yum...${NC}"
                sudo $(get_package_manager) install -y "${missing[@]}"
                ;;
            brew)
                echo -e "${YELLOW}Installing dependencies with Homebrew...${NC}"
                brew install "${missing[@]}"
                ;;
            *)
                echo -e "${RED}Error: Could not install dependencies automatically.${NC}"
                echo "Please install the following packages manually: ${missing[*]}"
                exit 1
                ;;
        esac
    else
        echo -e "${GREEN}All dependencies are met!${NC}"
    fi
}

# Function to get the package manager
get_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v brew &> /dev/null; then
        echo "brew"
    else
        echo "unknown"
    fi
}

# Function to download the latest release
download_release() {
    echo -e "\n${CYAN}Downloading latest AliasMate release...${NC}"
    
    # Get the latest release information
    local api_url="https://api.github.com/repos/$REPO/releases/latest"
    local latest_version
    local download_url
    
    if ! latest_release=$(curl -s "$api_url"); then
        echo -e "${RED}Error: Failed to fetch release information${NC}"
        exit 1
    fi
    
    latest_version=$(echo "$latest_release" | jq -r .tag_name)
    echo -e "${GREEN}Found latest version: $latest_version${NC}"
    
    # Determine which asset to download based on OS and architecture
    local os_name=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch_name=$(uname -m)
    
    if [[ "$os_name" == "darwin" ]]; then
        os_name="macos"
    fi
    
    if [[ "$arch_name" == "x86_64" ]]; then
        arch_name="amd64"
    elif [[ "$arch_name" == "aarch64" ]]; then
        arch_name="arm64"
    fi
    
    # Find the appropriate download URL
    if [[ "$os_name" == "linux" ]]; then
        download_url=$(echo "$latest_release" | jq -r ".assets[] | select(.name | contains(\"$os_name\") and contains(\"$arch_name\") and (contains(\".deb\") or contains(\".tar.gz\"))) | .browser_download_url")
    else
        download_url=$(echo "$latest_release" | jq -r ".assets[] | select(.name | contains(\"$os_name\") and contains(\"$arch_name\")) | .browser_download_url")
    fi
    
    if [[ -z "$download_url" ]]; then
        echo -e "${RED}Error: Could not find a suitable download for your system ($os_name $arch_name)${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}Downloading from: $download_url${NC}"
    
    # Download the release
    local pkg_path="$TEMP_DIR/$(basename "$download_url")"
    if ! curl -L "$download_url" -o "$pkg_path"; then
        echo -e "${RED}Error: Download failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Download complete!${NC}"
    
    # Install the package
    install_package "$pkg_path"
}

# Function to install the package
install_package() {
    local pkg_path="$1"
    
    echo -e "\n${CYAN}Installing AliasMate...${NC}"
    
    # Create necessary directories
    sudo mkdir -p "$INSTALL_DIR"
    sudo mkdir -p "$CONFIG_DIR"
    mkdir -p "$USER_CONFIG_DIR"
    mkdir -p "$DATA_DIR"
    
    if [[ "$pkg_path" == *".deb" ]]; then
        sudo dpkg -i "$pkg_path"
        if [[ $? -ne 0 ]]; then
            echo -e "${YELLOW}Fixing dependencies...${NC}"
            sudo apt-get install -f -y
        fi
    elif [[ "$pkg_path" == *".rpm" ]]; then
        sudo rpm -i "$pkg_path"
    elif [[ "$pkg_path" == *".tar.gz" ]]; then
        tar -xzf "$pkg_path" -C "$TEMP_DIR"
        sudo cp -r "$TEMP_DIR/aliasmate"/* "$INSTALL_DIR/"
        sudo chmod +x "$INSTALL_DIR/aliasmate"
    else
        echo -e "${RED}Error: Unsupported package format: $pkg_path${NC}"
        exit 1
    fi
    
    # Set up configuration
    if [[ ! -f "$CONFIG_DIR/config.yaml" ]]; then
        sudo cp "$INSTALL_DIR/etc/aliasmate/config.yaml" "$CONFIG_DIR/"
    fi
    
    if [[ ! -f "$USER_CONFIG_DIR/config.yaml" ]]; then
        cp "$INSTALL_DIR/etc/aliasmate/config.yaml" "$USER_CONFIG_DIR/"
    fi
    
    # Set up shell completion
    case "$SHELL" in
        */bash)
            # Set up Bash completion
            if [[ ! -f "$HOME/.bashrc" ]]; then
                touch "$HOME/.bashrc"
            fi
            
            if ! grep -q "aliasmate completion" "$HOME/.bashrc"; then
                echo -e "\n# AliasMate shell completion" >> "$HOME/.bashrc"
                echo "source <(aliasmate completion bash)" >> "$HOME/.bashrc"
                echo -e "${GREEN}Added Bash completion to ~/.bashrc${NC}"
            fi
            ;;
        */zsh)
            # Set up Zsh completion
            if [[ ! -f "$HOME/.zshrc" ]]; then
                touch "$HOME/.zshrc"
            fi
            
            if ! grep -q "aliasmate completion" "$HOME/.zshrc"; then
                echo -e "\n# AliasMate shell completion" >> "$HOME/.zshrc"
                echo "source <(aliasmate completion zsh)" >> "$HOME/.zshrc"
                echo -e "${GREEN}Added Zsh completion to ~/.zshrc${NC}"
            fi
            ;;
    esac
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "${CYAN}Try running: aliasmate --help${NC}"
}

# Function to perform post-installation steps
post_install() {
    echo -e "\n${GREEN}AliasMate v2 has been successfully installed!${NC}"
    
    # Offer to run the onboarding tutorial
    if [[ -t 0 && -t 1 ]]; then  # Only offer if running in an interactive terminal
        echo -e "\nWould you like to run the onboarding tutorial? [y/N]"
        read -r run_tutorial
        if [[ "$run_tutorial" =~ ^[Yy] ]]; then
            aliasmate tutorial onboarding
        else
            echo -e "\nYou can run the tutorial anytime with: ${YELLOW}aliasmate tutorial${NC}"
            echo -e "For basic usage, run: ${YELLOW}aliasmate --help${NC}"
        fi
    fi
    
    echo -e "\n${GREEN}Installation complete. Enjoy using AliasMate!${NC}"
}

# Function to clean up temporary files
cleanup() {
    echo -e "\n${CYAN}Cleaning up...${NC}"
    rm -rf "$TEMP_DIR"
}

# Main installation flow
main() {
    detect_os
    check_dependencies
    download_release
    cleanup
    
    echo -e "\n${GREEN}┌────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│    AliasMate v2 installed successfully  │${NC}"
    echo -e "${GREEN}└────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}To get started, run:${NC} aliasmate --help"
    echo -e "${YELLOW}Or launch the TUI:${NC} aliasmate --tui"
    echo -e "${YELLOW}Documentation:${NC} https://akhshyganesh.github.io/aliasmate-v2/docs/"
    
    # After completing the installation
    post_install
}

# Execute the main function
main

# Trap for cleanup
trap cleanup EXIT
