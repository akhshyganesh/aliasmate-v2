#!/usr/bin/env bash
# AliasMate v2 - Configuration module

# Default configuration values
DEFAULT_CONFIG=(
    "COMMAND_STORE=$HOME/.local/share/aliasmate"
    "LOG_FILE=/tmp/aliasmate.log"
    "LOG_LEVEL=info"
    "VERSION_CHECK=true"
    "EDITOR=nano"
    "DEFAULT_UI=cli"
    "THEME=default"
    "ENABLE_STATS=true"
    "SYNC_ENABLED=false"
    "SYNC_PROVIDER="
    "SYNC_INTERVAL=3600"
)

# Global configuration file
GLOBAL_CONFIG_FILE="/etc/aliasmate/config.yaml"

# User configuration file
USER_CONFIG_FILE="$HOME/.config/aliasmate/config.yaml"

# Function to load configuration
load_config() {
    # First, set default values
    for config_line in "${DEFAULT_CONFIG[@]}"; do
        eval "$config_line"
    done
    
    # Then load from global config file if it exists
    if [[ -f "$GLOBAL_CONFIG_FILE" ]]; then
        parse_config_file "$GLOBAL_CONFIG_FILE"
    fi
    
    # Finally, load from user config file (which overrides global)
    if [[ -f "$USER_CONFIG_FILE" ]]; then
        parse_config_file "$USER_CONFIG_FILE"
    fi
    
    # Ensure the command store directory exists
    mkdir -p "$COMMAND_STORE"
    mkdir -p "$COMMAND_STORE/categories"
    mkdir -p "$COMMAND_STORE/stats"
}

# Parse a YAML-like config file
parse_config_file() {
    local file="$1"
    
    while IFS=': ' read -r key value; do
        # Skip comments and empty lines
        if [[ -n "$key" && ! "$key" =~ ^[[:space:]]*# && -n "$value" ]]; then
            # Remove leading/trailing whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Only set if value is not empty
            if [[ -n "$value" ]]; then
                eval "$key=\"$value\""
            fi
        fi
    done < "$file"
}

# Function to get a configuration value
get_config() {
    local key="$1"
    
    # Check if the key exists
    if [[ -z "$key" ]]; then
        echo -e "${RED}Error: Missing configuration key${NC}"
        return 1
    fi
    
    # Get the value
    local value="${!key}"
    
    if [[ -z "$value" ]]; then
        echo -e "${YELLOW}Warning: Configuration key '$key' not found${NC}"
        return 1
    fi
    
    echo "$value"
}

# Function to set a configuration value
set_config() {
    local key="$1"
    local value="$2"
    
    # Validate input
    if [[ -z "$key" || -z "$value" ]]; then
        echo -e "${RED}Error: Both key and value are required${NC}"
        return 1
    fi
    
    # Check if the key is a valid configuration option
    local valid_key=false
    for config_line in "${DEFAULT_CONFIG[@]}"; do
        local default_key="${config_line%%=*}"
        if [[ "$key" == "$default_key" ]]; then
            valid_key=true
            break
        fi
    done
    
    if [[ "$valid_key" == "false" ]]; then
        echo -e "${YELLOW}Warning: '$key' is not a standard configuration option${NC}"
        # Continue anyway, as we allow custom config options
    fi
    
    # Update the user configuration file
    mkdir -p "$(dirname "$USER_CONFIG_FILE")"
    
    if [[ ! -f "$USER_CONFIG_FILE" ]]; then
        # Create a new file with header
        echo "# AliasMate v2 Configuration" > "$USER_CONFIG_FILE"
        echo "# Modified: $(date)" >> "$USER_CONFIG_FILE"
        echo "" >> "$USER_CONFIG_FILE"
    fi
    
    # Check if the key already exists in the file
    if grep -q "^$key:" "$USER_CONFIG_FILE"; then
        # Update existing key
        sed -i.bak "s|^$key:.*|$key: $value|" "$USER_CONFIG_FILE"
        rm -f "${USER_CONFIG_FILE}.bak"
    else
        # Add new key
        echo "$key: $value" >> "$USER_CONFIG_FILE"
    fi
    
    # Update current session
    eval "$key=\"$value\""
    
    echo -e "${GREEN}Configuration updated: $key = $value${NC}"
    return 0
}

# Function to list all configuration
list_config() {
    echo -e "${CYAN}Current AliasMate Configuration:${NC}"
    echo -e "${CYAN}================================${NC}"
    
    # Get the max key length for alignment
    local max_length=0
    for config_line in "${DEFAULT_CONFIG[@]}"; do
        local key="${config_line%%=*}"
        if (( ${#key} > max_length )); then
            max_length=${#key}
        fi
    done
    
    # Print each configuration value
    for config_line in "${DEFAULT_CONFIG[@]}"; do
        local key="${config_line%%=*}"
        local value="${!key}"
        
        # Format the output with proper padding
        printf "${YELLOW}%-${max_length}s${NC} : %s\n" "$key" "$value"
    done
    
    echo -e "${CYAN}================================${NC}"
    echo -e "${BLUE}Configuration files:${NC}"
    echo -e "Global: ${GLOBAL_CONFIG_FILE}"
    echo -e "User  : ${USER_CONFIG_FILE}"
}

# Function to reset configuration to defaults
reset_config() {
    local confirm="$1"
    
    if [[ "$confirm" != "--force" ]]; then
        echo -e "${YELLOW}Warning: This will reset all user configurations to defaults.${NC}"
        read -p "Are you sure you want to continue? (y/n): " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            return 1
        fi
    fi
    
    # Remove the user config file
    if [[ -f "$USER_CONFIG_FILE" ]]; then
        rm -f "$USER_CONFIG_FILE"
        echo -e "${GREEN}User configuration reset to defaults.${NC}"
    else
        echo -e "${YELLOW}No user configuration file found.${NC}"
    fi
    
    # Reload configuration
    load_config
    
    return 0
}

# Main config command handler
manage_config() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        "get")
            get_config "$1"
            ;;
        "set")
            set_config "$1" "$2"
            ;;
        "list"|"")
            list_config
            ;;
        "reset")
            reset_config "$1"
            ;;
        *)
            echo -e "${RED}Error: Unknown config subcommand '$subcommand'${NC}"
            echo "Valid subcommands: get, set, list, reset"
            return 1
            ;;
    esac
}
