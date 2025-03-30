#!/usr/bin/env bash
# AliasMate v2 - Cloud synchronization module

# Available sync providers
SYNC_PROVIDERS=(
    "github"
    "gitlab"
    "dropbox"
    "local"
)

# Setup cloud synchronization
setup_sync() {
    local provider=""
    local token=""
    local repo=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --provider)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing provider name after --provider"
                    return 1
                fi
                provider="$2"
                shift 2
                ;;
            --token)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing token after --token"
                    return 1
                fi
                token="$2"
                shift 2
                ;;
            --repo)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing repository name after --repo"
                    return 1
                fi
                repo="$2"
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
    
    # Interactive setup if no arguments provided
    if [[ -z "$provider" ]]; then
        # Display available providers
        echo -e "${CYAN}Available Sync Providers:${NC}"
        for i in "${!SYNC_PROVIDERS[@]}"; do
            echo -e "$((i+1)). ${YELLOW}${SYNC_PROVIDERS[$i]}${NC}"
        done
        echo
        
        # Prompt for provider
        read -p "Select provider [1-${#SYNC_PROVIDERS[@]}]: " choice
        if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#SYNC_PROVIDERS[@]} )); then
            print_error "Invalid selection"
            return 1
        fi
        
        provider="${SYNC_PROVIDERS[$((choice-1))]}"
    fi
    
    # Validate provider
    local valid_provider=false
    for p in "${SYNC_PROVIDERS[@]}"; do
        if [[ "$provider" == "$p" ]]; then
            valid_provider=true
            break
        fi
    done
    
    if [[ "$valid_provider" != "true" ]]; then
        print_error "Invalid provider: $provider"
        print_info "Valid providers: ${SYNC_PROVIDERS[*]}"
        return 1
    fi
    
    # Provider-specific setup
    case "$provider" in
        github|gitlab)
            # Get token if not provided
            if [[ -z "$token" ]]; then
                read -p "Enter personal access token for $provider: " token
                if [[ -z "$token" ]]; then
                    print_error "Token is required"
                    return 1
                fi
            fi
            
            # Get repository if not provided
            if [[ -z "$repo" ]]; then
                read -p "Enter repository name (user/repo): " repo
                if [[ -z "$repo" ]]; then
                    print_error "Repository is required"
                    return 1
                fi
            fi
            
            # Validate token and repo by making a test API call
            local api_url=""
            if [[ "$provider" == "github" ]]; then
                api_url="https://api.github.com/repos/$repo"
            else
                api_url="https://gitlab.com/api/v4/projects/$(echo "$repo" | tr '/' '%2F')"
            fi
            
            if ! curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $token" "$api_url" | grep -q "20[0-9]"; then
                print_error "Failed to validate token and repository"
                return 1
            fi
            ;;
            
        dropbox)
            # Get token if not provided
            if [[ -z "$token" ]]; then
                read -p "Enter Dropbox API token: " token
                if [[ -z "$token" ]]; then
                    print_error "Token is required"
                    return 1
                fi
            fi
            
            # Validate token by making a test API call
            if ! curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" "https://api.dropboxapi.com/2/users/get_current_account" | grep -q "20[0-9]"; then
                print_error "Failed to validate Dropbox token"
                return 1
            fi
            
            # Set repo to a default path
            if [[ -z "$repo" ]]; then
                repo="/aliasmate_sync"
            fi
            ;;
            
        local)
            # For local sync, repo is the path to sync directory
            if [[ -z "$repo" ]]; then
                read -p "Enter path to sync directory: " repo
                if [[ -z "$repo" ]]; then
                    print_error "Sync directory is required"
                    return 1
                fi
            fi
            
            # Ensure the directory exists
            mkdir -p "$repo"
            
            # No token needed for local sync
            token=""
            ;;
    esac
    
    # Save sync configuration
    set_config "SYNC_ENABLED" "true"
    set_config "SYNC_PROVIDER" "$provider"
    set_config "SYNC_TOKEN" "$token"
    set_config "SYNC_REPO" "$repo"
    
    print_success "Sync configured successfully with $provider"
    print_info "You can now use 'aliasmate sync push' and 'aliasmate sync pull' to synchronize your commands"
    
    # Ask if user wants to push or pull immediately
    if confirm "Do you want to push your current commands now?" "y"; then
        sync_push
    elif confirm "Do you want to pull commands from the remote source now?" "n"; then
        sync_pull
    fi
    
    return 0
}

