#!/usr/bin/env bash
# AliasMate v2 - Command management

# Save a command with an alias
save_command() {
    local alias_name=""
    local command=""
    local category=""
    local multi=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --multi)
                multi=true
                shift
                ;;
            --category)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing category name after --category"
                    return 1
                fi
                category="$2"
                shift 2
                ;;
            -*)
                print_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$alias_name" ]]; then
                    alias_name="$1"
                elif [[ -z "$command" ]]; then
                    command="$1"
                else
                    # If we already have alias and command, append rest to command
                    command="$command $1"
                fi
                shift
                ;;
        esac
    done
    
    # Validate alias name
    if [[ -z "$alias_name" ]]; then
        print_error "Missing alias name"
        print_info "Usage: aliasmate save <alias> <command> [--multi] [--category <category>]"
        return 1
    fi
    
    # Validate alias format
    if ! validate_alias "$alias_name"; then
        return 1
    fi
    
    # Check if alias already exists
    if [[ -f "$COMMAND_STORE/$alias_name.json" ]]; then
        if ! confirm "Alias '$alias_name' already exists. Overwrite?" "n"; then
            print_info "Command save cancelled"
            return 0
        fi
    fi
    
    # Handle multi-line command input
    if [[ "$multi" == "true" ]]; then
        print_info "Opening editor for multi-line command input..."
        
        # Create temporary file with helpful instructions
        local temp_file
        temp_file=$(mktemp)
        
        cat > "$temp_file" << EOF
# AliasMate v2 - Multi-line command
# Enter your command below. Lines starting with # are ignored.
# Press Ctrl+X to save when using nano.

EOF
        
        # If we already have a command, add it
        if [[ -n "$command" ]]; then
            echo "$command" >> "$temp_file"
        fi
        
        # Open editor
        ${EDITOR:-nano} "$temp_file"
        
        # Read command from file, skipping comments
        command=$(grep -v "^#" "$temp_file" | sed '/^$/d')
        
        # Clean up
        rm -f "$temp_file"
        
        if [[ -z "$command" ]]; then
            print_error "No command entered"
            return 1
        fi
    else
        # For single-line commands, we need to validate the command is provided
        if [[ -z "$command" ]]; then
            print_error "Missing command"
            print_info "Usage: aliasmate save <alias> <command>"
            return 1
        fi
    fi
    
    # Validate category if specified
    if [[ -n "$category" ]]; then
        # Create category if it doesn't exist
        mkdir -p "$COMMAND_STORE/categories"
        touch "$COMMAND_STORE/categories/$category"
    else
        # Default to "general" category
        category="general"
        mkdir -p "$COMMAND_STORE/categories"
        touch "$COMMAND_STORE/categories/general"
    fi
    
    # Get current working directory for default path
    local default_path="$(pwd)"
    
    # Create command data in JSON format
    local timestamp=$(date +%s)
    local command_file="$COMMAND_STORE/$alias_name.json"
    
    # Create command JSON
    cat > "$command_file" << EOF
{
  "alias": "$alias_name",
  "command": $(jq -n --arg cmd "$command" '$cmd'),
  "path": "$default_path",
  "category": "$category",
  "created": $timestamp,
  "modified": $timestamp,
  "runs": 0,
  "last_run": null
}
EOF
    
    print_success "Command saved as '$alias_name' in category '$category'"
    log_info "Command saved: $alias_name"
    
    return 0
}

