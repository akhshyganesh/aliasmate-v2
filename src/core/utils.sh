#!/usr/bin/env bash
# AliasMate v2 - Core utilities

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Validate an alias name
validate_alias() {
    local alias_name="$1"
    
    # Check if alias is empty
    if [[ -z "$alias_name" ]]; then
        print_error "Alias name cannot be empty"
        return 1
    fi
    
    # Check length
    if [[ ${#alias_name} -gt 50 ]]; then
        print_error "Alias name too long (max 50 characters)"
        return 1
    fi
    
    # Check format (only allow letters, numbers, underscore and hyphen)
    if ! [[ "$alias_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid alias name: $alias_name"
        print_info "Alias names can only contain letters, numbers, underscore and hyphen"
        return 1
    fi
    
    return 0
}

# Generate a unique ID
generate_id() {
    local prefix="${1:-}"
    local id
    
    if [[ -n "$prefix" ]]; then
        id="${prefix}_$(date +%s%N | sha256sum | head -c 8)"
    else
        id="$(date +%s%N | sha256sum | head -c 16)"
    fi
    
    echo "$id"
}

# Confirm action with user
confirm() {
    local prompt="$1"
    local default="${2:-y}"
    
    local options
    if [[ "$default" == "y" ]]; then
        options="[Y/n]"
    else
        options="[y/N]"
    fi
    
    local answer
    read -p "$prompt $options " answer
    
    # Default when Enter is pressed without any input
    if [[ -z "$answer" ]]; then
        answer="$default"
    fi
    
    # Convert to lowercase
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
        return 0
    else
        return 1
    fi
}

# URL encode a string
urlencode() {
    local string="$1"
    local length="${#string}"
    local i c
    
    for (( i = 0; i < length; i++ )); do
        c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) printf "%s" "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

# Parse command line arguments
parse_args() {
    local -n args=$1
    local -n options=$2
    shift 2
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --*)
                local key="${1:2}"
                if [[ "$2" == --* || -z "$2" ]]; then
                    options["$key"]=true
                else
                    options["$key"]="$2"
                    shift
                fi
                ;;
            -*)
                local key="${1:1}"
                if [[ "$2" == -* || -z "$2" ]]; then
                    options["$key"]=true
                else
                    options["$key"]="$2"
                    shift
                fi
                ;;
            *)
                args+=("$1")
                ;;
        esac
        shift
    done
}

# Format JSON or YAML data for display
format_data() {
    local data="$1"
    local format="${2:-json}"
    
    case "$format" in
        json)
            if command_exists jq; then
                echo "$data" | jq .
            else
                echo "$data"
            fi
            ;;
        yaml)
            if command_exists yq; then
                echo "$data" | yq eval -P
            else
                print_error "YAML formatting requires 'yq' tool. Please install it."
                echo "$data"
            fi
            ;;
        *)
            echo "$data"
            ;;
    esac
}

# Format duration in seconds to human readable
format_duration() {
    local seconds="$1"
    local days hours minutes
    
    # If seconds is less than 1, show milliseconds
    if (( $(echo "$seconds < 1" | bc -l) )); then
        echo "$(echo "$seconds * 1000" | bc | cut -d. -f1)ms"
        return
    fi
    
    days=$((seconds / 86400))
    seconds=$((seconds % 86400))
    hours=$((seconds / 3600))
    seconds=$((seconds % 3600))
    minutes=$((seconds / 60))
    seconds=$((seconds % 60))
    
    local result=""
    if [[ $days -gt 0 ]]; then
        result+="$days days "
    fi
    if [[ $hours -gt 0 ]]; then
        result+="$hours hours "
    fi
    if [[ $minutes -gt 0 ]]; then
        result+="$minutes minutes "
    fi
    result+="$seconds seconds"
    
    echo "$result"
}

