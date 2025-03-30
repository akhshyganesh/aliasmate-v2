#!/usr/bin/env bash
# Quick fix for the init_app issue in Docker

set -e

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Fixing init_app issue in Docker installation...${NC}"

# Path to main.sh
MAIN_SCRIPT="/usr/local/bin/aliasmate-scripts/main.sh"

if [ ! -f "$MAIN_SCRIPT" ]; then
    echo -e "${YELLOW}Main script not found at $MAIN_SCRIPT${NC}"
    echo "Please make sure AliasMate is installed correctly."
    exit 1
fi

# Create a backup
cp "$MAIN_SCRIPT" "$MAIN_SCRIPT.bak"
echo -e "${CYAN}Created backup at $MAIN_SCRIPT.bak${NC}"

# Get line number of main() function
MAIN_LINE=$(grep -n "^main()" "$MAIN_SCRIPT" | cut -d: -f1)

if [ -z "$MAIN_LINE" ]; then
    echo -e "${YELLOW}Could not find main() function in $MAIN_SCRIPT${NC}"
    echo "Adding init_app function at the beginning of the file."
    
    # Add to the beginning
    TMP_FILE=$(mktemp)
    
    cat << 'EOF' > "$TMP_FILE"
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
    
    cat "$MAIN_SCRIPT" >> "$TMP_FILE"
    mv "$TMP_FILE" "$MAIN_SCRIPT"
else
    # Add init_app function just before main() function
    echo -e "${CYAN}Adding init_app function before main() at line $MAIN_LINE${NC}"
    
    TMP_FILE=$(mktemp)
    head -n $((MAIN_LINE-1)) "$MAIN_SCRIPT" > "$TMP_FILE"
    
    cat << 'EOF' >> "$TMP_FILE"
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
    
    tail -n +$MAIN_LINE "$MAIN_SCRIPT" >> "$TMP_FILE"
    mv "$TMP_FILE" "$MAIN_SCRIPT"
fi

chmod +x "$MAIN_SCRIPT"

echo -e "${GREEN}Fix applied successfully!${NC}"
echo -e "Try running ${YELLOW}aliasmate --help${NC} again."
