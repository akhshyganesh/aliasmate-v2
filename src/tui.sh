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

# Function to list commands in TUI
tui_list_commands() {
    local temp_file="$TEMP_DIR/commands.txt"
    
    # Run list command and capture output
    list_commands > "$temp_file" 2>&1
    
    # Show the list
    $TUI_CMD --title "Commands" --scrolltext --textbox "$temp_file" $BOX_HEIGHT $BOX_WIDTH
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