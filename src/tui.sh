#!/usr/bin/env bash
# AliasMate v2 - Text User Interface

# Check if we have a suitable TUI toolkit
check_tui_dependencies() {
    if command_exists whiptail; then
        TUI_CMD="whiptail"
    elif command_exists dialog; then
        TUI_CMD="dialog"
    else
        print_error "TUI mode requires either 'whiptail' or 'dialog' to be installed"
        return 1
    fi
    return 0
}

# Get terminal dimensions
get_term_size() {
    # Default fallback values
    TERM_HEIGHT=24
    TERM_WIDTH=80
    
    # Try to get actual terminal size
    if command_exists tput; then
        TERM_HEIGHT=$(tput lines)
        TERM_WIDTH=$(tput cols)
    elif command_exists stty; then
        local size
        size=$(stty size 2>/dev/null || echo "24 80")
        TERM_HEIGHT=$(echo "$size" | cut -d' ' -f1)
        TERM_WIDTH=$(echo "$size" | cut -d' ' -f2)
    fi
    
    # Calculate dialog box dimensions (75% of terminal)
    BOX_HEIGHT=$((TERM_HEIGHT * 3 / 4))
    BOX_WIDTH=$((TERM_WIDTH * 3 / 4))
    LIST_HEIGHT=$((BOX_HEIGHT - 8))
    
    # Ensure minimum size
    if (( BOX_HEIGHT < 16 )); then BOX_HEIGHT=16; fi
    if (( BOX_WIDTH < 60 )); then BOX_WIDTH=60; fi
    if (( LIST_HEIGHT < 8 )); then LIST_HEIGHT=8; fi
}

# Create a temporary directory for TUI operations
init_tui() {
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT
}

# Show help for keyboard shortcuts
tui_show_keyboard_help() {
    $TUI_CMD --title "Keyboard Shortcuts" --msgbox "\
AliasMate Keyboard Shortcuts:
---------------------------
* Tab: Navigate between fields
* Enter: Select/Confirm
* Esc: Cancel/Back
* Arrow keys: Navigate menus
* h: Help (this screen)
* q: Quit current screen
* /: Search
* r: Refresh current view
* s: Save command (from list view)
* e: Edit command (from list view)
* d: Delete command (from list view)
* c: Create new category
* p: Change preferences
" $BOX_HEIGHT $BOX_WIDTH
}

# Main TUI entry point
launch_tui() {
    # Verify we have required dependencies
    if ! check_tui_dependencies; then
        print_error "Cannot launch TUI. Try using CLI commands instead."
        exit 1
    fi
    
    # Initialize TUI environment
    init_tui
    
    # Get terminal dimensions
    get_term_size
    
    # Main TUI loop
    while true; do
        local choice
        choice=$($TUI_CMD --title "AliasMate v$VERSION" --menu "Command Alias Manager" $BOX_HEIGHT $BOX_WIDTH $LIST_HEIGHT \
            "1" "List All Commands" \
            "2" "Save New Command" \
            "3" "Run Command" \
            "4" "Edit Command" \
            "5" "Remove Command" \
            "6" "Search Commands" \
            "7" "Manage Categories" \
            "8" "Export/Import" \
            "9" "Statistics" \
            "10" "Configuration" \
            "11" "Synchronization" \
            "12" "Exit" 3>&1 1>&2 2>&3)
        
        # Exit if cancelled
        if [[ $? -ne 0 ]]; then
            clear
            exit 0
        fi
        
        # Process the selected choice
        case "$choice" in
            1) tui_list_commands ;;
            2) tui_save_command ;;
            3) tui_run_command ;;
            4) tui_edit_command ;;
            5) tui_remove_command ;;
            6) tui_search_commands ;;
            7) tui_manage_categories ;;
            8) tui_export_import ;;
            9) tui_show_stats ;;
            10) tui_manage_config ;;
            11) tui_sync ;;
            12) 
                clear
                exit 0
                ;;
        esac
    done
}

