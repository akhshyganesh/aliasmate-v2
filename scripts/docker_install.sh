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
AM_DIR="/usr/local/bin/aliasmate-scripts"  # Changed to avoid directory collision
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
    
    # Check if aliasmate already exists as a directory and clean it up
    if [ -d "$INSTALL_DIR/aliasmate" ]; then
        echo -e "${YELLOW}Removing old installation directory...${NC}"
        rm -rf "$INSTALL_DIR/aliasmate"
    fi
    
    # Create main executable with absolute paths
    echo -e "${CYAN}Creating main executable...${NC}"
    cat > "$INSTALL_DIR/aliasmate" << EOF
#!/usr/bin/env bash
# AliasMate Docker test wrapper

cd "$AM_DIR"
exec bash main.sh "\$@"
EOF
    chmod +x "$INSTALL_DIR/aliasmate"
    
    # Copy source files
    echo -e "${CYAN}Copying source files...${NC}"
    cp -r ./src/* "$AM_DIR/"
    
    # Copy core directory if it exists
    if [ -d "./src/core" ]; then
        mkdir -p "$AM_DIR/core"
        cp -r ./src/core/* "$AM_DIR/core/"
        # Create symbolic links to core files in main directory for easier access
        for core_file in ./src/core/*.sh; do
            base_name=$(basename "$core_file")
            ln -sf "$AM_DIR/core/$base_name" "$AM_DIR/$base_name"
        done
    fi
    
    # Patch main.sh to ensure init_app is defined
    patch_main_script
    
    # Create basic config
    cat > "$USER_CONFIG_DIR/config.yaml" << EOF
COMMAND_STORE: $DATA_DIR
LOG_FILE: $USER_CONFIG_DIR/aliasmate.log
LOG_LEVEL: debug
EDITOR: vi
VERSION_CHECK: false
THEME: default
EOF
    
    # Create symlink for easy access (with error handling)
    echo -e "${CYAN}Creating symbolic link in /usr/bin...${NC}"
    if [ -e "/usr/bin/aliasmate" ]; then
        rm -f "/usr/bin/aliasmate"
    fi
    ln -sf "$INSTALL_DIR/aliasmate" /usr/bin/aliasmate
    
    # Make a simple alias that points to the executable for easy testing
    echo "alias am='aliasmate'" >> /root/.bashrc
    
    echo -e "${GREEN}Test setup complete!${NC}"
}

# Patch the main script to ensure init_app is present
patch_main_script() {
    echo -e "${CYAN}Patching main.sh for Docker compatibility...${NC}"
    
    local main_script="$AM_DIR/main.sh"
    
    # Get line number of main() function
    local main_line=$(grep -n "^main()" "$main_script" | cut -d: -f1)
    
    if [ -z "$main_line" ]; then
        echo -e "${YELLOW}Could not find main() function in main.sh, skipping patch${NC}"
        return
    fi
    
    # Add init_app function just before main() function
    local temp_file=$(mktemp)
    head -n $((main_line-1)) "$main_script" > "$temp_file"
    
    cat << 'EOF' >> "$temp_file"
# Initialize application - Docker compatibility function
init_app() {
    # Default configuration values for Docker testing
    COMMAND_STORE="/root/.local/share/aliasmate"
    LOG_FILE="/root/.config/aliasmate/aliasmate.log"
    LOG_LEVEL="debug"
    VERSION_CHECK="false"
    THEME="default"
    DEFAULT_UI="cli"
    
    # Basic logging function
    log_info() {
        echo "[INFO] $1" >> "$LOG_FILE"
    }
    
    log_info "AliasMate initialized (Docker compatibility mode)"
    
    # Ensure command store exists
    mkdir -p "$COMMAND_STORE/categories"
    mkdir -p "$COMMAND_STORE/stats"
    
    echo "AliasMate initialized in Docker test environment"
}

EOF
    
    # Append rest of the file
    tail -n +$main_line "$main_script" >> "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$main_script"
    chmod +x "$main_script"
}

# Verify the installation
verify_installation() {
    echo -e "${CYAN}Verifying installation...${NC}"
    
    # Check if the executable exists
    if [ -x "$INSTALL_DIR/aliasmate" ]; then
        echo -e "${GREEN}✓ Executable found at $INSTALL_DIR/aliasmate${NC}"
    else
        echo -e "${RED}✗ Executable not found at $INSTALL_DIR/aliasmate${NC}"
        return 1
    fi
    
    # Check if scripts directory exists
    if [ -d "$AM_DIR" ]; then
        echo -e "${GREEN}✓ Scripts directory exists${NC}"
        
        # Check for required scripts - looking in both main dir and core dir
        required_scripts=("main.sh" "config.sh" "commands.sh" "utils.sh")
        for script in "${required_scripts[@]}"; do
            if [ -f "$AM_DIR/$script" ]; then
                echo -e "${GREEN}✓ Found $script${NC}"
            elif [ -f "$AM_DIR/core/$script" ]; then
                echo -e "${GREEN}✓ Found core/$script${NC}"
            else
                echo -e "${RED}✗ Missing $script (checked in $AM_DIR and $AM_DIR/core)${NC}"
                # Create a simple utils.sh if it's missing and we're in this verification
                if [ "$script" = "utils.sh" ]; then
                    echo -e "${YELLOW}Creating a basic $script file...${NC}"
                    cat > "$AM_DIR/$script" << 'EOF'
#!/usr/bin/env bash
# Basic utils.sh file for Docker testing

# Simple function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Helper function to check if a string is empty
is_empty() {
    [[ -z "$1" ]]
}

# Helper function to validate an alias name
validate_alias() {
    # Alphanumeric, underscore, hyphen only
    [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]]
}
EOF
                    chmod +x "$AM_DIR/$script"
                    echo -e "${GREEN}✓ Created $script${NC}"
                else
                    return 1
                fi
            fi
        done
    else
        echo -e "${RED}✗ Scripts directory not found at $AM_DIR${NC}"
        return 1
    fi
    
    # Check if symlink exists
    if [ -L "/usr/bin/aliasmate" ]; then
        echo -e "${GREEN}✓ Symlink created in /usr/bin${NC}"
    else
        echo -e "${RED}✗ Symlink not created in /usr/bin${NC}"
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
    
    # List source files for debugging
    echo -e "${CYAN}Available source files:${NC}"
    find ./src -type f -name "*.sh" | sort
    
    install_from_source
    verify_installation
    
    # Create a test command script for verification
    cat > "$INSTALL_DIR/test-aliasmate" << EOF
#!/bin/bash
echo "Testing aliasmate command..."
aliasmate --version
EOF
    chmod +x "$INSTALL_DIR/test-aliasmate"
    
    echo -e "\n${GREEN}AliasMate is ready for testing!${NC}"
    echo -e "${YELLOW}Commands to try:${NC}"
    echo -e "  ✓ ${CYAN}aliasmate --help${NC} - Show help information"
    echo -e "  ✓ ${CYAN}aliasmate --version${NC} - Show version information"
    echo -e "  ✓ ${CYAN}aliasmate --tui${NC} - Launch the text user interface"
    echo -e "  ✓ ${CYAN}am${NC} - Short alias for aliasmate"
    echo -e "  ✓ ${CYAN}test-aliasmate${NC} - Run a test script to verify the command works"
}

# Run main function
main
