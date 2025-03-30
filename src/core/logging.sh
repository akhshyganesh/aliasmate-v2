#!/usr/bin/env bash
# AliasMate v2 - Logging module

# Define log levels
declare -A LOG_LEVELS=( 
    ["debug"]=0
    ["info"]=1
    ["warning"]=2
    ["error"]=3
    ["fatal"]=4
)

# Initialize logging
init_logging() {
    # Create log directory if it doesn't exist
    local log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir"
    
    # Initialize log file with header
    echo "# AliasMate v2 Log - Started $(date)" > "$LOG_FILE"
    echo "# Version: $VERSION" >> "$LOG_FILE"
    echo "# Log level: $LOG_LEVEL" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    log_debug "Logging initialized"
}

# Log a message if its level is >= the configured level
log_message() {
    local level="$1"
    local message="$2"
    
    # Skip if level is below the configured level
    if (( ${LOG_LEVELS[$level]} < ${LOG_LEVELS[$LOG_LEVEL]} )); then
        return 0
    fi
    
    # Format the timestamp
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Write to log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Convenience functions for different log levels
log_debug() {
    log_message "debug" "$1"
}

log_info() {
    log_message "info" "$1"
}

log_warning() {
    log_message "warning" "$1"
}

log_error() {
    log_message "error" "$1"
}

log_fatal() {
    log_message "fatal" "$1"
    # Exit the program on fatal errors
    exit 1
}

# Print colored output to the console
print_debug() {
    echo -e "${CYAN}Debug: $1${NC}"
    log_debug "$1"
}

print_info() {
    echo -e "${GREEN}$1${NC}"
    log_info "$1"
}

print_warning() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
    log_warning "$1"
}

print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
    log_error "$1"
}

print_fatal() {
    echo -e "${RED}Fatal Error: $1${NC}" >&2
    log_fatal "$1"
}

# Show log file contents
show_logs() {
    local lines="${1:-50}"
    
    if [[ ! -f "$LOG_FILE" ]]; then
        print_error "Log file does not exist: $LOG_FILE"
        return 1
    fi
    
    echo -e "${CYAN}Last $lines lines of the log file:${NC}"
    echo -e "${CYAN}=================================${NC}"
    
    tail -n "$lines" "$LOG_FILE"
    
    echo -e "${CYAN}=================================${NC}"
    echo -e "Full log file: $LOG_FILE"
}

# Clear the log file
clear_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        # Backup old log
        cp "$LOG_FILE" "${LOG_FILE}.bak"
        
        # Create new log file
        init_logging
        
        print_info "Log file cleared (backup saved as ${LOG_FILE}.bak)"
    else
        print_warning "Log file does not exist: $LOG_FILE"
    fi
}
