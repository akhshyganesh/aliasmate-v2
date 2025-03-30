#!/usr/bin/env bash
# AliasMate v2 - Build Script

set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.1.0-dev")
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"
SRC_DIR="$ROOT_DIR/src"
COMPLETIONS_DIR="$BUILD_DIR/completions"

# Print banner
echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│       AliasMate v2 Build Script        │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
echo -e "${CYAN}Building version: $VERSION${NC}"

# Function to verify build dependencies
verify_dependencies() {
    echo -e "\n${CYAN}Verifying build dependencies...${NC}"
    
    local deps=("shellcheck")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    # Optional dependency: fpm for package creation
    if ! command -v fpm &> /dev/null; then
        echo -e "${YELLOW}Note: 'fpm' is not installed. Package creation will be skipped.${NC}"
        echo -e "To install fpm: gem install fpm"
        # Don't add to missing, it's optional
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
        echo -e "Please install missing dependencies and try again."
        echo -e "  - shellcheck: Used for code quality checks"
        exit 1
    else
        echo -e "${GREEN}All required build dependencies are met!${NC}"
    fi
}

# Function to run tests
run_tests() {
    echo -e "\n${CYAN}Running tests...${NC}"
    
    # Run shellcheck
    echo -e "${YELLOW}Running shellcheck...${NC}"
    find "$SRC_DIR" -type f -name "*.sh" -exec shellcheck -x {} \; || {
        echo -e "${RED}Shellcheck failed. Please fix the issues and try again.${NC}"
        exit 1
    }
    
    # Run unit tests if available
    if [[ -f "$SCRIPT_DIR/run_tests.sh" ]]; then
        echo -e "${YELLOW}Running unit tests...${NC}"
        bash "$SCRIPT_DIR/run_tests.sh" || {
            echo -e "${RED}Unit tests failed. Please fix the issues and try again.${NC}"
            exit 1
        }
    fi
    
    echo -e "${GREEN}All tests passed!${NC}"
}

# Function to prepare the build directory
prepare_build() {
    echo -e "\n${CYAN}Preparing build directory...${NC}"
    
    # Clean previous build artifacts
    rm -rf "$BUILD_DIR" "$DIST_DIR"
    mkdir -p "$BUILD_DIR/usr/local/bin"
    mkdir -p "$BUILD_DIR/etc/aliasmate"
    mkdir -p "$BUILD_DIR/usr/share/doc/aliasmate"
    mkdir -p "$BUILD_DIR/usr/share/bash-completion/completions"
    mkdir -p "$BUILD_DIR/usr/share/zsh/site-functions"
    mkdir -p "$COMPLETIONS_DIR"
    mkdir -p "$DIST_DIR"
    
    # Copy source files
    cp -r "$SRC_DIR"/* "$BUILD_DIR/usr/local/bin/"
    
    # Make scripts executable
    find "$BUILD_DIR/usr/local/bin" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Create main executable
    cat > "$BUILD_DIR/usr/local/bin/aliasmate" << 'EOF'
#!/usr/bin/env bash
# AliasMate v2 - Main entry point

# Find the real installation directory
if [[ -L "$0" ]]; then
    # Follow symlink to get the real path
    REAL_PATH=$(readlink -f "$0" 2>/dev/null || readlink "$0" 2>/dev/null || echo "$0")
    INSTALL_DIR=$(dirname "$REAL_PATH")
else
    INSTALL_DIR=$(dirname "$0")
fi

# Check if we're in Docker for testing
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    export ALIASMATE_IN_DOCKER=true
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

    chmod +x "$BUILD_DIR/usr/local/bin/aliasmate"
    
    # Copy configuration
    mkdir -p "$BUILD_DIR/etc/aliasmate"
    cp "$ROOT_DIR/config/config.yaml" "$BUILD_DIR/etc/aliasmate/"
    
    # Copy documentation
    cp "$ROOT_DIR/README.md" "$BUILD_DIR/usr/share/doc/aliasmate/"
    cp "$ROOT_DIR/LICENSE" "$BUILD_DIR/usr/share/doc/aliasmate/"
    
    # Create directories for command storage
    mkdir -p "$BUILD_DIR/var/lib/aliasmate/categories"
    mkdir -p "$BUILD_DIR/var/lib/aliasmate/stats"
    
    # Generate completion scripts
    echo -e "${CYAN}Generating shell completion scripts...${NC}"
    source "$SRC_DIR/core/utils.sh"
    
    generate_completion bash > "$BUILD_DIR/usr/share/bash-completion/completions/aliasmate"
    generate_completion zsh > "$BUILD_DIR/usr/share/zsh/site-functions/_aliasmate"
    
    # Copy completion scripts to a directory for the installer
    cp "$BUILD_DIR/usr/share/bash-completion/completions/aliasmate" "$COMPLETIONS_DIR/aliasmate.bash"
    cp "$BUILD_DIR/usr/share/zsh/site-functions/_aliasmate" "$COMPLETIONS_DIR/aliasmate.zsh"
    
    echo -e "${GREEN}Build directory prepared successfully!${NC}"
}

# Function to create distribution packages
create_packages() {
    echo -e "\n${CYAN}Creating distribution packages...${NC}"
    
    if ! command -v fpm &> /dev/null; then
        echo -e "${YELLOW}Skipping package creation - fpm not installed${NC}"
        return 0
    fi
    
    # Create tar.gz archive
    echo -e "${YELLOW}Creating tarball...${NC}"
    tar -czf "$DIST_DIR/aliasmate-$VERSION.tar.gz" -C "$BUILD_DIR" .
    
    # Create DEB package
    echo -e "${YELLOW}Creating DEB package...${NC}"
    fpm -s dir -t deb -n aliasmate -v "${VERSION#v}" \
        --description "AliasMate - Command Alias Manager" \
        --url "https://github.com/akhshyganesh/aliasmate-v2" \
        --license "MIT" \
        --maintainer "akhshyganesh" \
        --vendor "akhshyganesh" \
        --depends "bash" \
        --depends "jq" \
        -C "$BUILD_DIR" \
        -p "$DIST_DIR/aliasmate-$VERSION.deb" \
        .
    
    # Create RPM package
    echo -e "${YELLOW}Creating RPM package...${NC}"
    fpm -s dir -t rpm -n aliasmate -v "${VERSION#v}" \
        --description "AliasMate - Command Alias Manager" \
        --url "https://github.com/akhshyganesh/aliasmate-v2" \
        --license "MIT" \
        --maintainer "akhshyganesh" \
        --vendor "akhshyganesh" \
        --depends "bash" \
        --depends "jq" \
        -C "$BUILD_DIR" \
        -p "$DIST_DIR/aliasmate-$VERSION.rpm" \
        .
    
    echo -e "${GREEN}Packages created in $DIST_DIR${NC}"
    ls -lh "$DIST_DIR"
}

# Main function
main() {
    # Verify dependencies
    verify_dependencies
    
    # Run tests
    run_tests
    
    # Prepare build directory
    prepare_build
    
    # Create distribution packages
    create_packages
    
    echo -e "\n${GREEN}Build completed successfully!${NC}"
}

# Call main function
main "$@"