# Run a command by its alias
run_command() {
    local alias_name=""
    local custom_path=""
    local additional_args=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --path)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing path value after --path"
                    return 1
                fi
                custom_path="$2"
                shift 2
                ;;
            --args)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing arguments after --args"
                    return 1
                fi
                additional_args="$2"
                shift 2
                ;;
            -*)
                print_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$alias_name" ]]; then
                    alias_name="$1"
                else
                    print_error "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate alias name
    if [[ -z "$alias_name" ]]; then
        print_error "Missing alias name"
        print_info "Usage: aliasmate run <alias> [--path <path>] [--args <args>]"
        return 1
    fi
    
    # Check if alias exists
    local command_file="$COMMAND_STORE/$alias_name.json"
    if [[ ! -f "$command_file" ]]; then
        print_error "Alias '$alias_name' not found"
        return 1
    fi
    
    # Read command data
    local command=$(jq -r '.command' "$command_file")
    local default_path=$(jq -r '.path' "$command_file")
    
    # Use custom path if provided
    local path_to_use="${custom_path:-$default_path}"
    
    # Validate path existence
    if [[ ! -d "$path_to_use" ]]; then
        print_error "Path '$path_to_use' does not exist"
        return 1
    fi
    
    # Update command statistics
    local timestamp=$(date +%s)
    local runs=$(jq -r '.runs' "$command_file")
    ((runs++))
    
    # Record the start time for execution duration
    local start_time=$(date +%s.%N)
    
    # Execute the command
    print_info "Running command: $(jq -r '.alias' "$command_file")"
    log_info "Running command: $alias_name"
    
    (
        cd "$path_to_use" || { 
            print_error "Failed to change to directory: $path_to_use"
            exit 1
        }
        
        # Execute the command
        if [[ -n "$additional_args" ]]; then
            eval "$command $additional_args"
        else
            eval "$command"
        fi
    )
    local exit_code=$?
    
    # Calculate duration
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    # Update command statistics
    jq --arg last_run "$timestamp" \
       --arg exit_code "$exit_code" \
       --arg runs "$runs" \
       --arg duration "$duration" \
       '.runs = ($runs | tonumber) | 
        .last_run = ($last_run | tonumber) | 
        .last_exit_code = ($exit_code | tonumber) |
        .last_duration = ($duration | tonumber)' \
       "$command_file" > "${command_file}.tmp" && mv "${command_file}.tmp" "$command_file"
    
    # Also update stats file
    local stats_dir="$COMMAND_STORE/stats"
    mkdir -p "$stats_dir"
    local stats_file="$stats_dir/${alias_name}.csv"
    
    # Create stats file with header if it doesn't exist
    if [[ ! -f "$stats_file" ]]; then
        echo "timestamp,duration,exit_code" > "$stats_file"
    fi
    
    # Append the stats
    echo "$timestamp,$duration,$exit_code" >> "$stats_file"
    
    # Print execution results
    if [[ $exit_code -eq 0 ]]; then
        print_success "Command executed successfully (took $(printf "%.2f" "$duration")s)"
    else
        print_warning "Command exited with status $exit_code (took $(printf "%.2f" "$duration")s)"
    fi
    
    return $exit_code
}

# Edit an existing command
edit_command() {
    local alias_name=""
    local edit_command=false
    local edit_path=false
    local edit_category=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cmd)
                edit_command=true
                shift
                ;;
            --path)
                edit_path=true
                shift
                ;;
            --category)
                edit_category=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$alias_name" ]]; then
                    alias_name="$1"
                else
                    print_error "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate alias name
    if [[ -z "$alias_name" ]]; then
        print_error "Missing alias name"
        print_info "Usage: aliasmate edit <alias> [--cmd] [--path] [--category]"
        return 1
    fi
    
    # Check if alias exists
    local command_file="$COMMAND_STORE/$alias_name.json"
    if [[ ! -f "$command_file" ]]; then
        print_error "Alias '$alias_name' not found"
        return 1
    fi
    
    # If no specific edit option is provided, edit all fields
    if [[ "$edit_command" == "false" && "$edit_path" == "false" && "$edit_category" == "false" ]]; then
        edit_command=true
        edit_path=true
        edit_category=true
    fi
    
    # Read current values
    local current_command=$(jq -r '.command' "$command_file")
    local current_path=$(jq -r '.path' "$command_file")
    local current_category=$(jq -r '.category' "$command_file")
    
    # Edit command if requested
    if [[ "$edit_command" == "true" ]]; then
        print_info "Editing command for '$alias_name'..."
        
        # Create temporary file for editing
        local temp_file
        temp_file=$(mktemp)
        
        cat > "$temp_file" << EOF
