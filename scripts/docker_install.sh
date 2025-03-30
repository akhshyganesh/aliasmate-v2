#!/usr/bin/env bash
# AliasMate v2 - Docker Installation Script
# Streamlined version that replicates standard installation

set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define variables - use the same paths as standard installation
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/aliasmate"
USER_CONFIG_DIR="/root/.config/aliasmate"
DATA_DIR="/root/.local/share/aliasmate"
TEMP_DIR=$(mktemp -d)

echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  AliasMate v2 Installation (Docker)    │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# Function to install from current source
install_from_source() {
    echo -e "\n${CYAN}Installing AliasMate...${NC}"
    
    # Create necessary directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$USER_CONFIG_DIR"
    mkdir -p "$DATA_DIR/categories"
    mkdir -p "$DATA_DIR/stats"
    
    # Make all scripts executable
    echo -e "${CYAN}Making scripts executable...${NC}"
    find "./src" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Create the main executable
    echo -e "${CYAN}Creating main executable...${NC}"
    cat > "$INSTALL_DIR/aliasmate" << 'EOF'
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
    chmod +x "$INSTALL_DIR/aliasmate"
    
    # Copy source files
    echo -e "${CYAN}Copying source files...${NC}"
    cp -r ./src/* "$INSTALL_DIR/"
    
    # Ensure all scripts are executable
    find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Create basic config
    echo -e "${CYAN}Creating configuration...${NC}"
    cat > "$USER_CONFIG_DIR/config.yaml" << EOF
COMMAND_STORE: $DATA_DIR
LOG_FILE: $USER_CONFIG_DIR/aliasmate.log
LOG_LEVEL: info
EDITOR: vi
VERSION_CHECK: false
THEME: default
EOF
    
    # Create symlink in /usr/bin for easier access
    echo -e "${CYAN}Creating symbolic link in /usr/bin...${NC}"
    if [ -e "/usr/bin/aliasmate" ]; then
        rm -f "/usr/bin/aliasmate"
    fi
    ln -sf "$INSTALL_DIR/aliasmate" /usr/bin/aliasmate
    
    # Add shell completion for bash
    echo -e "${CYAN}Setting up shell completion...${NC}"
    if ! grep -q "aliasmate completion" "/root/.bashrc"; then
        echo -e "\n# AliasMate shell completion" >> "/root/.bashrc"
        echo "if [ -x /usr/bin/aliasmate ]; then" >> "/root/.bashrc"
        echo "    source <(aliasmate completion bash 2>/dev/null || true)" >> "/root/.bashrc"
        echo "fi" >> "/root/.bashrc"
    fi
    
    echo -e "${GREEN}Installation complete!${NC}"
}

# Verify the installation
verify_installation() {
    echo -e "${CYAN}Verifying installation...${NC}"
    
    # Check if the executable is in place
    if [ -x "$INSTALL_DIR/aliasmate" ]; then
        echo -e "${GREEN}✓ Executable found at $INSTALL_DIR/aliasmate${NC}"
    else
        echo -e "${RED}✗ Executable not found${NC}"
        return 1
    fi
    
    # Check if source files are copied
    if [ -f "$INSTALL_DIR/main.sh" ]; then
        echo -e "${GREEN}✓ Main script found${NC}"
    else
        echo -e "${RED}✗ Main script not found${NC}"
        return 1
    fi
    
    # Check if config exists
    if [ -f "$USER_CONFIG_DIR/config.yaml" ]; then
        echo -e "${GREEN}✓ Configuration file created${NC}"
    else
        echo -e "${RED}✗ Configuration not found${NC}"
        return 1
    fi
    
    # Check command store
    if [ -d "$DATA_DIR" ]; then
        echo -e "${GREEN}✓ Command store created${NC}"
    else
        echo -e "${RED}✗ Command store not found${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Installation verified successfully!${NC}"
    return 0
}

# Main function
main() {
    # Verify we're in the right directory
    if [ ! -d "./src" ]; then
        echo -e "${RED}Error: Source directory not found${NC}"
        echo "Please run this script from the root of the AliasMate repository"
        exit 1
    fi
    
    install_from_source
    verify_installation
    
    echo -e "\n${GREEN}┌────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│  AliasMate installed successfully       │${NC}"
    echo -e "${GREEN}└────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}To get started, run:${NC} aliasmate --help"
    echo -e "${YELLOW}Or launch the TUI:${NC} aliasmate --tui"
}

# Run main function
main
