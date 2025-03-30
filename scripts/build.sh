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
        echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
        echo -e "Please install missing dependencies and try again."
        echo -e "  - shellcheck: Used for code quality checks"
        echo -e "  - fpm: Used for package creation (gem install fpm)"
        exit 1
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
    mkdir -p "$BUILD_DIR/etc/aliasmate"
    cp "$ROOT_DIR/config/config.yaml" "$BUILD_DIR/etc/aliasmate/"
    
    # Copy documentation
    cp "$ROOT_DIR/README.md" "$BUILD_DIR/usr/share/doc/aliasmate/"
    cp "$ROOT_DIR/LICENSE" "$BUILD_DIR/usr/share/doc/aliasmate/"
    
    # Create directories for command storage
    mkdir -p "$BUILD_DIR/var/lib/aliasmate/categories"
    mkdir -p "$BUILD_DIR/var/lib/aliasmate/stats"
    
    # Create completion scripts directory
    mkdir -p "$BUILD_DIR/usr/share/bash-completion/completions"
    mkdir -p "$BUILD_DIR/usr/share/zsh/site-functions"
    
    # Generate completion scripts
    generate_bash_completion > "$BUILD_DIR/usr/share/bash-completion/completions/aliasmate"
    generate_zsh_completion > "$BUILD_DIR/usr/share/zsh/site-functions/_aliasmate"
    
    echo -e "${GREEN}Build directory prepared successfully!${NC}"
}

# Generate bash completion script
generate_bash_completion() {
    cat << 'EOF'
# Bash completion for AliasMate
_aliasmate() {
    local cur prev words cword
    _init_completion || return

    local commands="save run edit ls list search rm remove categories export import stats config sync batch --tui --help --version"

    case "$prev" in
        save|run|edit|rm|remove)
            # Complete with saved aliases
            COMPREPLY=($(compgen -W "$(find ~/.local/share/aliasmate -maxdepth 1 -name "*.json" -exec basename {} .json \; 2>/dev/null)" -- "$cur"))
            return
            ;;
        search)
            # No completion for search terms
            return
            ;;
        --category)
            # Complete with existing categories
            COMPREPLY=($(compgen -W "$(find ~/.local/share/aliasmate/categories -type f -exec basename {} \; 2>/dev/null)" -- "$cur"))
            return
            ;;
        --format)
            # Complete with available formats
            COMPREPLY=($(compgen -W "json csv yaml table names" -- "$cur"))
            return
            ;;
        categories)
            # Complete with category subcommands
            COMPREPLY=($(compgen -W "list add rm remove rename" -- "$cur"))
            return
            ;;
        config)
            # Complete with config subcommands
            COMPREPLY=($(compgen -W "list get set reset" -- "$cur"))
            return
            ;;
        sync)
            # Complete with sync subcommands
            COMPREPLY=($(compgen -W "setup push pull status" -- "$cur"))
            return
            ;;
        batch)
            # Complete with batch subcommands
            COMPREPLY=($(compgen -W "import edit run" -- "$cur"))
            return
            ;;
    esac

    # Complete with available commands or options
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--help --version --tui --upgrade" -- "$cur"))
    else
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    fi
} &&
complete -F _aliasmate aliasmate
EOF
}

