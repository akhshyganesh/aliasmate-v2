#!/usr/bin/env bash
# AliasMate v2 - UI Components and Performance Enhancements

# Display a spinner while a command runs
show_spinner() {
    local pid=$1
    local message="${2:-Loading...}"
    local delay=0.1
    local spinstr='|/-\'
    
    # Save cursor position
    tput sc
    
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c] %s" "$spinstr" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
        tput el  # Clear to end of line
    done
    
    # Clear the spinner line
    printf "\r"
    tput el
    
    # Restore cursor position
    tput rc
}

# Display a progress bar
show_progress() {
    local current=$1
    local total=$2
    local message="${3:-Progress}"
    local width=40
    
    # Calculate percentage
    local percent=$((current * 100 / total))
    local completed_width=$((width * current / total))
    
    # Build the progress bar
    local bar="["
    for ((i=0; i<width; i++)); do
        if [[ $i -lt $completed_width ]]; then
            bar+="="
        else
            bar+=" "
        fi
    done
    bar+="] $percent%"
    
    # Display the progress bar
    printf "\r%-20s %s" "$message" "$bar"
    
    # Add newline if complete
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Display a notification styled based on message type
show_notification() {
    local message="$1"
    local type="${2:-info}"  # info, success, warning, error
    
    case "$type" in
        success)
            echo -e "${GREEN}✓ ${message}${NC}"
            ;;
        warning)
            echo -e "${YELLOW}⚠ ${message}${NC}"
            ;;
        error)
            echo -e "${RED}✘ ${message}${NC}"
            ;;
        info|*)
            echo -e "${BLUE}ℹ ${message}${NC}"
            ;;
    esac
}

# Create a centered heading for TUI
tui_centered_heading() {
    local text="$1"
    local width="$2"
    
    # Calculate padding
    local text_length=${#text}
    local padding=$(( (width - text_length) / 2 ))
    
    # Create the padded text
    local padded_text=""
    for ((i=0; i<padding; i++)); do
        padded_text+=" "
    done
    padded_text+="$text"
    
    echo "$padded_text"
}

# Create a select menu and return the user's choice
select_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo -e "${CYAN}$title${NC}"
    echo
    
    for i in "${!options[@]}"; do
        echo -e "  ${YELLOW}$((i+1))${NC}. ${options[$i]}"
    done
    echo
    
    local choice
    while true; do
        read -p "Enter selection [1-${#options[@]}]: " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            return $((choice-1))
        else
            echo -e "${RED}Invalid selection. Please try again.${NC}"
        fi
    done
}

# Paginate output text
paginate_text() {
    local text="$1"
    local page_size="${2:-10}"
    
    # Count total lines
    local total_lines=$(echo -e "$text" | wc -l)
    local total_pages=$(( (total_lines + page_size - 1) / page_size ))
    local current_page=1
    
    while true; do
        # Calculate range to display
        local start_line=$(( (current_page - 1) * page_size + 1 ))
        local end_line=$((current_page * page_size))
        
        # Clear screen
        clear
        
        # Display page header
        echo -e "${CYAN}Page $current_page of $total_pages${NC}"
        echo
        
        # Display content
        echo -e "$text" | sed -n "${start_line},${end_line}p"
        
        # Display navigation
        echo
        echo -e "${YELLOW}n${NC}:Next ${YELLOW}p${NC}:Previous ${YELLOW}q${NC}:Quit"
        
        # Get user input
        read -n 1 -s nav
        case "$nav" in
            n|N)
                if [[ $current_page -lt $total_pages ]]; then
                    ((current_page++))
                fi
                ;;
            p|P)
                if [[ $current_page -gt 1 ]]; then
                    ((current_page--))
                fi
                ;;
            q|Q)
                return 0
                ;;
        esac
    done
}

# Optimize large data processing with background tasks
process_in_background() {
    local cmd="$1"
    local message="${2:-Processing...}"
    
    # Start the command in background
    eval "$cmd" &
    local pid=$!
    
    # Show spinner while command runs
    show_spinner $pid "$message"
    
    # Wait for command to finish
    wait $pid
    return $?
}

# Cache manager for performance optimization
init_cache() {
    mkdir -p "$HOME/.cache/aliasmate"
}

cache_set() {
    local key="$1"
    local value="$2"
    local expiry="${3:-3600}"  # Default 1 hour
    
    local cache_file="$HOME/.cache/aliasmate/${key}"
    local expiry_time=$(($(date +%s) + expiry))
    
    echo "${expiry_time}" > "$cache_file"
    echo "${value}" >> "$cache_file"
}

cache_get() {
    local key="$1"
    local cache_file="$HOME/.cache/aliasmate/${key}"
    
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi
    
    # Read expiry time from first line
    local expiry_time=$(head -n 1 "$cache_file")
    local current_time=$(date +%s)
    
    # Check if cache is valid
    if (( current_time > expiry_time )); then
        # Cache expired
        rm -f "$cache_file"
        return 1
    fi
    
    # Return cached value (all lines except the first)
    tail -n +2 "$cache_file"
    return 0
}

cache_clear() {
    local key="$1"
    
    if [[ -n "$key" ]]; then
        rm -f "$HOME/.cache/aliasmate/${key}"
    else
        rm -f "$HOME/.cache/aliasmate/"*
    fi
}
