#!/usr/bin/env bash
# AliasMate v2 - Batch Processing Module

# Batch import multiple commands from a directory of files
batch_import() {
    local dir="$1"
    local merge="${2:-false}"
    
    if [[ ! -d "$dir" ]]; then
        print_error "Directory not found: $dir"
        return 1
    fi
    
    local import_count=0
    local error_count=0
    local total_files=$(find "$dir" -type f | wc -l)
    
    # Show a header
    print_info "Starting batch import from $dir ($total_files files)"
    echo -e "${CYAN}=====================================${NC}"
    
    # Process each file
    local counter=0
    find "$dir" -type f | while read -r file; do
        ((counter++))
        
        # Show progress
        show_progress $counter $total_files "Importing"
        
        # Check if the file looks like a valid import file
        local ext="${file##*.}"
        if [[ "$ext" != "json" && "$ext" != "yaml" && "$ext" != "yml" && "$ext" != "csv" ]]; then
            ((error_count++))
            continue
        fi
        
        # Import the file
        if ! import_commands "$file" $([ "$merge" == "true" ] && echo "--merge") > /dev/null 2>&1; then
            ((error_count++))
        else
            ((import_count++))
        fi
    done
    
    echo -e "\n${GREEN}Import complete: $import_count files imported, $error_count errors${NC}"
    return 0
}

# Batch edit multiple commands matching a pattern
batch_edit() {
    local pattern="$1"
    local edit_type="$2"  # "command", "path", "category"
    local new_value="$3"
    
    if [[ -z "$pattern" ]]; then
        print_error "Missing search pattern"
        return 1
    fi
    
    if [[ -z "$edit_type" ]]; then
        print_error "Missing edit type (command, path, category)"
        return 1
    fi
    
    if [[ -z "$new_value" && "$edit_type" != "interactive" ]]; then
        print_error "Missing new value"
        return 1
    fi
    
    # Find matching commands
    local matches=$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec grep -l "$pattern" {} \;)
    local total_matches=$(echo "$matches" | wc -l)
    
    if [[ -z "$matches" ]]; then
        print_info "No commands match pattern: $pattern"
        return 0
    fi
    
    print_info "Found $total_matches commands matching: $pattern"
    
    if ! confirm "Update all matching commands?" "n"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    local counter=0
    local updated=0
    
    echo "$matches" | while read -r cmd_file; do
        ((counter++))
        local alias_name=$(basename "$cmd_file" .json)
        
        # Show progress
        show_progress $counter $total_matches "Updating"
        
        # Update the command
        case "$edit_type" in
            command)
                jq --arg cmd "$new_value" '.command = $cmd | .modified = now' "$cmd_file" > "${cmd_file}.tmp" && 
                mv "${cmd_file}.tmp" "$cmd_file" && ((updated++))
                ;;
            path)
                jq --arg path "$new_value" '.path = $path | .modified = now' "$cmd_file" > "${cmd_file}.tmp" && 
                mv "${cmd_file}.tmp" "$cmd_file" && ((updated++))
                ;;
            category)
                jq --arg cat "$new_value" '.category = $cat | .modified = now' "$cmd_file" > "${cmd_file}.tmp" && 
                mv "${cmd_file}.tmp" "$cmd_file" && ((updated++))
                
                # Ensure category exists
                mkdir -p "$COMMAND_STORE/categories"
                touch "$COMMAND_STORE/categories/$new_value"
                ;;
            interactive)
                # Edit each command interactively
                echo -e "\nEditing: ${GREEN}$alias_name${NC}"
                edit_command "$alias_name" && ((updated++))
                ;;
        esac
    done
    
    print_success "Updated $updated out of $total_matches commands"
    return 0
}

# Run multiple commands in sequence
batch_run() {
    local pattern="$1"
    local path="$2"  # optional custom path
    
    if [[ -z "$pattern" ]]; then
        print_error "Missing search pattern"
        return 1
    fi
    
    # Find matching commands
    local matches=$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" | grep "$pattern")
    local total_matches=$(echo "$matches" | wc -l)
    
    if [[ -z "$matches" ]]; then
        print_info "No commands match pattern: $pattern"
        return 0
    fi
    
    print_info "Found $total_matches commands matching: $pattern"
    
    # Show the commands to run
    echo -e "${CYAN}Commands to run:${NC}"
    for cmd_file in $matches; do
        local alias_name=$(basename "$cmd_file" .json)
        local cmd=$(jq -r '.command' "$cmd_file")
        echo -e " - ${GREEN}$alias_name${NC}: $cmd"
    done
    
    if ! confirm "Run all these commands?" "n"; then
        print_info "Operation cancelled"
        return 0
    fi
    
    local success=0
    local failed=0
    
    echo -e "\n${CYAN}Executing commands...${NC}"
    for cmd_file in $matches; do
        local alias_name=$(basename "$cmd_file" .json)
        
        echo -e "\n${YELLOW}Running: $alias_name${NC}"
        
        if [[ -n "$path" ]]; then
            run_command "$alias_name" --path "$path"
        else
            run_command "$alias_name"
        fi
        
        if [[ $? -eq 0 ]]; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    echo -e "\n${CYAN}Execution summary:${NC}"
    echo -e " - ${GREEN}Success: $success${NC}"
    echo -e " - ${RED}Failed: $failed${NC}"
    
    return 0
}

# Main batch command handler
handle_batch() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        import)
            batch_import "$@"
            ;;
        edit)
            batch_edit "$@"
            ;;
        run)
            batch_run "$@"
            ;;
        *)
            print_error "Unknown batch subcommand: $subcommand"
            print_info "Valid subcommands: import, edit, run"
            return 1
            ;;
    esac
}
