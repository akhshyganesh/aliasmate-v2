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
source "$SCRIPT_DIR/ui_components.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/tui.sh"
source "$SCRIPT_DIR/categories.sh"
source "$SCRIPT_DIR/search.sh"
source "$SCRIPT_DIR/sync.sh"
source "$SCRIPT_DIR/stats.sh"
source "$SCRIPT_DIR/batch.sh"

# Load configuration
load_config

# Check for updates (if enabled)
if [[ "$VERSION_CHECK" == "true" ]]; then
    # Run update check in background for better startup performance
    check_for_updates &
fi

# Initialize command store if it doesn't exist
if [[ ! -d "$COMMAND_STORE" ]]; then
    mkdir -p "$COMMAND_STORE"
    mkdir -p "$COMMAND_STORE/categories"
    mkdir -p "$COMMAND_STORE/stats"
fi

# Initialize cache for better performance
init_cache

# Print application header
print_header() {
    echo -e "${BLUE}┌───────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│       AliasMate v$VERSION - Command Manager       │${NC}"
    echo -e "${BLUE}└───────────────────────────────────────────────┘${NC}"
}

# Print detailed help message
show_help() {
    print_header
    cat << EOF

${BOLD}USAGE:${NC}
  aliasmate [OPTIONS] COMMAND [ARGUMENTS]

${BOLD}OPTIONS:${NC}
  --help, -h              Show this help message and exit
  --version, -v           Show version information
  --tui                   Launch the Text User Interface (recommended for beginners)
  --update, --upgrade     Update AliasMate to the latest version
  --completion <shell>    Generate shell completion scripts (bash/zsh)
  --no-color              Disable colored output
  --quiet, -q             Suppress non-error output

${BOLD}COMMANDS:${NC}
  ${CYAN}Command Management:${NC}
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
    
    rm, remove <alias>      Remove a specific alias
  
  ${CYAN}Listing and Search:${NC}
    ls, list                List all saved aliases with details
         [--category <cat>] List aliases in a specific category
         [--sort <field>]   Sort by name, path, usage, last_run
         [--format <fmt>]   Output format: table, json, csv, names
    
    search <term>           Search for aliases by name or command content
           [--category <c>] Search in a specific category
           [--command]      Search only in command content
           [--path]         Search only in paths
           [--alias]        Search only in alias names
  
  ${CYAN}Organization:${NC}
    categories              List available categories
         add <name>         Add a new category
         rm <name>          Remove a category
         rename <old> <new> Rename a category
    
    tags <alias>            List tags for a command (experimental)
         add <alias> <tag>  Add a tag to a command
         rm <alias> <tag>   Remove a tag from a command
  
  ${CYAN}Data Management:${NC}
    export [alias]          Export all aliases (or specific one)
           [--format <fmt>] Export in format: json, yaml, csv
           [--output <file>] Specify output file
    
    import <file>           Import aliases from a file
           [--merge]        Merge with existing aliases
    
    stats                   Show command usage statistics
         [--reset]          Reset usage statistics
         [--export <file>]  Export statistics to file
  
  ${CYAN}Batch Operations:${NC}
    batch import <dir>      Batch import multiple command files
          edit <pattern>    Edit multiple commands matching a pattern
          run <pattern>     Run multiple commands matching a pattern
  
  ${CYAN}Configuration:${NC}
    config                  Show current configuration
         get <key>          Get a configuration value
         set <key> <value>  Set a configuration value
         reset              Reset configuration to defaults
    
    sync                    Synchronize aliases with cloud storage
         setup              Configure cloud synchronization
         push               Push aliases to cloud
         pull               Pull aliases from cloud
         status             Check sync status

${BOLD}EXAMPLES:${NC}
  aliasmate save build-app "npm run build"
  aliasmate run build-app
  aliasmate ls --category development
  aliasmate search "database"
  aliasmate sync setup --provider github

${BOLD}DOCUMENTATION:${NC}
  For complete documentation, visit:
  https://github.com/akhshyganesh/aliasmate-v2/docs

EOF
}

# Show a condensed help for quick reference
show_quick_help() {
    echo -e "${CYAN}AliasMate v$VERSION Quick Reference:${NC}"
    echo -e " - ${YELLOW}save <alias> <cmd>${NC}: Save a command"
    echo -e " - ${YELLOW}run <alias>${NC}: Run a command"
    echo -e " - ${YELLOW}ls${NC}: List all commands"
    echo -e " - ${YELLOW}search <term>${NC}: Search commands"
    echo -e " - ${YELLOW}--tui${NC}: Launch interactive interface"
    echo -e "Use ${YELLOW}aliasmate --help${NC} for full documentation"
}

# Main entry point to handle commands
main() {
    # Start with basic initialization
    init_app
    
    # No arguments, show TUI or help
    if [[ $# -eq 0 ]]; then
        if [[ "$DEFAULT_UI" == "tui" ]]; then
            launch_tui
        else
            show_quick_help
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
                print_error "Missing shell type (bash or zsh)"
                exit 1
            fi
            generate_completion "$2"
            exit 0
            ;;
            
        --update|--upgrade)
            update_aliasmate
            exit 0
            ;;
            
        --no-color)
            # Disable colors for this session
            RED=''
            GREEN=''
            YELLOW=''
            BLUE=''
            CYAN=''
            BOLD=''
            NC=''
            shift
            ;;
            
        --quiet|-q)
            # Redirect stdout to null for non-error output
            exec 1>/dev/null
            shift
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
            
        tags)
            shift
            manage_tags "$@"
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
            
        batch)
            shift
            handle_batch "$@"
            ;;
            
        *)
            # Check if this is a saved command alias that the user wants to run
            if [[ -f "$COMMAND_STORE/$1.json" ]]; then
                local alias_to_run="$1"
                shift
                run_command "$alias_to_run" "$@"
            else
                print_error "Unknown command '$1'"
                show_quick_help
                exit 1
            fi
            ;;
    esac
}

# Execute the main function
main "$@"
