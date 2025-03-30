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
SCRIPTS_DIR="/usr/local/share/aliasmate"  # Separate directory for scripts
CONFIG_DIR="/etc/aliasmate"
USER_CONFIG_DIR="/root/.config/aliasmate"
DATA_DIR="/root/.local/share/aliasmate"

echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  AliasMate v2 Installation (Docker)    │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# Function to install from current source
install_from_source() {
    echo -e "\n${CYAN}Installing AliasMate...${NC}"
    
    # Create necessary directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$USER_CONFIG_DIR"
    mkdir -p "$DATA_DIR/categories"
    mkdir -p "$DATA_DIR/stats"
    
    # Make all scripts executable
    echo -e "${CYAN}Making scripts executable...${NC}"
    find "./src" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Create the main executable as a wrapper
    echo -e "${CYAN}Creating main executable...${NC}"
    cat > "$INSTALL_DIR/aliasmate" << EOF
#!/usr/bin/env bash
# AliasMate v2 - Main entry point wrapper

# Set scripts directory
SCRIPTS_DIR="$SCRIPTS_DIR"

# Execute main script from scripts directory
cd "\$SCRIPTS_DIR"
exec bash "\$SCRIPTS_DIR/main.sh" "\$@"
EOF
    chmod +x "$INSTALL_DIR/aliasmate"
    
    # Copy source files to scripts directory
    echo -e "${CYAN}Copying source files...${NC}"
    cp -r ./src/* "$SCRIPTS_DIR/"
    
    # Ensure all scripts are executable
    find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Fix main.sh to use correct paths
    echo -e "${CYAN}Adjusting script paths...${NC}"
    sed -i "s|SCRIPT_DIR=\"\$(cd \"\$(dirname \"\${BASH_SOURCE\[0\]}\")\" && pwd)\"|SCRIPT_DIR=\"$SCRIPTS_DIR\"|g" "$SCRIPTS_DIR/main.sh"
    
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
    
    # Add alias for 'am' command
    echo -e "${CYAN}Creating 'am' alias...${NC}"
    if ! grep -q "alias am=" "/root/.bashrc"; then
        echo -e "\n# AliasMate shortcut alias" >> "/root/.bashrc"
        echo "alias am='aliasmate'" >> "/root/.bashrc"
    fi
    
    # Source the .bashrc to enable aliases immediately 
    echo -e "source ~/.bashrc" >> "/root/.bash_profile"
    
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
    if [ -f "$SCRIPTS_DIR/main.sh" ]; then
        echo -e "${GREEN}✓ Main script found${NC}"
    else
        echo -e "${RED}✗ Main script not found${NC}"
        return 1
    fi
    
    # Check key files
    for file in utils.sh config.sh commands.sh ui_components.sh; do
        if [ -f "$SCRIPTS_DIR/$file" ] || [ -f "$SCRIPTS_DIR/core/$file" ]; then
            echo -e "${GREEN}✓ Found $file${NC}"
        else
            echo -e "${RED}✗ Missing $file${NC}"
        fi
    done
    
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
    
    # Print debug info about the source files
    echo -e "${CYAN}Available source files:${NC}"
    find ./src -type f -name "*.sh" | sort
    
    install_from_source
    verify_installation
    
    # Create a simple test script
    echo -e "${CYAN}Creating test script...${NC}"
    cat > "$INSTALL_DIR/test-aliasmate" << EOF
#!/bin/bash
echo "Testing aliasmate command..."
aliasmate --version
EOF
    chmod +x "$INSTALL_DIR/test-aliasmate"
    
    # Provide clear instructions
    echo -e "\n${GREEN}AliasMate is ready for testing!${NC}"
    echo -e "${YELLOW}First, reload your shell environment:${NC}"
    echo -e "  source ~/.bashrc"
    echo -e "${YELLOW}Then try these commands:${NC}"
    echo -e "  aliasmate --help"
    echo -e "  am --version"
    echo -e "  test-aliasmate"
}

# Run main function
main
