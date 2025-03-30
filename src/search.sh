#!/usr/bin/env bash
# AliasMate v2 - Search functionality

# Search commands by name, content, or path
search_commands() {
    local search_term=""
    local search_category=""
    local search_in_command=true
    local search_in_path=false
    local search_in_alias=true
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --category)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing category name after --category"
                    return 1
                fi
                search_category="$2"
                shift 2
                ;;
            --command)
                search_in_command=true
                search_in_alias=false
                search_in_path=false
                shift
                ;;
            --path)
                search_in_path=true
                search_in_command=false
                search_in_alias=false
                shift
                ;;
            --alias)
                search_in_alias=true
                search_in_command=false
                search_in_path=false
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$search_term" ]]; then
                    search_term="$1"
                else
                    print_error "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate search term
    if [[ -z "$search_term" ]]; then
        print_error "Missing search term"
        print_info "Usage: aliasmate search <term> [--category <cat>] [--command|--path|--alias]"
        return 1
    fi
    
    # Check if any commands exist
    if [[ ! -n "$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -print -quit 2>/dev/null)" ]]; then
        print_info "No commands found. Use 'aliasmate save' to add some."
        return 0
    fi
    
    # Create a temporary file to store search results
    local temp_file
    temp_file=$(mktemp)
    
    # Perform the search
    if [[ -n "$search_category" ]]; then
        print_info "Searching in category: $search_category"
    fi
    
    # Build the jq filter based on search criteria
    local jq_filter=""
    local search_fields=()
    
    if [[ "$search_in_alias" == "true" ]]; then
        search_fields+=(".alias | contains(\"$search_term\")")
    fi
    
    if [[ "$search_in_command" == "true" ]]; then
        search_fields+=(".command | contains(\"$search_term\")")
    fi
    
    if [[ "$search_in_path" == "true" ]]; then
        search_fields+=(".path | contains(\"$search_term\")")
    fi
    
    # Combine search fields with OR
    jq_filter=$(printf " or " "${search_fields[@]}")
    jq_filter="${jq_filter:4}"  # Remove leading " or "
    
    # Add category filter if specified
    if [[ -n "$search_category" ]]; then
        jq_filter="$jq_filter and .category == \"$search_category\""
    fi
    
    # Execute the search
    find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec cat {} \; | 
    jq -c "select($jq_filter)" > "$temp_file"
    
    # Check if any results were found
    if [[ ! -s "$temp_file" ]]; then
        print_info "No commands found matching '$search_term'"
        rm -f "$temp_file"
        return 0
    fi
    
    # Count results
    local result_count=$(wc -l < "$temp_file")
    
    # Display results
    echo -e "${CYAN}Search Results for '${search_term}'${NC}"
    echo -e "${CYAN}==============================${NC}"
    echo -e "Found ${YELLOW}$result_count${NC} matching command(s)"
    echo
    
    # Format search results
    jq -s 'sort_by(.alias)' "$temp_file" | 
    jq -r '.[] | [.alias, .command, .category] | @tsv' |
    while IFS=$'\t' read -r alias cmd category; do
        # Truncate long commands for display
        if [[ ${#cmd} -gt 50 ]]; then
            cmd="${cmd:0:47}..."
        fi
        
        # Highlight the search term if it appears in the display text
        if [[ "$search_in_alias" == "true" && "$alias" == *"$search_term"* ]]; then
            alias="${alias//$search_term/${YELLOW}${search_term}${GREEN}}"
        fi
        
        if [[ "$search_in_command" == "true" && "$cmd" == *"$search_term"* ]]; then
            cmd="${cmd//$search_term/${YELLOW}${search_term}${NC}}"
        fi
        
        echo -e "${GREEN}${BOLD}$alias${NC} (${BLUE}$category${NC})"
        echo -e "  ${cmd}"
        echo
    done
    
    # Clean up
    rm -f "$temp_file"
    
    return 0
}