# Format timestamp to human readable date
format_timestamp() {
    local timestamp="$1"
    local format="${2:-%Y-%m-%d %H:%M:%S}"
    
    # Check if we have a valid timestamp
    if [[ -z "$timestamp" || "$timestamp" == "null" ]]; then
        echo "Never"
        return
    fi
    
    # Try different date commands for compatibility
    date -d "@$timestamp" +"$format" 2>/dev/null || 
    date -r "$timestamp" +"$format" 2>/dev/null || 
    echo "Unknown date format"
}

# Check for updates to aliasmate
check_update() {
    # Skip update check if disabled
    if [[ "$VERSION_CHECK" != "true" ]]; then
        return 0
    fi
    
    # Don't check for updates if we've already checked recently
    local update_check_file="/tmp/aliasmate_update_check"
    if [[ -f "$update_check_file" ]]; then
        local check_time=$(cat "$update_check_file")
        local current_time=$(date +%s)
        local diff=$((current_time - check_time))
        
        # Only check once per day (86400 seconds)
        if [[ $diff -lt 86400 ]]; then
            return 0
        fi
    fi
    
    # Log the update check time
    date +%s > "$update_check_file"
    
    # Fetch the latest version
    local latest_version=""
    if command_exists curl; then
        latest_version=$(curl -s https://api.github.com/repos/akhshyganesh/aliasmate-v2/releases/latest | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$' 2>/dev/null)
    elif command_exists wget; then
        latest_version=$(wget -qO- https://api.github.com/repos/akhshyganesh/aliasmate-v2/releases/latest | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$' 2>/dev/null)
    fi
    
    # Strip 'v' prefix if present
    latest_version="${latest_version#v}"
    current_version="${VERSION#v}"
    
    # Compare versions
    if [[ -n "$latest_version" && "$latest_version" != "$current_version" ]]; then
        if [[ "$USE_COLORS" == "true" ]]; then
            echo -e "${YELLOW}A new version of AliasMate is available: $latest_version (current: $current_version)${NC}"
            echo -e "${YELLOW}Run 'aliasmate --upgrade' to update${NC}"
        else
            echo "A new version of AliasMate is available: $latest_version (current: $current_version)"
            echo "Run 'aliasmate --upgrade' to update"
        fi
    fi
    
    return 0
}

# Update aliasmate to the latest version
update_aliasmate() {
    print_info "Checking for updates..."
    
    # Check if we can download the update script
    if command_exists curl; then
        curl -sSL https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash -s -- --upgrade
    elif command_exists wget; then
        wget -qO- https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash -s -- --upgrade
    else
        print_error "Update requires curl or wget to be installed"
        return 1
    fi
    
    return 0
}

# Parse YAML configuration file - improved version
parse_yaml() {
    local file="$1"
    local prefix="${2:-}"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # Remove comments and empty lines
    sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' "$file" |
    # Extract key-value pairs
    while read -r line; do
        # Skip lines that don't look like key-value pairs
        if ! [[ "$line" =~ ^[a-zA-Z0-9_]+:.* ]]; then
            continue
        fi
        
        # Extract key and value
        local key=$(echo "$line" | cut -d: -f1 | sed -e 's/[[:space:]]*$//')
        local value=$(echo "$line" | cut -d: -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Handle quoted values
        if [[ "$value" =~ ^\".*\"$ ]]; then
            value="${value#\"}"
            value="${value%\"}"
        elif [[ "$value" =~ ^\'.*\'$ ]]; then
            value="${value#\'}"
            value="${value%\'}"
        fi
        
        # Set the value
        if [[ -n "$key" && -n "$value" ]]; then
            eval "$prefix$key='$value'"
        fi
    done
    
    return 0
}

# Generate shell completion scripts
generate_completion() {
    local shell="$1"
    
    case "$shell" in
        bash)
            cat << 'EOF'
# AliasMate bash completion script

_aliasmate_completion() {
    local cur prev words cword
    _init_completion || return

    # Define commands and options
    local commands="save run edit ls list search rm remove categories export import stats config sync batch --tui --help --version --upgrade"
    local options="--category --format --sort --output --merge --multi --path --args --force --reset"

    # Handle specific command options
    case "$prev" in
        save)
            # Return available categories for save command
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--multi --category" -- "$cur"))
                return
            fi
            # After the alias name, no completion
            local cmd_parts=${#words[@]}
            if [[ $cmd_parts -gt 2 ]]; then
                return
            fi
            ;;
        run|edit|rm|remove)
            # Return available commands
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--path --args --force" -- "$cur"))
                return
            fi
            if [[ "$cur" == * ]]; then
                local cmds=$(aliasmate ls --format names 2>/dev/null)
                COMPREPLY=($(compgen -W "$cmds" -- "$cur"))
                return
            fi
            ;;
        categories)
            # Subcommands for categories
            if [[ "$cur" == * ]]; then
                COMPREPLY=($(compgen -W "list add rm remove rename" -- "$cur"))
                return
            fi
            ;;
        search)
            # Search options
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--category --command --path --alias" -- "$cur"))
                return
            fi
            ;;
        --category)
            # Return available categories
            local cats=$(find "$HOME/.local/share/aliasmate/categories" -type f -exec basename {} \; 2>/dev/null)
            COMPREPLY=($(compgen -W "$cats" -- "$cur"))
            return
            ;;
        --format)
            # Return available formats
            COMPREPLY=($(compgen -W "json yaml csv table names" -- "$cur"))
            return
            ;;
        --sort)
            # Return available sort fields
            COMPREPLY=($(compgen -W "name alias path usage runs last_run" -- "$cur"))
            return
            ;;
        export|import)
            # Return export/import options
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--format --output --merge" -- "$cur"))
                return
            fi
            ;;
        ls|list)
            # Return listing options
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--category --format --sort" -- "$cur"))
                return
            fi
            ;;
        stats)
            # Return stats options
            if [[ "$cur" == --* ]]; then
                COMPREPLY=($(compgen -W "--reset --export" -- "$cur"))
                return
            fi
            ;;
        config)
            # Return config subcommands
            if [[ "$cur" == * ]]; then
                COMPREPLY=($(compgen -W "list get set reset" -- "$cur"))
                return
            fi
            ;;
        sync)
            # Return sync subcommands
            if [[ "$cur" == * ]]; then
                COMPREPLY=($(compgen -W "status setup push pull" -- "$cur"))
                return
            fi
            ;;
        batch)
            # Return batch subcommands
            if [[ "$cur" == * ]]; then
                COMPREPLY=($(compgen -W "import edit run" -- "$cur"))
                return
            fi
            ;;
    esac

    # Handle initial command completion
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--help --version --tui --upgrade --completion" -- "$cur"))
    else
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    fi
}

