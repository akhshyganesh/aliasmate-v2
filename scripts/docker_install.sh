#!/usr/bin/env bash
# AliasMate v2 - Docker Installation Script
# This is a simplified version of the install script for containerized environments

set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define variables
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/aliasmate"
USER_CONFIG_DIR="/root/.config/aliasmate"
DATA_DIR="/root/.local/share/aliasmate"
TEMP_DIR=$(mktemp -d)

echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  AliasMate v2 Docker Installation      │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# For debugging
debug_files() {
    echo -e "\n${CYAN}Debugging file structure:${NC}"
    echo -e "Looking for key files in source dir:"
    find . -name "*.sh" | sort
    echo -e "\nContents of src directory:"
    ls -la ./src || echo "No src directory found"
    echo -e "\nInstalled files:"
    ls -la "$INSTALL_DIR"
}

# Function to install directly from source (current directory)
install_from_source() {
    echo -e "\n${CYAN}Installing AliasMate from source...${NC}"
    
    # Get current directory
    local SOURCE_DIR="$(pwd)"
    
    # Create necessary directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$USER_CONFIG_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$DATA_DIR/categories"
    mkdir -p "$DATA_DIR/stats"
    
    # Make all scripts executable
    echo -e "${CYAN}Making scripts executable...${NC}"
    find "$SOURCE_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Create the main executable wrapper
    echo -e "${CYAN}Creating main executable...${NC}"
    cat > "$INSTALL_DIR/aliasmate" << 'EOF'
#!/usr/bin/env bash
# AliasMate v2 - Main entry point wrapper

# Set installation directory (where all scripts are located)
INSTALL_DIR="/usr/local/bin/aliasmate"

# Check if the installation directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "Error: AliasMate installation directory not found at $INSTALL_DIR"
    echo "Try reinstalling AliasMate."
    exit 1
fi

# Source the main script
if [[ -f "$INSTALL_DIR/main.sh" ]]; then
    # Change to the install directory so relative paths work
    cd "$INSTALL_DIR"
    source "$INSTALL_DIR/main.sh" "$@"
else
    echo "Error: AliasMate installation is broken - main.sh not found"
    echo "Expected location: $INSTALL_DIR/main.sh"
    echo "Try reinstalling AliasMate."
    exit 1
fi
EOF
    chmod +x "$INSTALL_DIR/aliasmate"
    
    # Create a dedicated directory for AliasMate scripts
    mkdir -p "$INSTALL_DIR/aliasmate"
    
    # Copy source files to the dedicated directory
    echo -e "${CYAN}Copying source files...${NC}"
    cp -r "$SOURCE_DIR/src/"* "$INSTALL_DIR/aliasmate/"
    chmod +x "$INSTALL_DIR/aliasmate/"*.sh
    
    # Copy the core directory if it exists
    if [[ -d "$SOURCE_DIR/src/core" ]]; then
        mkdir -p "$INSTALL_DIR/aliasmate/core"
        cp -r "$SOURCE_DIR/src/core/"* "$INSTALL_DIR/aliasmate/core/"
        chmod +x "$INSTALL_DIR/aliasmate/core/"*.sh
    fi
    
    # Create basic config file
    echo -e "${CYAN}Creating configuration...${NC}"
    cat > "$CONFIG_DIR/config.yaml" << EOF
COMMAND_STORE: $DATA_DIR
LOG_FILE: $USER_CONFIG_DIR/aliasmate.log
LOG_LEVEL: info
EDITOR: vi
VERSION_CHECK: false
THEME: default
EOF
    cp "$CONFIG_DIR/config.yaml" "$USER_CONFIG_DIR/"
    
    # Create symlinks in /usr/bin
    echo -e "${CYAN}Creating symbolic link in /usr/bin...${NC}"
    ln -sf "$INSTALL_DIR/aliasmate" /usr/bin/aliasmate
    
    echo -e "${GREEN}Installation complete!${NC}"
    
    # Show debug information
    debug_files
}

# Simple verification function
verify_installation() {
    echo -e "\n${CYAN}Verifying installation...${NC}"
    
    if [[ -x "$INSTALL_DIR/aliasmate" ]]; then
        echo -e "${GREEN}✓ Executable installed at $INSTALL_DIR/aliasmate${NC}"
    else
        echo -e "${RED}✗ Executable not found at $INSTALL_DIR/aliasmate${NC}"
        return 1
    fi
    
    if [[ -f "$USER_CONFIG_DIR/config.yaml" ]]; then
        echo -e "${GREEN}✓ Configuration file created${NC}"
    else
        echo -e "${RED}✗ Configuration file not found${NC}"
        return 1
    fi
    
    if command -v aliasmate &> /dev/null; then
        echo -e "${GREEN}✓ 'aliasmate' command available in PATH${NC}"
    else
        echo -e "${RED}✗ 'aliasmate' command not in PATH${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Installation verified successfully!${NC}"
    
    # Print important file paths for troubleshooting
    echo -e "\n${CYAN}Installation locations:${NC}"
    echo -e "  Main executable: $INSTALL_DIR/aliasmate"
    echo -e "  Scripts directory: $INSTALL_DIR/aliasmate/"
    echo -e "  Configuration: $USER_CONFIG_DIR/config.yaml"
    echo -e "  Data directory: $DATA_DIR"
    
    return 0
}

# Main installation flow
main() {
    echo -e "${CYAN}Starting installation in Docker environment...${NC}"
    
    # Check for necessary files
    if [[ ! -d "./src" ]]; then
        echo -e "${RED}Error: Source directory not found${NC}"
        echo "Please run this script from the root of the AliasMate repository"
        exit 1
    fi
    
    install_from_source
    verify_installation
    
    echo -e "\n${GREEN}┌────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│  AliasMate v2 installed successfully    │${NC}"
    echo -e "${GREEN}└────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}To get started, run:${NC} aliasmate --help"
    echo -e "${YELLOW}Or launch the TUI:${NC} aliasmate --tui"
    echo -e "\n${CYAN}If you encounter issues, please check:${NC}"
    echo -e "1. That all required files are in $INSTALL_DIR/aliasmate/"
    echo -e "2. That the main.sh script correctly sources other modules"
}

# Execute the main function
main