# AliasMate v2 - Edit command
# Edit the command below. Lines starting with # are ignored.
# Current command for alias '$alias_name':

$current_command
EOF
        
        # Open editor
        ${EDITOR:-nano} "$temp_file"
        
        # Read updated command, skipping comments
        local new_command=$(grep -v "^#" "$temp_file" | sed '/^$/d')
        rm -f "$temp_file"
        
        if [[ -z "$new_command" ]]; then
            print_warning "Command cannot be empty, keeping original"
        else
            current_command="$new_command"
        fi
    fi
    
    # Edit path if requested
    if [[ "$edit_path" == "true" ]]; then
        print_info "Editing path for '$alias_name'..."
        
        # Create temporary file for editing
        local temp_file
        temp_file=$(mktemp)
        
        cat > "$temp_file" << EOF
# AliasMate v2 - Edit path
# Edit the default path below. This should be a valid directory.
# Current path for alias '$alias_name':

$current_path
EOF
        
        # Open editor
        ${EDITOR:-nano} "$temp_file"
        
        # Read updated path, skipping comments
        local new_path=$(grep -v "^#" "$temp_file" | sed '/^$/d')
        rm -f "$temp_file"
        
        if [[ -z "$new_path" ]]; then
            print_warning "Path cannot be empty, keeping original"
        elif [[ ! -d "$new_path" ]]; then
            print_warning "Directory '$new_path' does not exist, keeping original path"
        else
            current_path="$new_path"
        fi
    fi
    
    # Edit category if requested
    if [[ "$edit_category" == "true" ]]; then
        print_info "Editing category for '$alias_name'..."
        
        # List available categories
        local categories
        categories=$(find "$COMMAND_STORE/categories" -type f -exec basename {} \; 2>/dev/null | sort)
        
        local temp_file
        temp_file=$(mktemp)
        
        cat > "$temp_file" << EOF
# AliasMate v2 - Edit category
# Edit the category below.
# Current category for alias '$alias_name': $current_category
#
# Available categories:
$(printf "# - %s\n" $categories)
#
# Type a new category name to create one.

$current_category
EOF
        
        # Open editor
        ${EDITOR:-nano} "$temp_file"
        
        # Read updated category, skipping comments
        local new_category=$(grep -v "^#" "$temp_file" | sed '/^$/d')
        rm -f "$temp_file"
        
        if [[ -z "$new_category" ]]; then
            print_warning "Category cannot be empty, keeping original"
        else
            current_category="$new_category"
            # Ensure category exists
            mkdir -p "$COMMAND_STORE/categories"
            touch "$COMMAND_STORE/categories/$current_category"
        fi
    fi
    
    # Update the command file
    local timestamp=$(date +%s)
    
    jq --arg cmd "$current_command" \
       --arg path "$current_path" \
       --arg category "$current_category" \
       --arg modified "$timestamp" \
       '.command = $cmd | 
        .path = $path | 
        .category = $category | 
        .modified = ($modified | tonumber)' \
       "$command_file" > "${command_file}.tmp" && mv "${command_file}.tmp" "$command_file"
    
    print_success "Command '$alias_name' updated successfully"
    log_info "Command edited: $alias_name"
    
    return 0
}