complete -F _aliasmate_completion aliasmate
EOF
            ;;
        zsh)
            cat << 'EOF'
#compdef aliasmate

_aliasmate_commands() {
    local -a commands
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
    _describe -t commands 'aliasmate commands' commands
}

_aliasmate_saved_commands() {
    local -a commands
    local cmds=$(aliasmate ls --format names 2>/dev/null)
    commands=(${(f)cmds})
    _describe -t commands 'saved commands' commands
}

_aliasmate_categories() {
    local -a categories
    local cats=$(find "$HOME/.local/share/aliasmate/categories" -type f -exec basename {} \; 2>/dev/null)
    categories=(${(f)cats})
    _describe -t categories 'categories' categories
}

_aliasmate() {
    local curcontext="$curcontext" state line
    typeset -A opt_args

    _arguments -C \
        '(-h --help)'{-h,--help}'[Show help information]' \
        '(-v --version)'{-v,--version}'[Show version information]' \
        '--tui[Launch the Text User Interface]' \
        '--upgrade[Update AliasMate to the latest version]' \
        '--completion[Generate shell completion]:shell:(bash zsh)' \
        '*:: :->args'

    case $state in
        args)
            case $words[1] in
                save)
                    _arguments \
                        '--multi[Edit as multi-line command]' \
                        '--category[Specify category]:category:_aliasmate_categories' \
                        '*:command args:'
                    ;;
                run|edit)
                    _arguments \
                        ':command:_aliasmate_saved_commands' \
                        '--path[Run in specified path]:path:_files -/' \
                        '--args[Pass arguments to command]:args:'
                    ;;
                rm|remove)
                    _arguments \
                        ':command:_aliasmate_saved_commands' \
                        '--force[Remove without confirmation]'
                    ;;
                ls|list)
                    _arguments \
                        '--category[Filter by category]:category:_aliasmate_categories' \
                        '--format[Output format]:format:(table json csv names)' \
                        '--sort[Sort by field]:field:(name alias path usage runs last_run)'
                    ;;
                search)
                    _arguments \
                        ':search term:' \
                        '--category[Filter by category]:category:_aliasmate_categories' \
                        '--command[Search in command content]' \
                        '--path[Search in command paths]' \
                        '--alias[Search in alias names]'
                    ;;
                categories)
                    _arguments \
                        ':action:(list add rm remove rename)' \
                        '*::category args:'
                    ;;
                export)
                    _arguments \
                        '::command:_aliasmate_saved_commands' \
                        '--format[Export format]:format:(json yaml csv)' \
                        '--output[Output file]:file:_files'
                    ;;
                import)
                    _arguments \
                        ':file:_files' \
                        '--merge[Merge with existing commands]'
                    ;;
                stats)
                    _arguments \
                        '--reset[Reset statistics]' \
                        '--export[Export statistics]:file:_files'
                    ;;
                config)
                    _arguments \
                        ':action:(list get set reset)' \
                        '*::config args:'
                    ;;
                sync)
                    _arguments \
                        ':action:(status setup push pull)'
                    ;;
                batch)
                    _arguments \
                        ':action:(import edit run)'
                    ;;
                *)
                    _aliasmate_commands
                    ;;
            esac
            ;;
    esac
}

