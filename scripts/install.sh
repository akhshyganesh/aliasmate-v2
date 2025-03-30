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
UPGRADE_MODE=false

trap 'cleanup' EXIT

cleanup() {
    echo -e "\n${CYAN}Cleaning up temporary files...${NC}"
    rm -rf "$TEMP_DIR"
}

echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│       AliasMate v2 Installer           │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# Process args
for arg in "$@"; do
    case "$arg" in
        --upgrade)
            UPGRADE_MODE=true
            ;;
        --debug)
            set -x
            print_debug_info
            ;;
    esac
done

# Print verbose debugging information
print_debug_info() {
    echo -e "\n${CYAN}System information:${NC}"
    echo -e "  OS: $(uname -s)"
    echo -e "  Distribution: $(detect_os)"
    echo -e "  Package manager: $(get_package_manager)"
    echo -e "  Shell: $SHELL"
    echo -e "  User: $(whoami)"
    echo -e "  Running in Docker: $(is_docker && echo 'Yes' || echo 'No')"
    echo -e "  Installation directory: $INSTALL_DIR"
    echo -e "  User permissions: $(if need_sudo; then echo 'Requires sudo'; else echo 'No sudo needed'; fi)"
}

# Function to detect OS
detect_os() {
    local os=$(uname -s)
    
    case "$os" in
        Linux)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                echo "$NAME"
            else
                echo "Linux (generic)"
            fi
            ;;
        Darwin)
            echo "macOS"
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
                echo -e "${RED}Warning: Could not install jq automatically.${NC}"
                echo "Please install jq manually before continuing."
                read -p "Continue without jq? (y/n): " continue_without_jq
                if [[ ! "$continue_without_jq" =~ ^[Yy]$ ]]; then
                    exit 1
                fi
                ;;
        esac
        
        # Verify jq was installed successfully
        if ! command -v jq &> /dev/null; then
            echo -e "${YELLOW}Failed to install jq automatically.${NC}"
            echo "AliasMate will have limited functionality without jq."
            echo "Please consider installing jq manually after installation."
        else
            echo -e "${GREEN}Successfully installed jq!${NC}"
        fi
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing[*]}${NC}"
        echo "Please install these dependencies and try again."
        exit 1
    else
        echo -e "${GREEN}All core dependencies are met!${NC}"
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