# Function to display all commands in TUI with enhanced navigation
tui_list_commands() {
    local temp_file="$TEMP_DIR/commands.txt"
    
    # Run list command and capture output
    list_commands > "$temp_file" 2>&1
    
    # Display the commands with enhanced navigation
    local menu_height=$((BOX_HEIGHT - 10))
    local menu_items=()
    
    # Extract command data
    local cmd_data=$(jq -r '.[] | [.alias, .category, .command] | @tsv' "${TEMP_DIR}/sorted_cmds.json")
    
    # Build menu items
    while IFS=$'\t' read -r alias category cmd; do
        # Truncate command for display
        if [[ ${#cmd} -gt 40 ]]; then
            cmd="${cmd:0:37}..."
        fi
        menu_items+=("$alias" "[$category] $cmd")
    done <<< "$cmd_data"
    
    # Add keyboard shortcut help
    echo "Use arrow keys to navigate, Enter to select, 's' to save new, 'e' to edit, 'd' to delete, 'h' for help" > "$TEMP_DIR/key_help.txt"
    
    # Show menu with enhanced options
    local selected_cmd
    selected_cmd=$($TUI_CMD --title "Commands (${#menu_items[@]} items)" --menu "Select a command:" \
                   $BOX_HEIGHT $BOX_WIDTH $menu_height --cancel-button "Back" --help-button --help-label "Help" \
                   "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    local result=$?
    
    # Handle special button cases
    if [[ $result -eq 0 ]]; then
        # Command selected - show details and actions
        tui_show_command_details "$selected_cmd"
    elif [[ $result -eq 1 ]]; then
        # Cancel/Back pressed
        return 0
    elif [[ $result -eq 2 ]]; then
        # Help button pressed
        tui_show_keyboard_help
        tui_list_commands
    fi
}

# Enhanced command details view with more actions
tui_show_command_details() {
    local alias_name="$1"
    
    # Get command details
    local details_file="$TEMP_DIR/details.txt"
    get_command_details "$alias_name" > "$details_file" 2>&1
    
    # Show the details
    $TUI_CMD --title "Command Details" --scrolltext --textbox "$details_file" $((BOX_HEIGHT + 5)) $BOX_WIDTH
    
    # Offer more actions in a user-friendly menu
    local action
    action=$($TUI_CMD --title "Command: $alias_name" --menu "Choose action:" 15 60 8 \
            "1" "Run command" \
            "2" "Edit command" \
            "3" "Copy command to clipboard" \
            "4" "Show command history" \
            "5" "Create similar command" \
            "6" "Remove command" \
            "7" "Export command" \
            "8" "Back to command list" \
            3>&1 1>&2 2>&3)
    
    if [[ $? -eq 0 ]]; then
        case "$action" in
            1) # Run
                clear
                echo -e "${GREEN}Running command: $alias_name${NC}"
                run_command "$alias_name"
                echo
                read -p "Press Enter to continue..."
                tui_show_command_details "$alias_name"
                ;;
            2) # Edit
                tui_edit_specific_command "$alias_name"
                ;;
            3) # Copy to clipboard
                if command_exists pbcopy; then
                    jq -r '.command' "$COMMAND_STORE/$alias_name.json" | pbcopy
                    $TUI_CMD --title "Clipboard" --msgbox "Command copied to clipboard!" 8 40
                elif command_exists xclip; then
                    jq -r '.command' "$COMMAND_STORE/$alias_name.json" | xclip -selection clipboard
                    $TUI_CMD --title "Clipboard" --msgbox "Command copied to clipboard!" 8 40
                else
                    $TUI_CMD --title "Error" --msgbox "No clipboard utility found (pbcopy/xclip)" 8 40
                fi
                tui_show_command_details "$alias_name"
                ;;
            4) # History
                tui_show_command_history "$alias_name"
                tui_show_command_details "$alias_name"
                ;;
            5) # Create similar
                tui_clone_command "$alias_name"
                ;;
            6) # Remove
                tui_remove_specific_command "$alias_name"
                ;;
            7) # Export 
                tui_export_command "$alias_name"
                tui_show_command_details "$alias_name"
                ;;
            8) # Back
                return 0
                ;;
        esac
    fi
}