# List all saved commands
list_commands() {
    local category=""
    local sort_field="alias"
    local format="table"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --category)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing category name after --category"
                    return 1
                fi
                category="$2"
                shift 2
                ;;
            --sort)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing sort field after --sort"
                    return 1
                fi
                case "$2" in
                    name|alias) sort_field="alias" ;;
                    path) sort_field="path" ;;
                    usage|runs) sort_field="runs" ;;
                    *) 
                        print_error "Invalid sort field: $2"
                        print_info "Valid sort fields: name, path, usage"
                        return 1
                        ;;
                esac
                shift 2
                ;;
            --format)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing format after --format"
                    return 1
                fi
                case "$2" in
                    table|json|csv|names)
                        format="$2"
                        ;;
                    *)
                        print_error "Invalid format: $2"
                        print_info "Valid formats: table, json, csv, names"
                        return 1
                        ;;
                esac
                shift 2
                ;;
            -*)
                print_error "Unknown option: $1"
                return 1
                ;;
            *)
                print_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done
    
    # Check if any commands exist
    if [[ ! -n "$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -print -quit 2>/dev/null)" ]]; then
        print_info "No commands found. Use 'aliasmate save' to add some."
        return 0
    fi
    
    # Create a temporary file to store command data
    local temp_file
    temp_file=$(mktemp)
    
    # Collect commands, filtering by category if needed
    if [[ -n "$category" ]]; then
        print_info "Listing commands in category: $category"
        # Find all commands in the specified category
        find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec cat {} \; | 
        jq -c "select(.category == \"$category\")" > "$temp_file"
    else
        # Get all commands
        find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec cat {} \; > "$temp_file"
    fi
    
    # Check if any commands were found after filtering
    if [[ ! -s "$temp_file" ]]; then
        if [[ -n "$category" ]]; then
            print_info "No commands found in category '$category'"
        else
            print_info "No commands found"
        fi
        rm -f "$temp_file"
        return 0
    fi
    
    # Process and display the commands
    case "$format" in
        names)
            # Just print alias names, one per line
            jq -r '.alias' "$temp_file" | sort
            ;;
        json)
            # Format as pretty JSON
            jq -s '.' "$temp_file"
            ;;
        csv)
            # Convert to CSV format
            echo "alias,command,path,category,runs,last_run,last_exit_code"
            jq -r '[.alias, .command, .path, .category, .runs, .last_run, .last_exit_code] | @csv' "$temp_file"
            ;;
        table|*)
            # Format as a pretty table
            echo -e "${CYAN}AliasMate Commands${NC}"
            echo -e "${CYAN}==================${NC}"
            
            # Sort by the selected field
            case "$sort_field" in
                alias)
                    jq -s 'sort_by(.alias)' "$temp_file" > "${temp_file}.sorted"
                    ;;
                path)
                    jq -s 'sort_by(.path)' "$temp_file" > "${temp_file}.sorted"
                    ;;
                runs)
                    jq -s 'sort_by(.runs) | reverse' "$temp_file" > "${temp_file}.sorted"
                    ;;
            esac
            
            # Count commands
            local count=$(jq -s 'length' "${temp_file}.sorted")
            echo -e "Found ${YELLOW}$count${NC} command(s)"
            echo
            
            # Display commands in a formatted table
            jq -r '.[] | [.alias, .command, .category, .runs] | @tsv' "${temp_file}.sorted" |
            while IFS=$'\t' read -r alias cmd category runs; do
                # Truncate long commands for display
                if [[ ${#cmd} -gt 50 ]]; then
                    cmd="${cmd:0:47}..."
                fi
                
                echo -e "${GREEN}${BOLD}$alias${NC} (${BLUE}$category${NC}, ${YELLOW}$runs runs${NC})"
                echo -e "  ${cmd}"
                echo
            done
            
            rm -f "${temp_file}.sorted"
            ;;
    esac
    
    # Clean up
    rm -f "$temp_file"
    
    return 0
}

# Remove a command
remove_command() {
    local alias_name="$1"
    local force="$2"
    
    # Validate alias name
    if [[ -z "$alias_name" ]]; then
        print_error "Missing alias name"
        print_info "Usage: aliasmate rm <alias> [--force]"
        return 1
    fi
    
    # Check if alias exists
    local command_file="$COMMAND_STORE/$alias_name.json"
    if [[ ! -f "$command_file" ]]; then
        print_error "Alias '$alias_name' not found"
        return 1
    fi
    
    # Confirm deletion unless forced
    if [[ "$force" != "--force" ]]; then
        if ! confirm "Are you sure you want to remove alias '$alias_name'?" "n"; then
            print_info "Command removal cancelled"
            return 0
        fi
    fi
    
    # Remove command file and associated stats
    rm -f "$command_file"
    rm -f "$COMMAND_STORE/stats/${alias_name}.csv"
    
    print_success "Command '$alias_name' removed successfully"
    log_info "Command removed: $alias_name"
    
    return 0
}

# Export commands
export_commands() {
    local alias_name=""
    local format="json"
    local output_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing format after --format"
                    return 1
                fi
                case "$2" in
                    json|yaml|csv)
                        format="$2"
                        ;;
                    *)
                        print_error "Invalid format: $2"
                        print_info "Valid formats: json, yaml, csv"
                        return 1
                        ;;
                esac
                shift 2
                ;;
            --output)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing filename after --output"
                    return 1
                fi
                output_file="$2"
                shift 2
                ;;
            -*)
                print_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$alias_name" ]]; then
                    alias_name="$1"
                else
                    print_error "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # If no output file specified, create a default one
    if [[ -z "$output_file" ]]; then
        if [[ -n "$alias_name" ]]; then
            output_file="aliasmate_${alias_name}_$(date +%Y%m%d).${format}"
        else
            output_file="aliasmate_export_$(date +%Y%m%d).${format}"
        fi
    fi
    
    # Check if any commands exist
    if [[ ! -n "$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -print -quit 2>/dev/null)" ]]; then
        print_error "No commands found to export"
        return 1
    fi
    
    # Export a single command or all commands
    if [[ -n "$alias_name" ]]; then
        # Export a specific command
        local command_file="$COMMAND_STORE/$alias_name.json"
        if [[ ! -f "$command_file" ]]; then
            print_error "Alias '$alias_name' not found"
            return 1
        fi
        
        case "$format" in
            json)
                cat "$command_file" > "$output_file"
                ;;
            yaml)
                # Convert JSON to YAML (requires yq)
                if command_exists yq; then
                    yq -P eval '.' "$command_file" > "$output_file"
                else
                    print_error "YAML export requires 'yq' tool. Please install it."
                    return 1
                fi
                ;;
            csv)
                # Create CSV header
                echo "alias,command,path,category,created,modified,runs,last_run,last_exit_code,last_duration" > "$output_file"
                # Convert JSON to CSV
                jq -r '[.alias, .command, .path, .category, .created, .modified, .runs, .last_run, .last_exit_code, .last_duration] | @csv' "$command_file" >> "$output_file"
                ;;
        esac
    else
        # Export all commands
        case "$format" in
            json)
                # Combine all command JSONs into an array
                jq -s '.' "$COMMAND_STORE"/*.json > "$output_file"
                ;;
            yaml)
                # Convert JSON to YAML (requires yq)
                if command_exists yq; then
                    jq -s '.' "$COMMAND_STORE"/*.json | yq -P eval '.' - > "$output_file"
                else
                    print_error "YAML export requires 'yq' tool. Please install it."
                    return 1
                fi
                ;;
            csv)
                # Create CSV header
                echo "alias,command,path,category,created,modified,runs,last_run,last_exit_code,last_duration" > "$output_file"
                # Convert each JSON to a CSV row
                find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec jq -r '[.alias, .command, .path, .category, .created, .modified, .runs, .last_run, .last_exit_code, .last_duration] | @csv' {} \; >> "$output_file"
                ;;
        esac
    fi
    
    print_success "Export completed: $output_file"
    log_info "Commands exported to: $output_file"
    
    return 0
}

# Import commands
import_commands() {
    local file=""
    local merge=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --merge)
                merge=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                return 1
                ;;
            *)
                if [[ -z "$file" ]]; then
                    file="$1"
                else
                    print_error "Unexpected argument: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate file
    if [[ -z "$file" ]]; then
        print_error "Missing file to import"
        print_info "Usage: aliasmate import <file> [--merge]"
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi
    
    # Determine file format by extension
    local format
    if [[ "$file" == *.json ]]; then
        format="json"
    elif [[ "$file" == *.yaml || "$file" == *.yml ]]; then
        format="yaml"
    elif [[ "$file" == *.csv ]]; then
        format="csv"
    else
        # Try to guess by content
        if grep -q "^\[" "$file"; then
            format="json"
        elif grep -q "^alias,command,path" "$file"; then
            format="csv"
        else
            print_error "Unable to determine file format. Please use .json, .yaml, or .csv extension."
            return 1
        fi
    fi
    
    # Process based on format
    local temp_dir
    temp_dir=$(mktemp -d)
    local imported=0
    local errors=0
    
    case "$format" in
        json)
            # Check if it's a single command or an array
            if grep -q "^\[" "$file"; then
                # Array of commands - extract each to a separate file
                jq -c '.[]' "$file" | while read -r cmd; do
                    local alias_name
                    alias_name=$(echo "$cmd" | jq -r '.alias')
                    
                    if [[ -z "$alias_name" || "$alias_name" == "null" ]]; then
                        print_warning "Skipping command with missing alias"
                        ((errors++))
                        continue
                    fi
                    
                    # Validate alias
                    if ! validate_alias "$alias_name"; then
                        print_warning "Skipping command with invalid alias: $alias_name"
                        ((errors++))
                        continue
                    fi
                    
                    # Check if alias already exists
                    if [[ -f "$COMMAND_STORE/$alias_name.json" && "$merge" != "true" ]]; then
                        print_warning "Alias '$alias_name' already exists, skipping (use --merge to override)"
                        ((errors++))
                        continue
                    fi
                    
                    # Save the command
                    echo "$cmd" > "$COMMAND_STORE/$alias_name.json"
                    
                    # Create category if needed
                    local category
                    category=$(echo "$cmd" | jq -r '.category')
                    if [[ -n "$category" && "$category" != "null" ]]; then
                        mkdir -p "$COMMAND_STORE/categories"
                        touch "$COMMAND_STORE/categories/$category"
                    fi
                    
                    ((imported++))
                done
            else
                # Single command
                local alias_name
                alias_name=$(jq -r '.alias' "$file")
                
                if [[ -z "$alias_name" || "$alias_name" == "null" ]]; then
                    print_error "Command has no alias"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                # Validate alias
                if ! validate_alias "$alias_name"; then
                    print_error "Invalid alias: $alias_name"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                # Check if alias already exists
                if [[ -f "$COMMAND_STORE/$alias_name.json" && "$merge" != "true" ]]; then
                    print_error "Alias '$alias_name' already exists (use --merge to override)"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                # Save the command
                cp "$file" "$COMMAND_STORE/$alias_name.json"
                
                # Create category if needed
                local category
                category=$(jq -r '.category' "$file")
                if [[ -n "$category" && "$category" != "null" ]]; then
                    mkdir -p "$COMMAND_STORE/categories"
                    touch "$COMMAND_STORE/categories/$category"
                fi
                
                ((imported++))
            fi
            ;;
        yaml)
            # Convert YAML to JSON (requires yq)
            if command_exists yq; then
                yq eval -o=json "$file" > "$temp_dir/import.json"
                
                # Now process the JSON
                if grep -q "^\[" "$temp_dir/import.json"; then
                    # Array of commands
                    jq -c '.[]' "$temp_dir/import.json" | while read -r cmd; do
                        local alias_name
                        alias_name=$(echo "$cmd" | jq -r '.alias')
                        
                        if [[ -z "$alias_name" || "$alias_name" == "null" ]]; then
                            print_warning "Skipping command with missing alias"
                            ((errors++))
                            continue
                        fi
                        
                        # Validate alias
                        if ! validate_alias "$alias_name"; then
                            print_warning "Skipping command with invalid alias: $alias_name"
                            ((errors++))
                            continue
                        fi
                        
                        # Check if alias already exists
                        if [[ -f "$COMMAND_STORE/$alias_name.json" && "$merge" != "true" ]]; then
                            print_warning "Alias '$alias_name' already exists, skipping (use --merge to override)"
                            ((errors++))
                            continue
                        fi
                        
                        # Save the command
                        echo "$cmd" > "$COMMAND_STORE/$alias_name.json"
                        
                        # Create category if needed
                        local category
                        category=$(echo "$cmd" | jq -r '.category')
                        if [[ -n "$category" && "$category" != "null" ]]; then
                            mkdir -p "$COMMAND_STORE/categories"
                            touch "$COMMAND_STORE/categories/$category"
                        fi
                        
                        ((imported++))
                    done
                else
                    # Single command
                    local alias_name
                    alias_name=$(jq -r '.alias' "$temp_dir/import.json")
                    
                    if [[ -z "$alias_name" || "$alias_name" == "null" ]]; then
                        print_error "Command has no alias"
                        rm -rf "$temp_dir"
                        return 1
                    fi
                    
                    # Validate alias
                    if ! validate_alias "$alias_name"; then
                        print_error "Invalid alias: $alias_name"
                        rm -rf "$temp_dir"
                        return 1
                    fi
                    
                    # Check if alias already exists
                    if [[ -f "$COMMAND_STORE/$alias_name.json" && "$merge" != "true" ]]; then
                        print_error "Alias '$alias_name' already exists (use --merge to override)"
                        rm -rf "$temp_dir"
                        return 1
                    fi
                    
                    # Save the command
                    cp "$temp_dir/import.json" "$COMMAND_STORE/$alias_name.json"
                    
                    # Create category if needed
                    local category
                    category=$(jq -r '.category' "$temp_dir/import.json")
                    if [[ -n "$category" && "$category" != "null" ]]; then
                        mkdir -p "$COMMAND_STORE/categories"
                        touch "$COMMAND_STORE/categories/$category"
                    fi
                    
                    ((imported++))
                fi
            else
                print_error "YAML import requires 'yq' tool. Please install it."
                rm -rf "$temp_dir"
                return 1
            fi
            ;;
        csv)
            # Skip header
            tail -n +2 "$file" | while IFS=, read -r alias_name command path category created modified runs last_run last_exit_code last_duration; do
                # Remove quotes from CSV fields
                alias_name=${alias_name//\"/}
                command=${command//\"/}
                path=${path//\"/}
                category=${category//\"/}
                
                # Validate alias
                if [[ -z "$alias_name" ]]; then
                    print_warning "Skipping command with missing alias"
                    ((errors++))
                    continue
                fi
                
                if ! validate_alias "$alias_name"; then
                    print_warning "Skipping command with invalid alias: $alias_name"
                    ((errors++))
                    continue
                fi
                
                # Check if alias already exists
                if [[ -f "$COMMAND_STORE/$alias_name.json" && "$merge" != "true" ]]; then
                    print_warning "Alias '$alias_name' already exists, skipping (use --merge to override)"
                    ((errors++))
                    continue
                fi
                
                # Create command JSON
                local timestamp=$(date +%s)
                cat > "$COMMAND_STORE/$alias_name.json" << EOF
{
  "alias": "$alias_name",
  "command": $(jq -n --arg cmd "$command" '$cmd'),
  "path": "${path:-$PWD}",
  "category": "${category:-general}",
  "created": ${created:-$timestamp},
  "modified": ${modified:-$timestamp},
  "runs": ${runs:-0},
  "last_run": ${last_run:-null},
  "last_exit_code": ${last_exit_code:-null},
  "last_duration": ${last_duration:-null}
}
EOF
                
                # Create category if needed
                if [[ -n "$category" ]]; then
                    mkdir -p "$COMMAND_STORE/categories"
                    touch "$COMMAND_STORE/categories/$category"
                fi
                
                ((imported++))
            done
            ;;
    esac
    
    # Clean up
    rm -rf "$temp_dir"
    
    if [[ $imported -gt 0 ]]; then
        print_success "Imported $imported command(s) successfully"
    fi
    
    if [[ $errors -gt 0 ]]; then
        print_warning "Skipped $errors command(s) due to errors"
    fi
    
    if [[ $imported -eq 0 && $errors -eq 0 ]]; then
        print_warning "No commands found to import"
    }
    
    log_info "Imported $imported commands from $file"
    
    return 0
}
