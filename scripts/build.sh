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

# Print banner
echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│       AliasMate v2 Build Script        │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
echo -e "${CYAN}Building version: $VERSION${NC}"

# Function to verify build dependencies
verify_dependencies() {
    echo -e "\n${CYAN}Verifying build dependencies...${NC}"
    
    local deps=("shellcheck" "fpm")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Missing build dependencies: ${missing[*]}${NC}"
        
        # Install missing dependencies
        if command -v apt-get &> /dev/null; then
            echo -e "${YELLOW}Installing dependencies with apt...${NC}"
            sudo apt-get update
            
            # Install shellcheck if needed
            if [[ " ${missing[@]} " =~ " shellcheck " ]]; then
                sudo apt-get install -y shellcheck
            fi
            
            # Install fpm if needed
            if [[ " ${missing[@]} " =~ " fpm " ]]; then
                sudo apt-get install -y ruby ruby-dev rubygems build-essential
                sudo gem install --no-document fpm
            fi
        else
            echo -e "${RED}Error: Automatic dependency installation only supported on Debian/Ubuntu.${NC}"
            echo "Please install the following dependencies manually: ${missing[*]}"
            exit 1
        fi
    else
        echo -e "${GREEN}All build dependencies are met!${NC}"
    fi
}

# Function to run tests
run_tests() {
    echo -e "\n${CYAN}Running tests...${NC}"
    
    # Run shellcheck
    echo -e "${YELLOW}Running shellcheck...${NC}"
    find "$SRC_DIR" -type f -name "*.sh" -exec shellcheck -x {} \;
    
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
    mkdir -p "$DIST_DIR"
    
    # Copy source files
    cp -r "$SRC_DIR"/* "$BUILD_DIR/usr/local/bin/"
    
    # Make scripts executable
    find "$BUILD_DIR/usr/local/bin" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Create main executable
    cat > "$BUILD_DIR/usr/local/bin/aliasmate" << 'EOF'
#!/bin/bash
exec /usr/local/bin/main.sh "$@"
EOF
    chmod +x "$BUILD_DIR/usr/local/bin/aliasmate"
    
    # Copy configuration
    cp "$ROOT_DIR/config/config.yaml" "$BUILD_DIR/etc/aliasmate/"
    
    # Copy documentation
    cp "$ROOT_DIR/README.md" "$BUILD_DIR/usr/share/doc/aliasmate/"
    cp "$ROOT_DIR/LICENSE" "$BUILD_DIR/usr/share/doc/aliasmate/"
    cp -r "$ROOT_DIR/docs" "$BUILD_DIR/usr/share/doc/aliasmate/"
    
    echo -e "${GREEN}Build directory prepared!${NC}"
}

# Function to build packages
build_packages() {
    echo -e "\n${CYAN}Building packages...${NC}"
    
    # Clean version string for filenames
    local clean_version="${VERSION#v}"
    
    # Build .deb package
    echo -e "${YELLOW}Building .deb package...${NC}"
    fpm -s dir -t deb \
        -n "aliasmate" \
        -v "$clean_version" \
        --description "A powerful command alias manager with path tracking" \
        --maintainer "Akhshy Ganesh <akhshy.balakannan@gmail.com>" \
        --url "https://github.com/akhshyganesh/aliasmate-v2" \
        --license "MIT" \
        --category "utils" \
        --depends "bash" \
        --depends "jq" \
        --depends "curl" \
        --deb-no-default-config-files \
        -p "$DIST_DIR/aliasmate_${clean_version}_amd64.deb" \
        -C "$BUILD_DIR" \
        .
    
    # Build .rpm package
    echo -e "${YELLOW}Building .rpm package...${NC}"
    fpm -s dir -t rpm \
        -n "aliasmate" \
        -v "$clean_version" \
        --description "A powerful command alias manager with path tracking" \
        --maintainer "Akhshy Ganesh <akhshy.balakannan@gmail.com>" \
        --url "https://github.com/akhshyganesh/aliasmate-v2" \
        --license "MIT" \
        --category "System Environment/Shells" \
        --depends "bash" \
        --depends "jq" \
        --depends "curl" \
        -p "$DIST_DIR/aliasmate-${clean_version}.x86_64.rpm" \
        -C "$BUILD_DIR" \
        .
    
    # Build .tar.gz archive
    echo -e "${YELLOW}Building .tar.gz archive...${NC}"
    tar -czf "$DIST_DIR/aliasmate-${clean_version}.tar.gz" -C "$BUILD_DIR" .
    
    echo -e "${GREEN}All packages built successfully!${NC}"
    ls -l "$DIST_DIR"
}

# Main function
main() {
    verify_dependencies
    run_tests
    prepare_build
    build_packages
    
    echo -e "\n${GREEN}┌────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│      Build completed successfully!      │${NC}"
    echo -e "${GREEN}└────────────────────────────────────────┘${NC}"
    echo -e "${YELLOW}Packages are available in:${NC} $DIST_DIR"
}

# Execute the main function
main
