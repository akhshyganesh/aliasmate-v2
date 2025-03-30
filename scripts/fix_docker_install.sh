#!/usr/bin/env bash
# AliasMate v2 - Docker Installation Fixer
# This script attempts to fix common issues with Docker installations

set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  AliasMate v2 Docker Install Fixer     │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# Define base directories
INSTALL_DIR="/usr/local/bin"
AM_DIR="/usr/local/bin/aliasmate"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Try running with: sudo $0"
    exit 1
fi

echo -e "${CYAN}Checking for installation issues...${NC}"

# Create directories if they don't exist
mkdir -p "$AM_DIR"
mkdir -p "/root/.config/aliasmate"
mkdir -p "/root/.local/share/aliasmate/categories"
mkdir -p "/root/.local/share/aliasmate/stats"

# Fix main executable
echo -e "${CYAN}Creating new main executable...${NC}"
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

# Change to the install directory so relative paths work
cd "$INSTALL_DIR"

# Source the main script
if [[ -f "$INSTALL_DIR/main.sh" ]]; then
    source "$INSTALL_DIR/main.sh" "$@"
else
    echo "Error: AliasMate main.sh not found"
    echo "Expected location: $INSTALL_DIR/main.sh"
    ls -la "$INSTALL_DIR"
    exit 1
fi
EOF
chmod +x "$INSTALL_DIR/aliasmate"

# Create a basic configuration
echo -e "${CYAN}Creating basic configuration...${NC}"
cat > "/root/.config/aliasmate/config.yaml" << EOF
COMMAND_STORE: /root/.local/share/aliasmate
LOG_FILE: /root/.config/aliasmate/aliasmate.log
LOG_LEVEL: info
EDITOR: vi
VERSION_CHECK: false
THEME: default
EOF

echo -e "${CYAN}Downloading latest source code...${NC}"
cd /tmp
rm -rf aliasmate-v2
git clone https://github.com/akhshyganesh/aliasmate-v2.git
cd aliasmate-v2

echo -e "${CYAN}Copying source files...${NC}"
cp -r src/* "$AM_DIR/"
chmod +x "$AM_DIR/"*.sh

if [ -d "src/core" ]; then
    mkdir -p "$AM_DIR/core"
    cp -r src/core/* "$AM_DIR/core/"
    chmod +x "$AM_DIR/core/"*.sh
fi

echo -e "${CYAN}Creating symbolic link...${NC}"
ln -sf "$INSTALL_DIR/aliasmate" /usr/bin/aliasmate

echo -e "${GREEN}Repair completed!${NC}"
echo -e "Try running: aliasmate --help"