# Generate zsh completion script
generate_zsh_completion() {
    cat << 'EOF'
#compdef aliasmate

_aliasmate() {
    local -a commands categories formats
    
    commands=(
        'save:Save a command with an alias'
        'run:Run a saved command'
        'edit:Edit a command'
        'ls:List all commands'
        'list:List all commands'
        'search:Search for commands'
        'rm:Remove a command'
        'remove:Remove a command'
        'categories:Manage categories'
        'export:Export commands'
        'import:Import commands'
        'stats:Show command statistics'
        'config:Manage configuration'
        'sync:Synchronize commands'
        'batch:Perform batch operations'
    )
    
    # Get categories
    if [[ -d ~/.local/share/aliasmate/categories ]]; then
        categories=($(find ~/.local/share/aliasmate/categories -type f -exec basename {} \; 2>/dev/null))
    fi
    
    formats=(
        'json:JSON format'
        'yaml:YAML format'
        'csv:CSV format'
        'table:Table format'
        'names:Just names'
    )
    
    _arguments -C \
        '(- *)--help[Show help information]' \
        '(- *)--version[Show version information]' \
        '(- *)--tui[Launch the Text User Interface]' \
        '(- *)--upgrade[Update to the latest version]' \
        '1: :->command' \
        '*:: :->args'
    
    case $state in
        command)
            _describe -t commands 'aliasmate commands' commands
            ;;
        args)
            case $words[1] in
                save)
                    _arguments \
                        '2:alias name:' \
                        '3:command:' \
                        '--multi[Edit as multi-line command]' \
                        '--category=[Specify category]:category:($categories)'
                    ;;
                run|edit|rm|remove)
                    local -a aliases
                    if [[ -d ~/.local/share/aliasmate ]]; then
                        aliases=($(find ~/.local/share/aliasmate -maxdepth 1 -name "*.json" -exec basename {} .json \; 2>/dev/null))
                    fi
                    _arguments \
                        '2:alias name:($aliases)' \
                        '*::options:'
                    ;;
                ls|list)
                    _arguments \
                        '--category=[Filter by category]:category:($categories)' \
                        '--format=[Output format]:format:($formats)' \
                        '--sort=[Sort field]:(name path usage last_run)'
                    ;;
                search)
                    _arguments \
                        '2:search term:' \
                        '--category=[Filter by category]:category:($categories)' \
                        '--command[Search in command content]' \
                        '--path[Search in paths]' \
                        '--alias[Search in alias names]'
                    ;;
                categories)
                    local -a subcmds
                    subcmds=(
                        'list:List all categories'
                        'add:Add a new category'
                        'rm:Remove a category'
                        'remove:Remove a category'
                        'rename:Rename a category'
                    )
                    _arguments \
                        '2: :->subcmd' \
                        '*:: :->subcmd_args'
                    
                    case $state in
                        subcmd)
                            _describe -t subcmds 'categories subcommands' subcmds
                            ;;
                        subcmd_args)
                            case $words[1] in
                                add)
                                    _arguments '2:new category name:'
                                    ;;
                                rm|remove)
                                    _arguments '2:category to remove:($categories)'
                                    ;;
                                rename)
                                    _arguments \
                                        '2:old category name:($categories)' \
                                        '3:new category name:'
                                    ;;
                            esac
                            ;;
                    esac
                    ;;
                # Add other commands here...
            esac
            ;;
    esac
}

_aliasmate "$@"
EOF
}

# Function to build packages
build_packages() {
    echo -e "\n${CYAN}Building packages...${NC}"
    
    # Create tarball
    echo -e "${YELLOW}Creating tarball...${NC}"
    tar -czf "$DIST_DIR/aliasmate-$VERSION.tar.gz" -C "$BUILD_DIR" .
    
    # Create DEB package
    echo -e "${YELLOW}Creating DEB package...${NC}"
    fpm -s dir -t deb -n aliasmate -v "$VERSION" \
        --description "AliasMate v2 - Command Alias Manager for the command line" \
        --url "https://github.com/akhshyganesh/aliasmate-v2" \
        --maintainer "Akhshy Ganesh <akhshyganeshb@gmail.com>" \
        --license "MIT" \
        --depends "jq" \
        --depends "bash" \
        --category "utils" \
        -C "$BUILD_DIR" \
        --deb-no-default-config-files \
        usr etc var
    
    # Create RPM package
    echo -e "${YELLOW}Creating RPM package...${NC}"
    fpm -s dir -t rpm -n aliasmate -v "$VERSION" \
        --description "AliasMate v2 - Command Alias Manager for the command line" \
        --url "https://github.com/akhshyganesh/aliasmate-v2" \
        --maintainer "Akhshy Ganesh <akhshyganeshb@gmail.com>" \
        --license "MIT" \
        --depends "jq" \
        --depends "bash" \
        -C "$BUILD_DIR" \
        usr etc var
    
    # Move packages to dist directory
    mv aliasmate*.deb "$DIST_DIR/"
    mv aliasmate*.rpm "$DIST_DIR/"
    
    echo -e "${GREEN}All packages built successfully!${NC}"
    ls -la "$DIST_DIR/"
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
    echo -e "Packages are available in ${YELLOW}$DIST_DIR/${NC}"
}

# Execute the main function
main