# New function to clone/create similar command
tui_clone_command() {
    local source_alias="$1"
    
    # Get source command details
    local cmd=$(jq -r '.command' "$COMMAND_STORE/$source_alias.json")
    local category=$(jq -r '.category' "$COMMAND_STORE/$source_alias.json")
    local path=$(jq -r '.path' "$COMMAND_STORE/$source_alias.json")
    
    # Ask for new alias name
    local new_alias
    new_alias=$($TUI_CMD --title "Clone Command" --inputbox "Enter new alias name:" 10 60 "${source_alias}_copy" 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$new_alias" ]]; then
        return 0
    fi
    
    # Validate new alias
    if ! validate_alias "$new_alias"; then
        $TUI_CMD --title "Invalid Alias" --msgbox "Invalid alias name. Use only letters, numbers, underscore and hyphen." 10 60
        return 1
    fi
    
    # Check if new alias exists
    if [[ -f "$COMMAND_STORE/$new_alias.json" ]]; then
        $TUI_CMD --title "Alias Exists" --yesno "Alias '$new_alias' already exists. Overwrite?" 10 60
        if [[ $? -ne 0 ]]; then
            return 0
        fi
    fi
    
    # Allow editing the command
    local temp_file=$(mktemp)
    echo "$cmd" > "$temp_file"
    
    $TUI_CMD --title "Edit Command" --yesno "Do you want to edit the command?" 10 60
    
    if [[ $? -eq 0 ]]; then
        ${EDITOR:-nano} "$temp_file"
        cmd=$(cat "$temp_file")
    fi
    
    rm -f "$temp_file"
    
    # Create the new command
    local timestamp=$(date +%s)
    local command_file="$COMMAND_STORE/$new_alias.json"
    
    cat > "$command_file" << EOF
{
  "alias": "$new_alias",
  "command": $(jq -n --arg cmd "$cmd" '$cmd'),
  "path": "$path",
  "category": "$category",
  "created": $timestamp,
  "modified": $timestamp,
  "runs": 0,
  "last_run": null
}
EOF
    
    $TUI_CMD --title "Success" --msgbox "Command cloned successfully as '$new_alias'!" 10 60
    return 0
}

# New function to show command execution history
tui_show_command_history() {
    local alias_name="$1"
    local stats_file="$COMMAND_STORE/stats/${alias_name}.csv"
    
    if [[ ! -f "$stats_file" || $(wc -l < "$stats_file") -le 1 ]]; then
        $TUI_CMD --title "No History" --msgbox "No execution history available for '$alias_name'." 10 60
        return 0
    fi
    
    # Format history data for display
    local history_file="$TEMP_DIR/history.txt"
    echo "=== Execution History for: $alias_name ===" > "$history_file"
    echo "" >> "$history_file"
    
    # Process the most recent 20 executions
    tail -n 20 "$stats_file" | tac | while IFS=, read -r ts duration exit_code; do
        # Skip header
        if [[ "$ts" == "timestamp" ]]; then continue; fi
        
        # Format timestamp
        local run_time=$(date -d "@$ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || 
                         date -r "$ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        
        # Format status
        local status="Success"
        if [[ "$exit_code" != "0" ]]; then
            status="Failed (exit code: $exit_code)"
        fi
        
        echo "- $run_time: $status, took $(printf "%.2f" "$duration")s" >> "$history_file"
    done
    
    # Show the history
    $TUI_CMD --title "Command History" --scrolltext --textbox "$history_file" $BOX_HEIGHT $BOX_WIDTH
}

# Enhanced function to export a specific command
tui_export_command() {
    local alias_name="$1"
    
    local format
    format=$($TUI_CMD --title "Export Format" --menu "Select export format:" 12 60 3 \
            "json" "JSON format (recommended)" \
            "yaml" "YAML format" \
            "csv" "CSV format" \
            3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 ]]; then
        return 0
    fi
    
    local output_file
    output_file=$($TUI_CMD --title "Export File" --inputbox "Enter output filename:" 10 60 "aliasmate_${alias_name}_$(date +%Y%m%d).$format" 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$output_file" ]]; then
        return 0
    fi
    
    export_commands "$alias_name" --format "$format" --output "$output_file"
    $TUI_CMD --title "Success" --msgbox "Command '$alias_name' exported to '$output_file' successfully." 10 60
    
    return 0
}

# Function to save a new command in TUI
tui_save_command() {
    local alias_name
    alias_name=$($TUI_CMD --title "Save Command" --inputbox "Enter alias name:" 10 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$alias_name" ]]; then
        return 0
    fi
    
    local command
    command=$($TUI_CMD --title "Save Command" --inputbox "Enter command:" 10 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$command" ]]; then
        return 0
    fi
    
    save_command "$alias_name" "$command"
    $TUI_CMD --title "Success" --msgbox "Command '$alias_name' saved successfully." 10 60
}

# Function to run a command in TUI
tui_run_command() {
    local alias_name
    alias_name=$($TUI_CMD --title "Run Command" --inputbox "Enter alias name:" 10 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$alias_name" ]]; then
        return 0
    fi
    
    run_command "$alias_name"
    $TUI_CMD --title "Command Run" --msgbox "Command execution complete." 10 60
}

# Function to edit a command in TUI
tui_edit_command() {
    local alias_name
    alias_name=$($TUI_CMD --title "Edit Command" --inputbox "Enter alias name:" 10 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$alias_name" ]]; then
        return 0
    fi
    
    edit_command "$alias_name"
    $TUI_CMD --title "Success" --msgbox "Command '$alias_name' edited successfully." 10 60
}

# Function to remove a command in TUI
tui_remove_command() {
    local alias_name
    alias_name=$($TUI_CMD --title "Remove Command" --inputbox "Enter alias name:" 10 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$alias_name" ]]; then
        return 0
    fi
    
    remove_command "$alias_name"
    $TUI_CMD --title "Success" --msgbox "Command '$alias_name' removed successfully." 10 60
}

# Function to search commands in TUI
tui_search_commands() {
    local search_term
    search_term=$($TUI_CMD --title "Search Commands" --inputbox "Enter search term:" 10 60 3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 || -z "$search_term" ]]; then
        return 0
    fi
    
    local temp_file="$TEMP_DIR/search_results.txt"
    search_commands "$search_term" > "$temp_file" 2>&1
    
    # Show the search results
    $TUI_CMD --title "Search Results" --scrolltext --textbox "$temp_file" $BOX_HEIGHT $BOX_WIDTH
}

# Function to manage categories in TUI
tui_manage_categories() {
    local action
    action=$($TUI_CMD --title "Category Management" --menu "Choose action:" 12 60 4 \
            "1" "List categories" \
            "2" "Add a category" \
            "3" "Remove a category" \
            "4" "Rename a category" \
            3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 ]]; then
        return 0
    fi
    
    case "$action" in
        1)
            local temp_file="$TEMP_DIR/categories.txt"
            list_categories > "$temp_file" 2>&1
            $TUI_CMD --title "Categories" --scrolltext --textbox "$temp_file" $BOX_HEIGHT $BOX_WIDTH
            ;;
        2)
            local new_category
            new_category=$($TUI_CMD --title "Add Category" --inputbox "Enter new category name:" 10 60 3>&1 1>&2 2>&3)
            
            if [[ $? -eq 0 && -n "$new_category" ]]; then
                add_category "$new_category"
                $TUI_CMD --title "Success" --msgbox "Category '$new_category' added successfully." 10 60
            fi
            ;;
        3)
            local category_name
            category_name=$($TUI_CMD --title "Remove Category" --inputbox "Enter category name:" 10 60 3>&1 1>&2 2>&3)
            
            if [[ $? -eq 0 && -n "$category_name" ]]; then
                remove_category "$category_name"
                $TUI_CMD --title "Success" --msgbox "Category '$category_name' removed successfully." 10 60
            fi
            ;;
        4)
            local old_name
            old_name=$($TUI_CMD --title "Rename Category" --inputbox "Enter old category name:" 10 60 3>&1 1>&2 2>&3)
            
            if [[ $? -eq 0 && -n "$old_name" ]]; then
                local new_name
                new_name=$($TUI_CMD --title "Rename Category" --inputbox "Enter new category name:" 10 60 3>&1 1>&2 2>&3)
                
                if [[ $? -eq 0 && -n "$new_name" ]]; then
                    rename_category "$old_name" "$new_name"
                    $TUI_CMD --title "Success" --msgbox "Category renamed from '$old_name' to '$new_name' successfully." 10 60
                fi
            fi
            ;;
    esac
}

# Function to manage export/import in TUI
tui_export_import() {
    local action
    action=$($TUI_CMD --title "Export/Import" --menu "Choose action:" 12 60 3 \
            "1" "Export commands" \
            "2" "Import commands" \
            "3" "Export specific command" \
            3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 ]]; then
        return 0
    fi
    
    case "$action" in
        1)
            local format
            format=$($TUI_CMD --title "Export Format" --menu "Select export format:" 12 60 3 \
                    "json" "JSON format (recommended)" \
                    "yaml" "YAML format" \
                    "csv" "CSV format" \
                    3>&1 1>&2 2>&3)
            
            if [[ $? -ne 0 ]]; then
                return 0
            fi
            
            local output_file
            output_file=$($TUI_CMD --title "Export File" --inputbox "Enter output filename:" 10 60 "aliasmate_export_$(date +%Y%m%d).$format" 3>&1 1>&2 2>&3)
            
            if [[ $? -eq 0 && -n "$output_file" ]]; then
                export_commands --format "$format" --output "$output_file"
                $TUI_CMD --title "Success" --msgbox "Commands exported to '$output_file' successfully." 10 60
            fi
            ;;
        2)
            local file
            file=$($TUI_CMD --title "Import File" --inputbox "Enter import filename:" 10 60 3>&1 1>&2 2>&3)
            
            if [[ $? -ne 0 || -z "$file" ]]; then
                return 0
            fi
            
            if [[ ! -f "$file" ]]; then
                $TUI_CMD --title "Error" --msgbox "File '$file' not found." 10 60
                return 1
            fi
            
            $TUI_CMD --title "Import Options" --yesno "Merge with existing commands?" 10 60
            local merge=$?
            
            if [[ $merge -eq 0 ]]; then
                import_commands "$file" --merge
            else
                import_commands "$file"
            fi
            
            $TUI_CMD --title "Success" --msgbox "Commands imported from '$file' successfully." 10 60
            ;;
        3)
            local selected_cmd
            selected_cmd=$($TUI_CMD --title "Export Command" --inputbox "Enter command alias to export:" 10 60 3>&1 1>&2 2>&3)
            
            if [[ $? -ne 0 || -z "$selected_cmd" ]]; then
                return 0
            fi
            
            local format
            format=$($TUI_CMD --title "Export Format" --menu "Select export format:" 12 60 3 \
                    "json" "JSON format (recommended)" \
                    "yaml" "YAML format" \
                    "csv" "CSV format" \
                    3>&1 1>&2 2>&3)
            
            if [[ $? -ne 0 ]]; then
                return 0
            fi
            
            local output_file
            output_file=$($TUI_CMD --title "Export File" --inputbox "Enter output filename:" 10 60 "aliasmate_${selected_cmd}_$(date +%Y%m%d).$format" 3>&1 1>&2 2>&3)
            
            if [[ $? -eq 0 && -n "$output_file" ]]; then
                export_commands "$selected_cmd" --format "$format" --output "$output_file"
                $TUI_CMD --title "Success" --msgbox "Command '$selected_cmd' exported to '$output_file' successfully." 10 60
            fi
            ;;
    esac
}

