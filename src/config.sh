#!/usr/bin/env bash
# AliasMate v2 - Main config loader

# Source core modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core/config.sh"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/utils.sh"

# Load colors for the terminal
load_colors() {
    # Define colors for terminal output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
    
    # Check if we're in a terminal that supports colors
    if [[ -t 1 && "${TERM}" != "dumb" ]]; then
        # Terminal supports colors
        USE_COLORS=true
    else
        # Disable colors for non-interactive or dumb terminals
        USE_COLORS=false
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
        MAGENTA=''
        BOLD=''
        NC=''
    fi
    
    # Apply theme customizations if specified
    if [[ "$THEME" != "default" && -n "$THEME" ]]; then
        apply_theme "$THEME"
    fi
}

# Apply a color theme
apply_theme() {
    local theme="$1"
    
    case "$theme" in
        dark)
            # Dark theme with bright colors
            RED='\033[1;31m'
            GREEN='\033[1;32m'
            YELLOW='\033[1;33m'
            BLUE='\033[1;34m'
            CYAN='\033[1;36m'
            MAGENTA='\033[1;35m'
            ;;
        light)
            # Light theme with more subtle colors
            RED='\033[0;31m'
            GREEN='\033[0;32m'
            YELLOW='\033[0;33m'
            BLUE='\033[0;34m'
            CYAN='\033[0;36m'
            MAGENTA='\033[0;35m'
            ;;
        minimal)
            # Minimal theme with fewer colors
            RED='\033[0;31m'
            GREEN='\033[0;32m'
            YELLOW='\033[0;33m'
            BLUE=''
            CYAN=''
            MAGENTA=''
            BOLD='\033[1m'
            ;;
        *)
            # Unknown theme, log a warning
            log_warning "Unknown theme: $theme, using default"
            ;;
    esac
}

# Export print_success function for use in other modules
print_success() {
    echo -e "${GREEN}${1}${NC}"
    log_info "$1"
}

# Initialize everything
init_app() {
    # Load configuration
    load_config
    
    # Set up colors
    load_colors
    
    # Initialize logging
    init_logging
    
    log_info "AliasMate v2 initialized"
}
