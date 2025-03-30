#!/usr/bin/env bash
# AliasMate v2 - Utility functions

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Prompt for confirmation
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Generate a unique ID
generate_id() {
    local prefix="${1:-cmd}"
    echo "${prefix}_$(date +%s)_$(openssl rand -hex 4)"
}

# Validate an alias name
validate_alias() {
    local alias_name="$1"
    
    if [[ -z "$alias_name" ]]; then
        print_error "Alias name cannot be empty"
        return 1
    fi
    
    if [[ "$alias_name" =~ [^a-zA-Z0-9_-] ]]; then
        print_error "Alias name can only contain letters, numbers, underscore and hyphen"
        return 1
    fi
    
    if [[ "${#alias_name}" -gt 50 ]]; then
        print_error "Alias name is too long (max 50 characters)"
        return 1
    fi
    
    return 0
}

# Check for updates
check_for_updates() {
    # Skip if version check is disabled
    if [[ "$VERSION_CHECK" != "true" ]]; then
        return 0
    fi
    
    # Skip update check if we've checked recently
    local cache_file="$HOME/.cache/aliasmate/update_check"
    local cache_dir=$(dirname "$cache_file")
    mkdir -p "$cache_dir"
    
    # Check if the cache file exists and is less than a day old
    if [[ -f "$cache_file" ]] && (( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file") < 86400 )); then
        # Use cached result
        local cached_version=$(cat "$cache_file")
        
        # Compare with current version
        if [[ "$cached_version" != "$VERSION" ]] && [[ "$cached_version" != "error" ]]; then
            print_info "A new version is available: $cached_version (current: $VERSION)"
            print_info "Run 'aliasmate --upgrade' to update"
        fi
        
        return 0
    fi
    
    # Check for a new version in the background
    (
        # Get the latest version from GitHub
        if command_exists curl; then
            latest_version=$(curl -s --max-time 3 "https://api.github.com/repos/akhshyganesh/aliasmate-v2/releases/latest" | 
                             grep -o '"tag_name": *"[^"]*"' | 
                             grep -o '[^"]*$' | 
                             sed 's/^v//')
        elif command_exists wget; then
            latest_version=$(wget -qO- --timeout=3 "https://api.github.com/repos/akhshyganesh/aliasmate-v2/releases/latest" | 
                             grep -o '"tag_name": *"[^"]*"' | 
                             grep -o '[^"]*$' | 
                             sed 's/^v//')
        else
            # No tools to check for updates
            echo "error" > "$cache_file"
            return 0
        fi
        
        # Cache the result
        if [[ -n "$latest_version" ]] && [[ "$latest_version" != "null" ]]; then
            echo "$latest_version" > "$cache_file"
        else
            echo "error" > "$cache_file"
        fi
    ) &
}

# Update AliasMate
update_aliasmate() {
    print_info "Checking for updates..."
    
    # Download the installer script
    local temp_dir=$(mktemp -d)
    local installer_script="$temp_dir/install.sh"
    
    if command_exists curl; then
        curl -sSL "https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh" -o "$installer_script"
    elif command_exists wget; then
        wget -q "https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh" -O "$installer_script"
    else
        print_error "Neither curl nor wget is available to download updates"
        return 1
    fi
    
    # Make the installer executable
    chmod +x "$installer_script"
    
    # Run the installer
    print_info "Running installer..."
    bash "$installer_script"
    
    # Clean up
    rm -rf "$temp_dir"
    
    print_info "Update complete!"
}

# Show a spinner for long-running commands
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Format data as a table
format_table() {
    local header=("$@")
    local separator="|"
    local num_columns=${#header[@]}
    local column_widths=()
    
    # Calculate column widths
    for ((i=0; i<num_columns; i++)); do
        column_widths+=("${#header[$i]}")
    done
    
    # Read data and update column widths
    local rows=()
    while IFS= read -r line; do
        rows+=("$line")
        
        # Split the line by separator
        IFS="$separator" read -ra cells <<< "$line"
        
        # Update column widths
        for ((i=0; i<num_columns && i<${#cells[@]}; i++)); do
            if (( ${#cells[$i]} > ${column_widths[$i]} )); then
                column_widths[$i]=${#cells[$i]}
            fi
        done
    done
    
    # Print header
    for ((i=0; i<num_columns; i++)); do
        printf "%-$((${column_widths[$i]}+2))s" "${header[$i]}"
        if (( i < num_columns - 1 )); then
            printf "| "
        fi
    done
    echo
    
    # Print separator line
    for ((i=0; i<num_columns; i++)); do
        printf "%s" "$(printf '=%.0s' $(seq 1 $((${column_widths[$i]}+2))))"
        if (( i < num_columns - 1 )); then
            printf "| "
        fi
    done
    echo
    
    # Print rows
    for row in "${rows[@]}"; do
        IFS="$separator" read -ra cells <<< "$row"
        
        for ((i=0; i<num_columns && i<${#cells[@]}; i++)); do
            printf "%-$((${column_widths[$i]}+2))s" "${cells[$i]}"
            if (( i < num_columns - 1 )); then
                printf "| "
            fi
        done
        echo
    done
}

# Generate shell completion script
generate_completion() {
    local shell="$1"
    
    case "$shell" in
        bash)
            cat << 'EOF'
# AliasMate v2 bash completion

_aliasmate_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    opts="save run edit ls list search stats rm remove categories export import config sync --help -h --version -v --tui --update --upgrade --completion"
    
    # Handle different completion contexts
    case "$prev" in
        aliasmate)
            COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
            return 0
            ;;
        run|edit|rm|remove)
            # Complete with available aliases
            local aliases=$(aliasmate ls --format=names 2>/dev/null)
            COMPREPLY=( $(compgen -W "${aliases}" -- "${cur}") )
            return 0
            ;;
        --category)
            # Complete with available categories
            local categories=$(aliasmate categories --format=names 2>/dev/null)
            COMPREPLY=( $(compgen -W "${categories}" -- "${cur}") )
            return 0
            ;;
        --path)
            # Complete with directories
            COMPREPLY=( $(compgen -d -- "${cur}") )
            return 0
            ;;
        --completion)
            COMPREPLY=( $(compgen -W "bash zsh" -- "${cur}") )
            return 0
            ;;
        save|ls|list|search|stats|categories|export|import|config|sync)
            # Handle subcommands
            local subopts=""
            case "$prev" in
                save)
                    subopts="--multi --category"
                    ;;
                ls|list)
                    subopts="--category --sort --format"
                    ;;
                search)
                    subopts="--category --command --path"
                    ;;
                stats)
                    subopts="--reset --export"
                    ;;
                categories)
                    subopts="add rm list"
                    ;;
                export)
                    subopts="--format"
                    ;;
                import)
                    subopts="--merge"
                    ;;
                config)
                    subopts="get set list reset"
                    ;;
                sync)
                    subopts="setup push pull status"
                    ;;
            esac
            COMPREPLY=( $(compgen -W "${subopts}" -- "${cur}") )
            return 0
            ;;
    esac
    
    # Default to file completion
    return 0
}