# Function to show statistics in TUI
tui_show_stats() {
    local temp_file="$TEMP_DIR/stats.txt"
    
    # Run stats command and capture output
    show_stats > "$temp_file" 2>&1
    
    # Show the stats
    $TUI_CMD --title "Command Statistics" --scrolltext --textbox "$temp_file" $((BOX_HEIGHT + 5)) $BOX_WIDTH
    
    # Offer reset option
    $TUI_CMD --title "Reset Stats" --yesno "Do you want to reset all command statistics?" 10 60
    
    if [[ $? -eq 0 ]]; then
        show_stats --reset
        $TUI_CMD --title "Success" --msgbox "Statistics have been reset." 10 60
    fi
}

# Function to manage configuration in TUI
tui_manage_config() {
    while true; do
        local action
        action=$($TUI_CMD --title "Configuration" --menu "Choose action:" 14 60 7 \
                "1" "Show current configuration" \
                "2" "Set editor" \
                "3" "Set default UI (cli/tui)" \
                "4" "Toggle version check" \
                "5" "Toggle statistics" \
                "6" "Set command store location" \
                "7" "Reset configuration" \
                3>&1 1>&2 2>&3)
        
        if [[ $? -ne 0 ]]; then
            return 0
        fi
        
        case "$action" in
            1)
                local temp_file="$TEMP_DIR/config.txt"
                manage_config list > "$temp_file" 2>&1
                $TUI_CMD --title "Configuration" --scrolltext --textbox "$temp_file" $BOX_HEIGHT $BOX_WIDTH
                ;;
            2)
                local current_editor=$(get_config EDITOR)
                local new_editor
                new_editor=$($TUI_CMD --title "Set Editor" --inputbox "Enter preferred editor:" 10 60 "$current_editor" 3>&1 1>&2 2>&3)
                
                if [[ $? -eq 0 && -n "$new_editor" ]]; then
                    manage_config set EDITOR "$new_editor"
                    $TUI_CMD --title "Success" --msgbox "Editor set to '$new_editor'." 10 60
                fi
                ;;
            3)
                local current_ui=$(get_config DEFAULT_UI)
                local ui_choice
                ui_choice=$($TUI_CMD --title "Default UI" --menu "Choose default interface:" 10 60 2 \
                          "cli" "Command Line Interface" \
                          "tui" "Text User Interface" \
                          3>&1 1>&2 2>&3)
                
                if [[ $? -eq 0 ]]; then
                    manage_config set DEFAULT_UI "$ui_choice"
                    $TUI_CMD --title "Success" --msgbox "Default UI set to '$ui_choice'." 10 60
                fi
                ;;
            4)
                local current_check=$(get_config VERSION_CHECK)
                local new_value
                
                if [[ "$current_check" == "true" ]]; then
                    new_value="false"
                    message="Version check will be disabled."
                else
                    new_value="true"
                    message="Version check will be enabled."
                fi
                
                $TUI_CMD --title "Version Check" --yesno "Current setting: $current_check\n\n$message\n\nIs this correct?" 12 60
                
                if [[ $? -eq 0 ]]; then
                    manage_config set VERSION_CHECK "$new_value"
                    $TUI_CMD --title "Success" --msgbox "Version check set to '$new_value'." 10 60
                fi
                ;;
            5)
                local current_stats=$(get_config ENABLE_STATS)
                local new_value
                
                if [[ "$current_stats" == "true" ]]; then
                    new_value="false"
                    message="Statistics tracking will be disabled."
                else
                    new_value="true"
                    message="Statistics tracking will be enabled."
                fi
                
                $TUI_CMD --title "Statistics" --yesno "Current setting: $current_stats\n\n$message\n\nIs this correct?" 12 60
                
                if [[ $? -eq 0 ]]; then
                    manage_config set ENABLE_STATS "$new_value"
                    $TUI_CMD --title "Success" --msgbox "Statistics tracking set to '$new_value'." 10 60
                fi
                ;;
            6)
                local current_store=$(get_config COMMAND_STORE)
                local new_store
                new_store=$($TUI_CMD --title "Command Store" --inputbox "Enter command store path:" 10 60 "$current_store" 3>&1 1>&2 2>&3)
                
                if [[ $? -eq 0 && -n "$new_store" ]]; then
                    $TUI_CMD --title "Warning" --yesno "Changing the command store location will not move your existing commands.\n\nDo you want to continue?" 12 60
                    
                    if [[ $? -eq 0 ]]; then
                        manage_config set COMMAND_STORE "$new_store"
                        $TUI_CMD --title "Success" --msgbox "Command store location set to '$new_store'.\n\nYou may need to restart AliasMate for changes to take effect." 12 60
                    fi
                fi
                ;;
            7)
                $TUI_CMD --title "Reset Configuration" --yesno "This will reset all configuration to defaults.\n\nAre you sure?" 10 60
                
                if [[ $? -eq 0 ]]; then
                    manage_config reset --force
                    $TUI_CMD --title "Success" --msgbox "Configuration has been reset to defaults.\n\nYou may need to restart AliasMate for changes to take effect." 12 60
                    return 0
                fi
                ;;
        esac
    done
}

