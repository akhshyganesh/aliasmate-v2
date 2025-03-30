#!/usr/bin/env bash
# AliasMate v2 - Main entry point

set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Set version
VERSION="2.0.0"

# Source modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/commands.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/tui.sh"
source "$SCRIPT_DIR/categories.sh"
source "$SCRIPT_DIR/search.sh"
source "$SCRIPT_DIR/sync.sh"
source "$SCRIPT_DIR/stats.sh"

# Load configuration
load_config

# Check for updates (if enabled)
if [[ "$VERSION_CHECK" == "true" ]]; then
    check_for_updates
fi

# Initialize command store if it doesn't exist
if [[ ! -d "$COMMAND_STORE" ]]; then
    mkdir -p "$COMMAND_STORE"
    mkdir -p "$COMMAND_STORE/categories"
    mkdir -p "$COMMAND_STORE/stats"
fi

# Print application header
print_header() {
    echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│       AliasMate v2 - Version $VERSION       │${NC}"
    echo -e "${BLUE}└────────────────────────────────────────┘${NC}"
}

# Print help message
show_help() {
    print_header
    cat << EOF

${BOLD}USAGE:${NC}
  aliasmate [OPTIONS] COMMAND [ARGUMENTS]

${BOLD}OPTIONS:${NC}
  --help, -h              Show this help message and exit
  --version, -v           Show version information
  --tui                   Launch the Text User Interface
  --update, --upgrade     Update AliasMate to the latest version
  --completion <shell>    Generate shell completion scripts

${BOLD}COMMANDS:${NC}
  save <alias> <command>  Save a command with an alias name
       <alias> --multi    Save a multi-line command using editor
       <alias> --category <category>  Save with a category
  
  run <alias>             Run a saved command
       [--path <path>]    Run in specified path (instead of default)
       [--args <args>]    Pass additional arguments to the command
  
  edit <alias>            Edit both command and path for an alias
       [--cmd]            Edit only the command
       [--path]           Edit only the default path
       [--category]       Edit the category
  
  ls, list                List all saved aliases with details
       [--category <cat>] List aliases in a specific category
       [--sort <field>]   Sort by name, path, or usage
  
  search <term>           Search for aliases by name or command content
  
  stats                   Show command usage statistics
       [--reset]          Reset usage statistics
  
  rm, remove <alias>      Remove a specific alias
  
  categories              List available categories
       add <name>         Add a new category
       rm <name>          Remove a category
  
  export [alias]          Export all aliases (or specific one)
       [--format json]    Export in JSON format
  
  import <file>           Import aliases from a file
       [--merge]          Merge with existing aliases
  
  config                  Show current configuration
       get <key>          Get a configuration value
       set <key> <value>  Set a configuration value
  
  sync                    Synchronize aliases with cloud storage
       setup              Configure cloud synchronization
       push               Push aliases to cloud
       pull               Pull aliases from cloud

For more details, visit: https://github.com/akhshyganesh/aliasmate-v2
EOF
}

# Main entry point to handle commands
main() {
    # No arguments, show TUI or help
    if [[ $# -eq 0 ]]; then
        if [[ "$DEFAULT_UI" == "tui" ]]; then
            launch_tui
        else
            show_help
        fi
        exit 0
    fi
    
    # Parse command line arguments
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
            
        --version|-v)
            echo "AliasMate v$VERSION"
            exit 0
            ;;
            
        --tui)
            launch_tui
            exit 0
            ;;
            
        --completion)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: Missing shell type (bash or zsh)${NC}"
                exit 1
            fi
            generate_completion "$2"
            exit 0
            ;;
            
        --update|--upgrade)
            update_aliasmate
            exit 0
            ;;
            
        save)
            shift
            save_command "$@"
            ;;
            
        run)
            shift
            run_command "$@"
            ;;
            
        edit)
            shift
            edit_command "$@"
            ;;
            
        ls|list)
            shift
            list_commands "$@"
            ;;
            
        search)
            shift
            search_commands "$@"
            ;;
            
        stats)
            shift
            show_stats "$@"
            ;;
            
        rm|remove)
            shift
            remove_command "$@"
            ;;
            
        categories)
            shift
            manage_categories "$@"
            ;;
            
        export)
            shift
            export_commands "$@"
            ;;
            
        import)
            shift
            import_commands "$@"
            ;;
            
        config)
            shift
            manage_config "$@"
            ;;
            
        sync)
            shift
            sync_commands "$@"
            ;;
            
        *)
            echo -e "${RED}Error: Unknown command '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Execute the main function
main "$@"