# Push commands to remote storage
sync_push() {
    # Check if sync is enabled and configured
    if [[ "$SYNC_ENABLED" != "true" ]]; then
        print_error "Sync is not enabled. Run 'aliasmate sync setup' first."
        return 1
    fi
    
    if [[ -z "$SYNC_PROVIDER" ]]; then
        print_error "Sync provider is not configured. Run 'aliasmate sync setup' first."
        return 1
    fi
    
    print_info "Pushing commands to ${SYNC_PROVIDER}..."
    
    # Create a temp directory for sync
    local temp_dir
    temp_dir=$(mktemp -d)
    local archive="$temp_dir/aliasmate_sync.tar.gz"
    
    # Export all commands to the temp directory
    mkdir -p "$temp_dir/commands"
    cp "$COMMAND_STORE"/*.json "$temp_dir/commands/" 2>/dev/null
    
    # Export categories
    if [[ -d "$COMMAND_STORE/categories" ]]; then
        mkdir -p "$temp_dir/categories"
        cp -r "$COMMAND_STORE/categories"/* "$temp_dir/categories/" 2>/dev/null
    fi
    
    # Create metadata file with timestamp
    local timestamp=$(date +%s)
    echo "{\"timestamp\": $timestamp, \"version\": \"$VERSION\"}" > "$temp_dir/metadata.json"
    
    # Create archive
    tar -czf "$archive" -C "$temp_dir" commands categories metadata.json
    
    # Provider-specific push
    case "$SYNC_PROVIDER" in
        github|gitlab)
            # Base64 encode the archive
            local content
            content=$(base64 "$archive")
            
            # API endpoint
            local api_url=""
            local content_path="aliasmate_sync.tar.gz"
            if [[ "$SYNC_PROVIDER" == "github" ]]; then
                api_url="https://api.github.com/repos/$SYNC_REPO/contents/$content_path"
            else
                # For GitLab, we need URL-encoded project ID and file path
                local project_id=$(echo "$SYNC_REPO" | tr '/' '%2F')
                api_url="https://gitlab.com/api/v4/projects/$project_id/repository/files/$content_path"
            fi
            
            # Check if file already exists to get SHA
            local sha=""
            if [[ "$SYNC_PROVIDER" == "github" ]]; then
                sha=$(curl -s -H "Authorization: token $SYNC_TOKEN" "$api_url" | jq -r '.sha // ""')
            fi
            
            # Push to remote
            local response=""
            if [[ "$SYNC_PROVIDER" == "github" ]]; then
                # GitHub API
                local data="{\"message\":\"Update aliasmate sync\",\"content\":\"$content\""
                if [[ -n "$sha" ]]; then
                    data="$data,\"sha\":\"$sha\""
                fi
                data="$data}"
                
                response=$(curl -s -X PUT -H "Authorization: token $SYNC_TOKEN" -d "$data" "$api_url")
            else
                # GitLab API
                local data="{\"branch\":\"master\",\"content\":\"$content\",\"commit_message\":\"Update aliasmate sync\"}"
                response=$(curl -s -X PUT -H "PRIVATE-TOKEN: $SYNC_TOKEN" -d "$data" "$api_url")
            fi
            
            if [[ "$response" =~ "error" ]]; then
                print_error "Failed to push to $SYNC_PROVIDER: $(echo "$response" | jq -r '.message // "Unknown error"')"
                rm -rf "$temp_dir"
                return 1
            fi
            ;;
            
        dropbox)
            # Dropbox API endpoint
            local api_url="https://content.dropboxapi.com/2/files/upload"
            local path="$SYNC_REPO/aliasmate_sync.tar.gz"
            
            # Push to Dropbox
            local response=$(curl -s -X POST "$api_url" \
                --header "Authorization: Bearer $SYNC_TOKEN" \
                --header "Dropbox-API-Arg: {\"path\":\"$path\",\"mode\":\"overwrite\"}" \
                --header "Content-Type: application/octet-stream" \
                --data-binary @"$archive")
            
            if [[ "$response" =~ "error" ]]; then
                print_error "Failed to push to Dropbox: $(echo "$response" | jq -r '.error_summary // "Unknown error"')"
                rm -rf "$temp_dir"
                return 1
            fi
            ;;
            
        local)
            # For local sync, just copy the archive to the sync directory
            cp "$archive" "$SYNC_REPO/aliasmate_sync.tar.gz"
            ;;
    esac
    
    # Clean up
    rm -rf "$temp_dir"
    
    print_success "Commands pushed successfully to $SYNC_PROVIDER"
    return 0
}

# Pull commands from remote storage
sync_pull() {
    # Check if sync is enabled and configured
    if [[ "$SYNC_ENABLED" != "true" ]]; then
        print_error "Sync is not enabled. Run 'aliasmate sync setup' first."
        return 1
    fi
    
    if [[ -z "$SYNC_PROVIDER" ]]; then
        print_error "Sync provider is not configured. Run 'aliasmate sync setup' first."
        return 1
    fi
    
    print_info "Pulling commands from ${SYNC_PROVIDER}..."
    
    # Create a temp directory for sync
    local temp_dir
    temp_dir=$(mktemp -d)
    local archive="$temp_dir/aliasmate_sync.tar.gz"
    
    # Provider-specific pull
    case "$SYNC_PROVIDER" in
        github|gitlab)
            # API endpoint
            local api_url=""
            local content_path="aliasmate_sync.tar.gz"
            if [[ "$SYNC_PROVIDER" == "github" ]]; then
                api_url="https://api.github.com/repos/$SYNC_REPO/contents/$content_path"
            else
                # For GitLab, we need URL-encoded project ID and file path
                local project_id=$(echo "$SYNC_REPO" | tr '/' '%2F')
                api_url="https://gitlab.com/api/v4/projects/$project_id/repository/files/$content_path"
            fi
            
            # Get content from remote
            local response=""
            if [[ "$SYNC_PROVIDER" == "github" ]]; then
                response=$(curl -s -H "Authorization: token $SYNC_TOKEN" "$api_url")
                
                # Check if file exists
                if [[ "$response" =~ "Not Found" ]]; then
                    print_error "No sync data found on GitHub"
                    rm -rf "$temp_dir"
                    return 1
                fi
                
                # Decode content
                echo "$response" | jq -r '.content' | base64 -d > "$archive"
            else
                response=$(curl -s -H "PRIVATE-TOKEN: $SYNC_TOKEN" "$api_url/raw?ref=master" -o "$archive")
                
                # Check if file exists
                if [[ ! -s "$archive" ]]; then
                    print_error "No sync data found on GitLab"
                    rm -rf "$temp_dir"
                    return 1
                fi
            fi
            ;;
            
        dropbox)
            # Dropbox API endpoint
            local api_url="https://content.dropboxapi.com/2/files/download"
            local path="$SYNC_REPO/aliasmate_sync.tar.gz"
            
            # Pull from Dropbox
            local response=$(curl -s -X POST "$api_url" \
                --header "Authorization: Bearer $SYNC_TOKEN" \
                --header "Dropbox-API-Arg: {\"path\":\"$path\"}" \
                -o "$archive")
            
            # Check if file exists
            if [[ ! -s "$archive" ]]; then
                print_error "No sync data found on Dropbox"
                rm -rf "$temp_dir"
                return 1
            fi
            ;;
            
        local)
            # For local sync, just copy the archive from the sync directory
            if [[ ! -f "$SYNC_REPO/aliasmate_sync.tar.gz" ]]; then
                print_error "No sync data found in $SYNC_REPO"
                rm -rf "$temp_dir"
                return 1
            fi
            
            cp "$SYNC_REPO/aliasmate_sync.tar.gz" "$archive"
            ;;
    esac
    
    # Extract archive
    tar -xzf "$archive" -C "$temp_dir"
    
    # Check for metadata
    if [[ ! -f "$temp_dir/metadata.json" ]]; then
        print_error "Invalid sync data: metadata.json not found"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check for commands
    if [[ ! -d "$temp_dir/commands" ]]; then
        print_error "Invalid sync data: commands directory not found"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Confirm import
    local remote_timestamp=$(jq -r '.timestamp' "$temp_dir/metadata.json")
    local remote_date=$(date -d "@$remote_timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || 
                        date -r "$remote_timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
    local cmd_count=$(find "$temp_dir/commands" -name "*.json" | wc -l)
    
    echo -e "Found ${YELLOW}$cmd_count${NC} commands from ${CYAN}$remote_date${NC}"
    
    if ! confirm "Do you want to import these commands? This may overwrite your existing commands." "n"; then
        print_info "Import cancelled"
        rm -rf "$temp_dir"
        return 0
    fi
    
    # Import commands
    echo -e "Importing commands..."
    
    # Import categories
    if [[ -d "$temp_dir/categories" ]]; then
        mkdir -p "$COMMAND_STORE/categories"
        cp -r "$temp_dir/categories"/* "$COMMAND_STORE/categories/" 2>/dev/null
    fi
    
    # Import commands
    local imported=0
    find "$temp_dir/commands" -name "*.json" | while read -r cmd_file; do
        local alias_name=$(basename "$cmd_file" .json)
        cp "$cmd_file" "$COMMAND_STORE/$alias_name.json"
        ((imported++))
    done
    
    # Clean up
    rm -rf "$temp_dir"
    
    print_success "Imported $imported commands from $SYNC_PROVIDER"
    return 0
}

# Check sync status
sync_status() {
    echo -e "${CYAN}Sync Status:${NC}"
    echo -e "${CYAN}============${NC}"
    
    if [[ "$SYNC_ENABLED" != "true" ]]; then
        echo -e "Sync is ${RED}disabled${NC}"
        echo -e "Run 'aliasmate sync setup' to configure synchronization"
        return 0
    fi
    
    echo -e "Sync is ${GREEN}enabled${NC}"
    echo -e "Provider: ${YELLOW}$SYNC_PROVIDER${NC}"
    echo -e "Repository/Path: ${YELLOW}$SYNC_REPO${NC}"
    
    # Count local commands
    local local_count=$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" | wc -l)
    echo -e "Local commands: ${YELLOW}$local_count${NC}"
    
    # Check when was the last sync
    local last_sync_file="$COMMAND_STORE/.last_sync"
    if [[ -f "$last_sync_file" ]]; then
        local last_timestamp=$(cat "$last_sync_file")
        local last_date=$(date -d "@$last_timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || 
                          date -r "$last_timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        echo -e "Last sync: ${CYAN}$last_date${NC}"
    else
        echo -e "Last sync: ${YELLOW}Never${NC}"
    fi
    
    return 0
}

# Main sync command handler
sync_commands() {
    local subcommand="$1"
    shift
    
    case "$subcommand" in
        setup)
            setup_sync "$@"
            ;;
        push)
            sync_push "$@"
            
            # Record last sync time
            if [[ $? -eq 0 ]]; then
                local timestamp=$(date +%s)
                echo "$timestamp" > "$COMMAND_STORE/.last_sync"
            fi
            ;;
        pull)
            sync_pull "$@"
            
            # Record last sync time
            if [[ $? -eq 0 ]]; then
                local timestamp=$(date +%s)
                echo "$timestamp" > "$COMMAND_STORE/.last_sync"
            fi
            ;;
        status|"")
            sync_status "$@"
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            print_info "Valid subcommands: setup, push, pull, status"
            return 1
            ;;
    esac
}