_aliasmate "$@"
EOF
            ;;
        *)
            print_error "Unsupported shell type: $shell"
            print_info "Supported shells: bash, zsh"
            return 1
            ;;
    esac
    
    return 0
}

# Function to get command details for display
get_command_details() {
    local alias_name="$1"
    local command_file="$COMMAND_STORE/$alias_name.json"
    
    if [[ ! -f "$command_file" ]]; then
        print_error "Command not found: $alias_name"
        return 1
    fi
    
    # Get command details
    local command=$(jq -r '.command' "$command_file")
    local path=$(jq -r '.path' "$command_file")
    local category=$(jq -r '.category' "$command_file")
    local runs=$(jq -r '.runs' "$command_file")
    local created=$(jq -r '.created' "$command_file")
    local modified=$(jq -r '.modified' "$command_file")
    local last_run=$(jq -r '.last_run' "$command_file")
    local last_exit_code=$(jq -r '.last_exit_code' "$command_file")
    local last_duration=$(jq -r '.last_duration' "$command_file")
    
    # Format timestamps
    local created_fmt=$(format_timestamp "$created")
    local modified_fmt=$(format_timestamp "$modified")
    local last_run_fmt=$(format_timestamp "$last_run")
    
    # Format success/failure
    local status="Unknown"
    if [[ "$last_exit_code" == "null" ]]; then
        status="Never run"
    elif [[ "$last_exit_code" == "0" ]]; then
        status="Success"
    else
        status="Failed (exit code: $last_exit_code)"
    fi
    
    # Format duration
    local duration_fmt="N/A"
    if [[ "$last_duration" != "null" && -n "$last_duration" ]]; then
        duration_fmt="$(printf "%.2f" "$last_duration")s"
    fi
    
    # Print details
    echo "===== Command Details: $alias_name ====="
    echo
    echo "Command:"
    echo "  $command"
    echo
    echo "Category: $category"
    echo "Default Path: $path"
    echo
    echo "Stats:"
    echo "  Runs: $runs"
    echo "  Last Run: $last_run_fmt"
    echo "  Last Status: $status"
    echo "  Last Duration: $duration_fmt"
    echo
    echo "Metadata:"
    echo "  Created: $created_fmt"
    echo "  Modified: $modified_fmt"
    
    return 0
}
