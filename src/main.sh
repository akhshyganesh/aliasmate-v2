#!/usr/bin/env bash
# AliasMate v2 - Main entry point

# Set error handling
set -o pipefail

# Define version
VERSION="0.2.0"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Initialize variables
USE_COLORS=true
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if we're in a Docker test environment
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo -e "${YELLOW}Running AliasMate in Docker test environment${NC}"
    echo -e "${YELLOW}Note: This is for testing purposes only, some features may be limited${NC}"
    export ALIASMATE_IN_DOCKER=true
fi

# Source dependencies
source "$SCRIPT_DIR/core/config.sh"
source "$SCRIPT_DIR/core/logging.sh"
source "$SCRIPT_DIR/core/utils.sh"
source "$SCRIPT_DIR/commands.sh"

# Load configuration
load_config

# Function to print the help message
print_help() {
    cat << EOF
${BOLD}NAME${NC}
    aliasmate - Command Alias Manager v$VERSION

${BOLD}SYNOPSIS${NC}
    aliasmate <command> [options]

${BOLD}DESCRIPTION${NC}
    AliasMate is a powerful command alias manager for Linux and macOS.
    Store, organize, and execute your commonly used commands with ease.

${BOLD}COMMANDS:${NC}

  ${CYAN}Basic Usage:${NC}
    save <alias> <command>  Save a command with an alias
         [--multi]         Edit the command in multi-line mode
         [--category <cat>] Assign to a category
  
    run <alias>            Run a saved command
        [--path <dir>]     Run in specified directory
        [--args <args>]    Pass additional arguments
  
    edit <alias>           Edit a saved command
         [--path]          Edit only the path
  
    ls, list [pattern]     List all saved commands
         [--category <cat>] Filter by category
         [--format <fmt>]  Output format: table, json, csv, names
         [--sort <field>]  Sort by: name, runs, last_run
  
    rm, remove <alias>     Remove a saved command
         [--force]         Remove without confirmation
  
  ${CYAN}Search & Discovery:${NC}
    search <query>         Search for commands
           [--category]    Filter by category
           [--command]     Search only in command content
           [--path]        Search only in paths
           [--alias]       Search only in alias names
  
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

  ${CYAN}System & Updates:${NC}
    completion [shell]      Generate shell completion script
    --upgrade               Check for updates and upgrade
    --version               Show version information
    --help                  Show this help message

${BOLD}EXAMPLES:${NC}
  aliasmate save build-app "npm run build"
  aliasmate run build-app
  aliasmate ls --category development
  aliasmate search "database"

${BOLD}DOCUMENTATION:${NC}
  For complete documentation, visit:
  https://github.com/akhshyganesh/aliasmate-v2/docs

EOF
}

# Main function
main() {
    # No arguments provided
    if [[ $# -eq 0 ]]; then
        print_help
        exit 0
    fi
    
    # Process command line arguments
    local command="$1"
    shift
    
    # Check for updates (unless disabled)
    check_update
    
    # Process commands
    case "$command" in
        # Help and version info
        --help|-h)
            print_help
            ;;
        --version|-v)
            echo "AliasMate v$VERSION"
            ;;
        --upgrade)
            update_aliasmate
            ;;
        # Command management
        save)
            save_command "$@"
            ;;
        run)
            run_command "$@"
            ;;
        edit)
            edit_command "$@"
            ;;
        ls|list)
            list_commands "$@"
            ;;
        rm|remove)
            remove_command "$@"
            ;;
        # Search
        search)
            search_commands "$@"
            ;;
        # Categories
        categories)
            manage_categories "$@"
            ;;
        # Tags
        tags)
            manage_tags "$@"
            ;;
        # Import/Export
        export)
            export_commands "$@"
            ;;
        import)
            import_commands "$@"
            ;;
        # Statistics
        stats)
            show_stats "$@"
            ;;
        # Config management
        config)
            manage_config "$@"
            ;;
        # Batch operations
        batch)
            batch_operations "$@"
            ;;
        # Sync
        sync)
            sync_commands "$@"
            ;;
        # Shell completion
        completion)
            shell=${1:-bash}
            generate_completion "$shell"
            ;;
        # Advanced features
        --tui)
            launch_tui "$@"
            ;;
        # Unknown command
        *)
            print_error "Unknown command: $command"
            echo "Run 'aliasmate --help' for usage information."
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