complete -F _aliasmate_completion aliasmate
EOF
            ;;
        zsh)
            cat << 'EOF'
#compdef aliasmate

_aliasmate() {
    local -a commands
    commands=(
        'save:Save a command with an alias'
        'run:Run a saved command'
        'edit:Edit a command'
        'ls:List all commands'
        'list:List all commands'
        'search:Search for commands'
        'stats:Show command usage statistics'
        'rm:Remove a command'
        'remove:Remove a command'
        'categories:Manage categories'
        'export:Export commands'
        'import:Import commands'
        'config:Manage configuration'
        'sync:Synchronize with cloud'
    )

    local -a options
    options=(
        '--help[Show help message]'
        '-h[Show help message]'
        '--version[Show version information]'
        '-v[Show version information]'
        '--tui[Launch the Text User Interface]'
        '--update[Update AliasMate]'
        '--upgrade[Update AliasMate]'
        '--completion[Generate shell completion scripts]:shell:(bash zsh)'
    )

    _arguments -C \
        "1: :{_describe 'command' commands}" \
        "*::arg:->args" \
        "${options[@]}"

    case $state in
        args)
            case $line[1] in
                save)
                    _arguments \
                        '--multi[Create a multi-line command]' \
                        '--category[Assign a category]:category:($(_aliasmate_categories))'
                    ;;
                run)
                    _arguments \
                        '1:alias:($(_aliasmate_aliases))' \
                        '--path[Run in a specific path]:directory:_directories' \
                        '--args[Additional arguments]'
                    ;;
                edit)
                    _arguments \
                        '1:alias:($(_aliasmate_aliases))' \
                        '--cmd[Edit only the command]' \
                        '--path[Edit only the path]' \
                        '--category[Edit the category]:category:($(_aliasmate_categories))'
                    ;;
                ls|list)
                    _arguments \
                        '--category[Filter by category]:category:($(_aliasmate_categories))' \
                        '--sort[Sort results]:field:(name path usage)' \
                        '--format[Output format]:format:(table json csv names)'
                    ;;
                search)
                    _arguments \
                        '1:term' \
                        '--category[Filter by category]:category:($(_aliasmate_categories))' \
                        '--command[Search in commands]' \
                        '--path[Search in paths]'
                    ;;
                stats)
                    _arguments \
                        '--reset[Reset statistics]' \
                        '--export[Export statistics]:file:_files'
                    ;;
                rm|remove)
                    _arguments \
                        '1:alias:($(_aliasmate_aliases))'
                    ;;
                categories)
                    local -a subcmds
                    subcmds=(
                        'add:Add a new category'
                        'rm:Remove a category'
                        'list:List categories'
                    )
                    _arguments \
                        "1: :{_describe 'subcommand' subcmds}"
                    ;;
                export)
                    _arguments \
                        '::alias:($(_aliasmate_aliases))' \
                        '--format[Export format]:format:(json yaml csv)'
                    ;;
                import)
                    _arguments \
                        '1:file:_files' \
                        '--merge[Merge with existing commands]'
                    ;;
                config)
                    local -a subcmds
                    subcmds=(
                        'get:Get a configuration value'
                        'set:Set a configuration value'
                        'list:List all configuration'
                        'reset:Reset configuration to defaults'
                    )
                    _arguments \
                        "1: :{_describe 'subcommand' subcmds}"
                    ;;
                sync)
                    local -a subcmds
                    subcmds=(
                        'setup:Configure cloud synchronization'
                        'push:Push to cloud'
                        'pull:Pull from cloud'
                        'status:Check sync status'
                    )
                    _arguments \
                        "1: :{_describe 'subcommand' subcmds}"
                    ;;
            esac
            ;;
    esac
}

_aliasmate_aliases() {
    local -a aliases
    aliases=(${(f)"$(aliasmate ls --format=names 2>/dev/null)"})
    _values 'aliases' $aliases
}

_aliasmate_categories() {
    local -a categories
    categories=(${(f)"$(aliasmate categories --format=names 2>/dev/null)"})
    _values 'categories' $categories
}

compdef _aliasmate aliasmate
EOF
            ;;
        *)
            print_error "Unsupported shell: $shell"
            print_info "Supported shells: bash, zsh"
            return 1
            ;;
    esac
}
