#!/usr/bin/env bash
# AliasMate v2 - Docker Installation Script for Testing
# Simple installation script optimized for testing in Docker environments

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
AM_DIR="/usr/local/bin/aliasmate"
CONFIG_DIR="/etc/aliasmate"
USER_CONFIG_DIR="/root/.config/aliasmate"
DATA_DIR="/root/.local/share/aliasmate"

echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  AliasMate v2 Docker Test Setup        │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# Function to install from source (current directory)
install_from_source() {
    echo -e "\n${CYAN}Setting up AliasMate for testing...${NC}"
    
    # Create necessary directories
    mkdir -p "$AM_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$USER_CONFIG_DIR"
    mkdir -p "$DATA_DIR/categories"
    mkdir -p "$DATA_DIR/stats"
    
    # Make scripts executable
    echo -e "${CYAN}Making scripts executable...${NC}"
    find "./src" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Create main executable
    echo -e "${CYAN}Creating main executable...${NC}"
    cat > "$INSTALL_DIR/aliasmate" << 'EOF'
#!/usr/bin/env bash
# AliasMate Docker test wrapper

cd /usr/local/bin/aliasmate
source ./main.sh "$@"
EOF
    chmod +x "$INSTALL_DIR/aliasmate"
    
    # Copy source files
    echo -e "${CYAN}Copying source files...${NC}"
    cp -r ./src/* "$AM_DIR/"
    
    # Copy core directory if it exists
    if [ -d "./src/core" ]; then
        mkdir -p "$AM_DIR/core"
        cp -r ./src/core/* "$AM_DIR/core/"
    fi
    
    # Create basic config
    cat > "$USER_CONFIG_DIR/config.yaml" << EOF
COMMAND_STORE: $DATA_DIR
LOG_FILE: $USER_CONFIG_DIR/aliasmate.log
LOG_LEVEL: debug
EDITOR: vi
VERSION_CHECK: false
THEME: default
EOF
    
    # Create symlink for easy access
    ln -sf "$INSTALL_DIR/aliasmate" /usr/bin/aliasmate
    
    echo -e "${GREEN}Test setup complete!${NC}"
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
    
    echo -e "\n${GREEN}AliasMate is ready for testing!${NC}"
    echo -e "Run: ${YELLOW}aliasmate --help${NC} to verify installation"
}

# Run main function
main
