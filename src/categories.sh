#!/usr/bin/env bash
# AliasMate v2 - Category management

# List all categories
list_categories() {
    local format="table"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
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
    
    # Ensure categories directory exists
    local categories_dir="$COMMAND_STORE/categories"
    mkdir -p "$categories_dir"
    
    # Check if any categories exist
    if [[ ! -n "$(find "$categories_dir" -type f -print -quit 2>/dev/null)" ]]; then
        print_info "No categories found. Use 'aliasmate categories add <name>' to create one."
        return 0
    fi
    
    # Get list of categories
    local categories=($(find "$categories_dir" -type f -exec basename {} \; | sort))
    
    # Count commands in each category
    local temp_file
    temp_file=$(mktemp)
    
    # Format and display categories
    case "$format" in
        names)
            # Just print category names, one per line
            printf "%s\n" "${categories[@]}"
            ;;
        json)
            # Create JSON object with category counts
            echo "[" > "$temp_file"
            for i in "${!categories[@]}"; do
                local category="${categories[$i]}"
                local count=$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec cat {} \; | 
                              jq -c "select(.category == \"$category\")" | wc -l)
                
                echo "  {" >> "$temp_file"
                echo "    \"name\": \"$category\"," >> "$temp_file"
                echo "    \"count\": $count" >> "$temp_file"
                if [[ $i -lt $(( ${#categories[@]} - 1 )) ]]; then
                    echo "  }," >> "$temp_file"
                else
                    echo "  }" >> "$temp_file"
                fi
            done
            echo "]" >> "$temp_file"
            
            # Pretty print the JSON
            jq '.' "$temp_file"
            ;;
        csv)
            # Create CSV output
            echo "name,count"
            for category in "${categories[@]}"; do
                local count=$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec cat {} \; | 
                              jq -c "select(.category == \"$category\")" | wc -l)
                echo "\"$category\",$count"
            done
            ;;
        table|*)
            # Format as a pretty table
            echo -e "${CYAN}Categories${NC}"
            echo -e "${CYAN}==========${NC}"
            echo -e "Found ${YELLOW}${#categories[@]}${NC} categories"
            echo
            
            for category in "${categories[@]}"; do
                local count=$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec cat {} \; | 
                              jq -c "select(.category == \"$category\")" | wc -l)
                echo -e "${GREEN}${category}${NC}: ${YELLOW}$count${NC} command(s)"
            done
            ;;
    esac
    
    # Clean up
    rm -f "$temp_file"
    
    return 0
}

# Add a new category
add_category() {
    local category_name="$1"
    
    # Validate category name
    if [[ -z "$category_name" ]]; then
        print_error "Missing category name"
        print_info "Usage: aliasmate categories add <name>"
        return 1
    fi
    
    # Validate category format (same rules as alias names)
    if ! validate_alias "$category_name"; then
        print_error "Invalid category name: $category_name"
        print_info "Category names can only contain letters, numbers, underscore and hyphen"
        return 1
    fi
    
    # Ensure categories directory exists
    local categories_dir="$COMMAND_STORE/categories"
    mkdir -p "$categories_dir"
    
    # Check if category already exists
    if [[ -f "$categories_dir/$category_name" ]]; then
        print_warning "Category '$category_name' already exists"
        return 0
    fi
    
    # Create category file
    touch "$categories_dir/$category_name"
    
    print_success "Category '$category_name' created successfully"
    return 0
}

# Remove a category
remove_category() {
    local category_name="$1"
    local force="$2"
    
    # Validate category name
    if [[ -z "$category_name" ]]; then
        print_error "Missing category name"
        print_info "Usage: aliasmate categories rm <name> [--force]"
        return 1
    fi
    
    # Ensure categories directory exists
    local categories_dir="$COMMAND_STORE/categories"
    mkdir -p "$categories_dir"
    
    # Check if category exists
    if [[ ! -f "$categories_dir/$category_name" ]]; then
        print_error "Category '$category_name' not found"
        return 1
    fi
    
    # Check if category is in use
    local count=$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec cat {} \; | 
                  jq -c "select(.category == \"$category_name\")" | wc -l)
    
    if [[ $count -gt 0 && "$force" != "--force" ]]; then
        print_warning "Category '$category_name' is used by $count command(s)"
        if ! confirm "Do you want to reassign these commands to 'general' category?" "n"; then
            print_info "Category removal cancelled"
            return 0
        fi
        
        # Update all commands using this category
        find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec cat {} \; | 
        jq -c "select(.category == \"$category_name\")" | 
        jq -r '.alias' | 
        while read -r alias; do
            local command_file="$COMMAND_STORE/$alias.json"
            if [[ -f "$command_file" ]]; then
                jq '.category = "general"' "$command_file" > "${command_file}.tmp" && 
                mv "${command_file}.tmp" "$command_file"
                print_info "Updated command '$alias' to use 'general' category"
            fi
        done
        
        # Ensure general category exists
        touch "$categories_dir/general"
    fi
    
    # Remove category file
    rm -f "$categories_dir/$category_name"
    
    print_success "Category '$category_name' removed successfully"
    return 0
}

# Rename a category
rename_category() {
    local old_name="$1"
    local new_name="$2"
    
    # Validate category names
    if [[ -z "$old_name" || -z "$new_name" ]]; then
        print_error "Missing category name"
        print_info "Usage: aliasmate categories rename <old-name> <new-name>"
        return 1
    fi
    
    # Validate new name format (same rules as alias names)
    if ! validate_alias "$new_name"; then
        print_error "Invalid category name: $new_name"
        print_info "Category names can only contain letters, numbers, underscore and hyphen"
        return 1
    fi
    
    # Ensure categories directory exists
    local categories_dir="$COMMAND_STORE/categories"
    mkdir -p "$categories_dir"
    
    # Check if old category exists
    if [[ ! -f "$categories_dir/$old_name" ]]; then
        print_error "Category '$old_name' not found"
        return 1
    fi
    
    # Check if new category already exists
    if [[ -f "$categories_dir/$new_name" ]]; then
        print_error "Category '$new_name' already exists"
        return 1
    fi
    
    # Rename category file
    mv "$categories_dir/$old_name" "$categories_dir/$new_name"
    
    # Update all commands using this category
    find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -exec cat {} \; | 
    jq -c "select(.category == \"$old_name\")" | 
    jq -r '.alias' | 
    while read -r alias; do
        local command_file="$COMMAND_STORE/$alias.json"
        if [[ -f "$command_file" ]]; then
            jq --arg new_cat "$new_name" '.category = $new_cat' "$command_file" > "${command_file}.tmp" && 
            mv "${command_file}.tmp" "$command_file"
        fi
    done
    
    print_success "Category '$old_name' renamed to '$new_name' successfully"
    return 0
}

# Main category management function
manage_categories() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        list|"")
            list_categories "$@"
            ;;
        add)
            add_category "$@"
            ;;
        rm|remove)
            remove_category "$@"
            ;;
        rename)
            rename_category "$@"
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            print_info "Valid subcommands: list, add, rm, rename"
            return 1
            ;;
    esac
}
