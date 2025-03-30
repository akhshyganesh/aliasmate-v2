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

# Print verbose debugging information
print_debug_info() {
    echo -e "\n${CYAN}System information:${NC}"
    echo -e "  OS: $(uname -s)"
    echo -e "  Arch: $(uname -m)"
    echo -e "  Shell: $SHELL"
    echo -e "  User: $(whoami)"
    echo -e "  PATH: $PATH"
    echo -e "  Install directory: $INSTALL_DIR"
    echo -e "  Working directory: $(pwd)"
}

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
    
    local deps=("curl" "bash")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    # Special check for jq - it's needed but we can install it if missing
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Required dependency 'jq' is missing. Attempting to install...${NC}"
        
        case $(get_package_manager) in
            apt)
                echo -e "${YELLOW}Installing jq with apt...${NC}"
                sudo apt-get update
                sudo apt-get install -y jq
                ;;
            dnf|yum)
                echo -e "${YELLOW}Installing jq with dnf/yum...${NC}"
                sudo $(get_package_manager) install -y jq
                ;;
            brew)
                echo -e "${YELLOW}Installing jq with Homebrew...${NC}"
                brew install jq
                ;;
            *)
                echo -e "${RED}Error: Could not install jq automatically.${NC}"
                echo "Please install jq manually and run the installer again."
                exit 1
                ;;
        esac
        
        # Verify jq was installed successfully
        if ! command -v jq &> /dev/null; then
            echo -e "${RED}Failed to install jq. Installation cannot continue.${NC}"
            exit 1
        fi
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing[*]}${NC}"
        echo "Please install these dependencies and try again."
        exit 1
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

# Function to download the source directly rather than using GitHub releases
download_source() {
    echo -e "\n${CYAN}Downloading AliasMate source code...${NC}"
    
    local download_url="https://github.com/$REPO/archive/main.tar.gz"
    local source_archive="$TEMP_DIR/aliasmate-source.tar.gz"
    
    echo -e "${CYAN}Downloading from: $download_url${NC}"
    
    if ! curl -L "$download_url" -o "$source_archive"; then
        echo -e "${RED}Error: Download failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Download complete!${NC}"
    
    # Extract the source code
    echo -e "${CYAN}Extracting source code...${NC}"
    mkdir -p "$TEMP_DIR/source"
    tar -xzf "$source_archive" -C "$TEMP_DIR/source" --strip-components=1
    
    if [[ ! -d "$TEMP_DIR/source/src" ]]; then
        echo -e "${RED}Error: Invalid source archive - 'src' directory not found${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Source code extracted successfully!${NC}"
    
    # Install from source
    install_from_source "$TEMP_DIR/source"
}