# Function to manage synchronization in TUI
tui_sync() {
    local action
    action=$($TUI_CMD --title "Synchronization" --menu "Choose action:" 12 60 4 \
            "1" "Check sync status" \
            "2" "Setup sync" \
            "3" "Push commands to cloud" \
            "4" "Pull commands from cloud" \
            3>&1 1>&2 2>&3)
    
    if [[ $? -ne 0 ]]; then
        return 0
    fi
    
    case "$action" in
        1)
            local temp_file="$TEMP_DIR/sync_status.txt"
            sync_commands status > "$temp_file" 2>&1
            $TUI_CMD --title "Sync Status" --scrolltext --textbox "$temp_file" $BOX_HEIGHT $BOX_WIDTH
            ;;
        2)
            local provider
            provider=$($TUI_CMD --title "Sync Provider" --menu "Select sync provider:" 15 60 4 \
                      "github" "GitHub (recommended)" \
                      "gitlab" "GitLab" \
                      "dropbox" "Dropbox" \
                      "local" "Local directory" \
                      3>&1 1>&2 2>&3)
            
            if [[ $? -ne 0 ]]; then
                return 0
            fi
            
            case "$provider" in
                github|gitlab)
                    local token
                    token=$($TUI_CMD --title "API Token" --passwordbox "Enter your personal access token:" 10 60 3>&1 1>&2 2>&3)
                    
                    if [[ $? -ne 0 || -z "$token" ]]; then
                        return 0
                    fi
                    
                    local repo
                    repo=$($TUI_CMD --title "Repository" --inputbox "Enter repository (username/repo):" 10 60 3>&1 1>&2 2>&3)
                    
                    if [[ $? -ne 0 || -z "$repo" ]]; then
                        return 0
                    fi
                    
                    setup_sync --provider "$provider" --token "$token" --repo "$repo"
                    ;;
                dropbox)
                    local token
                    token=$($TUI_CMD --title "API Token" --passwordbox "Enter your Dropbox API token:" 10 60 3>&1 1>&2 2>&3)
                    
                    if [[ $? -ne 0 || -z "$token" ]]; then
                        return 0
                    fi
                    
                    local path
                    path=$($TUI_CMD --title "Path" --inputbox "Enter Dropbox path (default: /aliasmate_sync):" 10 60 "/aliasmate_sync" 3>&1 1>&2 2>&3)
                    
                    if [[ $? -ne 0 ]]; then
                        return 0
                    fi
                    
                    setup_sync --provider "$provider" --token "$token" --repo "$path"
                    ;;
                local)
                    local path
                    path=$($TUI_CMD --title "Sync Directory" --inputbox "Enter directory path for local sync:" 10 60 3>&1 1>&2 2>&3)
                    
                    if [[ $? -ne 0 || -z "$path" ]]; then
                        return 0
                    fi
                    
                    setup_sync --provider "$provider" --repo "$path"
                    ;;
            esac
            
            $TUI_CMD --title "Success" --msgbox "Sync setup completed successfully." 10 60
            ;;
        3)
            $TUI_CMD --title "Push Commands" --infobox "Pushing commands to cloud..." 10 60
            
            if ! sync_commands push > "$TEMP_DIR/push_output.txt" 2>&1; then
                local error_msg=$(grep "Error" "$TEMP_DIR/push_output.txt" | head -1)
                $TUI_CMD --title "Error" --msgbox "Failed to push commands: $error_msg" 10 60
                return 1
            fi
            
            $TUI_CMD --title "Success" --msgbox "Commands pushed to cloud successfully." 10 60
            ;;
        4)
            $TUI_CMD --title "Pull Commands" --infobox "Pulling commands from cloud..." 10 60
            
            if ! sync_commands pull > "$TEMP_DIR/pull_output.txt" 2>&1; then
                local error_msg=$(grep "Error" "$TEMP_DIR/pull_output.txt" | head -1)
                $TUI_CMD --title "Error" --msgbox "Failed to pull commands: $error_msg" 10 60
                return 1
            fi
            
            $TUI_CMD --title "Success" --msgbox "Commands pulled from cloud successfully." 10 60
            ;;
    esac
}