# Function to detect if running in Docker
is_docker() {
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to determine if sudo is needed
need_sudo() {
    if [ "$(id -u)" -eq 0 ] || [ -w "$INSTALL_DIR" ]; then
        # Running as root or install dir is writable, no need for sudo
        return 1
    else
        # Not running as root and install dir not writable, need sudo
        return 0
    fi
}

# Helper function to run a command with sudo if needed
run_with_sudo() {
    if need_sudo; then
        sudo "$@"
    else
        "$@"
    fi
}

# Function to download the source directly rather than using GitHub releases
download_source() {
    echo -e "\n${CYAN}Downloading AliasMate source code...${NC}"
    
    # Check if we're inside a Docker container with the code mounted
    if [ -f /.dockerenv ] && [ -d "/app/src" ]; then
        echo -e "${CYAN}Detected Docker environment with code mounted, using local files${NC}"
        install_from_source "/app"
        return 0
    fi
    
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
    if ! tar -xzf "$source_archive" -C "$TEMP_DIR/source" --strip-components=1; then
        echo -e "${RED}Error: Failed to extract source code${NC}"
        exit 1
    fi
    
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
    run_with_sudo mkdir -p "$INSTALL_DIR"
    run_with_sudo mkdir -p "$CONFIG_DIR"
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
    REAL_PATH=$(readlink -f "$0" 2>/dev/null || readlink "$0" 2>/dev/null || echo "$0")
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
    run_with_sudo cp "$TEMP_DIR/aliasmate" "$INSTALL_DIR/aliasmate"
    
    # Copy source files
    run_with_sudo cp -r "$source_dir/src/"* "$INSTALL_DIR/"
    
    # Make all script files executable
    run_with_sudo chmod -R +x "$INSTALL_DIR/"*.sh
    
    # Copy default configuration file
    if [[ ! -f "$USER_CONFIG_DIR/config.yaml" ]]; then
        echo -e "${CYAN}Setting up default configuration...${NC}"
        cp "$source_dir/config/config.yaml" "$USER_CONFIG_DIR/"
        # Update paths in the config file
        sed -i.bak "s|COMMAND_STORE:.*|COMMAND_STORE: $DATA_DIR|g" "$USER_CONFIG_DIR/config.yaml"
        rm -f "$USER_CONFIG_DIR/config.yaml.bak"
    else
        echo -e "${CYAN}Preserving existing user configuration...${NC}"
    fi
    
    # Set up shell completion for bash if available
    if [[ -d "/etc/bash_completion.d" ]] && [[ -f "$source_dir/completions/aliasmate.bash" ]]; then
        echo -e "${CYAN}Installing bash completion...${NC}"
        run_with_sudo cp "$source_dir/completions/aliasmate.bash" "/etc/bash_completion.d/aliasmate"
    fi
    
    # Set up shell completion for zsh if available
    if [[ -d "/usr/share/zsh/site-functions" ]] && [[ -f "$source_dir/completions/aliasmate.zsh" ]]; then
        echo -e "${CYAN}Installing zsh completion...${NC}"
        run_with_sudo cp "$source_dir/completions/aliasmate.zsh" "/usr/share/zsh/site-functions/_aliasmate"
    fi
    
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${CYAN}AliasMate is now installed at: $INSTALL_DIR/aliasmate${NC}"
}

# Function to configure shell integrations
configure_shell_integration() {
    echo -e "\n${CYAN}Configuring shell integration...${NC}"
    
    # Detect shell type
    local shell_type=$(basename "$SHELL")
    local rc_file=""
    local completion_cmd=""
    
    case "$shell_type" in
        bash)
            rc_file="$HOME/.bashrc"
            completion_cmd="source <(aliasmate completion bash)"
            ;;
        zsh)
            rc_file="$HOME/.zshrc"
            completion_cmd="source <(aliasmate completion zsh)"
            ;;
        *)
            echo -e "${YELLOW}Shell type '$shell_type' not directly supported for auto-configuration.${NC}"
            echo -e "To enable shell completion manually, run one of these commands:"
            echo -e "  For Bash: echo 'source <(aliasmate completion bash)' >> ~/.bashrc"
            echo -e "  For Zsh: echo 'source <(aliasmate completion zsh)' >> ~/.zshrc"
            return 0
            ;;
    esac
    
    # Ask user if they want to set up shell completion
    read -p "Would you like to set up shell completion for $shell_type? (y/n): " setup_completion
    if [[ "$setup_completion" =~ ^[Yy]$ ]]; then
        if grep -q "aliasmate completion" "$rc_file"; then
            echo -e "${YELLOW}Shell completion appears to be already configured in $rc_file${NC}"
        else
            echo "$completion_cmd" >> "$rc_file"
            echo -e "${GREEN}Shell completion has been added to $rc_file${NC}"
            echo -e "To activate it in your current session, run: source $rc_file"
        fi
    else
        echo -e "${CYAN}Skipping shell completion setup.${NC}"
    fi
}

# Main installation function
main() {
    echo -e "${CYAN}Starting AliasMate installation...${NC}"
    
    # Check for dependencies
    check_dependencies
    
    # Download and install
    download_source
    
    # Configure shell integration
    configure_shell_integration
    
    echo -e "\n${GREEN}AliasMate v2 has been successfully installed!${NC}"
    echo -e "To get started, run: ${CYAN}aliasmate --help${NC}"
    echo -e "For more information, visit: ${CYAN}https://github.com/$REPO${NC}"
}

# Execute main function
main