# Function to install from source
install_from_source() {
    local source_dir="$1"
    
    echo -e "\n${CYAN}Installing AliasMate from source...${NC}"
    
    # Create necessary directories
    sudo mkdir -p "$INSTALL_DIR"
    sudo mkdir -p "$CONFIG_DIR"
    mkdir -p "$USER_CONFIG_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$DATA_DIR/categories"
    mkdir -p "$DATA_DIR/stats"
    
    # Copy source files
    echo -e "${CYAN}Copying files to $INSTALL_DIR...${NC}"
    
    # Create a single executable script
    echo -e "${CYAN}Creating main executable...${NC}"
    cat > "$TEMP_DIR/aliasmate" << 'EOF'
#!/usr/bin/env bash
# AliasMate v2 - Main entry point wrapper

# Find the real installation directory
if [[ -L "$0" ]]; then
    # Follow symlink to get the real path
    REAL_PATH=$(readlink -f "$0")
    INSTALL_DIR=$(dirname "$REAL_PATH")
else
    INSTALL_DIR=$(dirname "$0")
fi

# Source the main script
if [[ -f "$INSTALL_DIR/main.sh" ]]; then
    source "$INSTALL_DIR/main.sh" "$@"
else
    echo "Error: AliasMate installation is broken - main.sh not found"
    echo "Expected location: $INSTALL_DIR/main.sh"
    echo "Try reinstalling AliasMate."
    exit 1
fi
EOF

    # Make executable
    chmod +x "$TEMP_DIR/aliasmate"
    
    # Copy the main executable
    sudo cp "$TEMP_DIR/aliasmate" "$INSTALL_DIR/aliasmate"
    
    # Copy source files
    sudo cp -r "$source_dir/src/"* "$INSTALL_DIR/"
    
    # Make all shell scripts executable
    echo -e "${CYAN}Making all scripts executable...${NC}"
    sudo find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Copy config files
    if [[ -d "$source_dir/config" ]]; then
        sudo cp -r "$source_dir/config/"* "$CONFIG_DIR/"
        cp -r "$source_dir/config/"* "$USER_CONFIG_DIR/"
    else
        # Create a basic config file if none exists
        cat > "$TEMP_DIR/config.yaml" << EOF
COMMAND_STORE: $DATA_DIR
LOG_FILE: $USER_CONFIG_DIR/aliasmate.log
LOG_LEVEL: info
EDITOR: vi
VERSION_CHECK: true
THEME: default
EOF
        sudo cp "$TEMP_DIR/config.yaml" "$CONFIG_DIR/"
        cp "$TEMP_DIR/config.yaml" "$USER_CONFIG_DIR/"
    fi
    
    # Verify installation
    if [[ ! -x "$INSTALL_DIR/aliasmate" ]]; then
        echo -e "${RED}Error: Installation failed - executable not found${NC}"
        echo "The aliasmate executable should be at $INSTALL_DIR/aliasmate"
        exit 1
    fi
    
    # Create symlink if /usr/bin is in PATH but /usr/local/bin is not
    if [[ ! ":$PATH:" == *":/usr/local/bin:"* ]] && [[ ":$PATH:" == *":/usr/bin:"* ]]; then
        echo -e "${YELLOW}Creating symlink in /usr/bin for compatibility...${NC}"
        sudo ln -sf "$INSTALL_DIR/aliasmate" /usr/bin/aliasmate
    fi
    
    echo -e "${GREEN}Installation from source complete!${NC}"
}

# Function to perform post-installation steps
post_install() {
    echo -e "\n${GREEN}AliasMate v2 has been installed!${NC}"
    
    # Verify the installation
    echo -e "${CYAN}Verifying installation...${NC}"
    
    if command -v aliasmate &> /dev/null; then
        echo -e "${GREEN}  ✓ 'aliasmate' command is available${NC}"
    else
        echo -e "${RED}  ✗ 'aliasmate' command not found in PATH${NC}"
        echo -e "${YELLOW}  You may need to add $INSTALL_DIR to your PATH${NC}"
        echo -e "${YELLOW}  or create a symlink to $INSTALL_DIR/aliasmate in a directory in your PATH${NC}"
        
        # Suggest commands to fix PATH
        echo -e "\n${CYAN}To add aliasmate to your PATH, run one of these commands:${NC}"
        echo -e "  echo 'export PATH=\$PATH:$INSTALL_DIR' >> ~/.bashrc && source ~/.bashrc"
        echo -e "  sudo ln -sf $INSTALL_DIR/aliasmate /usr/bin/aliasmate"
    fi
    
    # Show where files are installed
    echo -e "\n${CYAN}Installation locations:${NC}"
    echo -e "  Executable: $INSTALL_DIR/aliasmate"
    echo -e "  System config: $CONFIG_DIR"
    echo -e "  User config: $USER_CONFIG_DIR"
    echo -e "  Data directory: $DATA_DIR"
    
    # Offer to run the onboarding tutorial
    if [[ -t 0 && -t 1 ]] && command -v aliasmate &> /dev/null; then  # Only offer if running in an interactive terminal
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

# Function to handle installation errors
handle_error() {
    echo -e "\n${RED}Error: Installation failed!${NC}"
    echo -e "Please check the error messages above."
    echo -e "If you need help, please open an issue at:"
    echo -e "https://github.com/$REPO/issues"
    
    # Print debug information to help diagnose the issue
    print_debug_info
    
    # Clean up before exiting
    cleanup
    exit 1
}

# Main installation flow
main() {
    # Set up error handling
    trap handle_error ERR
    
    detect_os
    check_dependencies
    download_source
    post_install
    
    echo -e "\n${GREEN}┌────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│    AliasMate v2 installed successfully  │${NC}"
    echo -e "${GREEN}└────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}To get started, run:${NC} aliasmate --help"
    echo -e "${YELLOW}Or launch the TUI:${NC} aliasmate --tui"
    echo -e "${YELLOW}For tutorials:${NC} aliasmate tutorial"
}

# Execute the main function
main

# Trap for cleanup
trap cleanup EXIT
