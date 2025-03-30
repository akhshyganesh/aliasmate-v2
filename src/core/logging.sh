#!/usr/bin/env bash
# AliasMate v2 - Logging module

# Initialize logging system
init_logging() {
    # Create log directory if it doesn't exist
    local log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir"
    
    # Initialize log file with header
    echo "--- AliasMate v$VERSION Log Started at $(date) ---" >> "$LOG_FILE"
    
    # Log system info for debugging
    {
        echo "System: $(uname -a)"
        echo "Shell: $SHELL"
        echo "Terminal: $TERM"
        echo "Working directory: $(pwd)"
        echo "Command store: $COMMAND_STORE"
        echo "Configuration loaded from: ${CONFIG_FILES[*]}"
        echo "----------------------------------------"
    } >> "$LOG_FILE"
    
    log_info "Logging initialized at level: $LOG_LEVEL"
}

# Log a message at the specified level
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local caller="${FUNCNAME[2]:-main}"
    
    # Performance optimization - early return if log level is not enabled
    case "$level" in
        DEBUG)
            [[ "$LOG_LEVEL" != "debug" ]] && return 0
            ;;
        INFO)
            [[ "$LOG_LEVEL" != "debug" && "$LOG_LEVEL" != "info" ]] && return 0
            ;;
        WARNING)
            [[ "$LOG_LEVEL" == "error" || "$LOG_LEVEL" == "none" ]] && return 0
            ;;
        ERROR)
            [[ "$LOG_LEVEL" == "none" ]] && return 0
            ;;
    esac
    
    # Add log entry to log file
    echo "[$timestamp] [$level] [$caller] $message" >> "$LOG_FILE"
    
    # For error levels, also write to stderr if not in quiet mode
    if [[ "$level" == "ERROR" && -z "$ALIASMATE_QUIET" ]]; then
        echo "[$level] $message" >&2
    fi
}

# Debug level logging
log_debug() {
    log_message "DEBUG" "$1"
}

# Info level logging
log_info() {
    log_message "INFO" "$1"
}

# Warning level logging
log_warning() {
    log_message "WARNING" "$1"
}

# Error level logging
log_error() {
    log_message "ERROR" "$1"
}

# Print a warning message to the console
print_warning() {
    # Log to file
    log_warning "$1"
    
    # Print to console if not in quiet mode
    if [[ -z "$ALIASMATE_QUIET" ]]; then
        echo -e "${YELLOW}Warning: ${1}${NC}" >&2
    fi
}

# Print an error message to the console
print_error() {
    # Log to file
    log_error "$1"
    
    # Print to console if not in quiet mode
    if [[ -z "$ALIASMATE_QUIET" ]]; then
        echo -e "${RED}Error: ${1}${NC}" >&2
    fi
}

# Print an info message to the console
print_info() {
    # Log to file
    log_info "$1"
    
    # Print to console if not in quiet mode
    if [[ -z "$ALIASMATE_QUIET" ]]; then
        echo -e "${BLUE}${1}${NC}"
    fi
}

# Start timing for performance measurement
start_timing() {
    local operation="$1"
    
    # Only log timing if debug is enabled
    if [[ "$LOG_LEVEL" == "debug" ]]; then
        # Create a unique ID for this timing
        local timing_id=$(date +%s%N)
        
        # Store the operation name and start time
        TIMING_OPERATIONS["$timing_id"]="$operation"
        TIMING_STARTS["$timing_id"]=$(date +%s.%N)
        
        echo "$timing_id"
    else
        echo "0"
    fi
}

# End timing and log performance
end_timing() {
    local timing_id="$1"
    
    # Only log timing if debug is enabled and timing was started
    if [[ "$LOG_LEVEL" == "debug" && "$timing_id" != "0" && -n "${TIMING_OPERATIONS[$timing_id]}" ]]; then
        local operation="${TIMING_OPERATIONS[$timing_id]}"
        local start_time="${TIMING_STARTS[$timing_id]}"
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc)
        
        # Log the performance information
        log_debug "PERFORMANCE: $operation completed in ${duration}s"
        
        # Clean up
        unset TIMING_OPERATIONS["$timing_id"]
        unset TIMING_STARTS["$timing_id"]
        
        # Return the duration
        echo "$duration"
    else
        echo "0"
    fi
}

# Initialize timing maps
declare -A TIMING_OPERATIONS
declare -A TIMING_STARTS

# Rotate log file if it's too large (over 5MB)
rotate_logs() {
    if [[ -f "$LOG_FILE" && $(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE") -gt 5242880 ]]; then
        local timestamp=$(date +%Y%m%d%H%M%S)
        local backup_file="${LOG_FILE}.${timestamp}"
        
        # Move current log to backup
        mv "$LOG_FILE" "$backup_file"
        
        # Create new log file
        init_logging
        
        # Keep only the last 5 log files
        local log_dir=$(dirname "$LOG_FILE")
        local pattern=$(basename "$LOG_FILE")
        
        # Delete old logs, keeping the newest 5
        ls -t "${log_dir}/${pattern}."* 2>/dev/null | tail -n +6 | xargs -r rm
        
        log_info "Log file rotated. Previous log: $backup_file"
    fi
}

# Check if we should rotate logs
rotate_logs
