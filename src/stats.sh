#!/usr/bin/env bash
# AliasMate v2 - Statistics module

# Show command usage statistics
show_stats() {
    local reset=false
    local export_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --reset)
                reset=true
                shift
                ;;
            --export)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing filename after --export"
                    return 1
                fi
                export_file="$2"
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
    
    # Handle reset request
    if [[ "$reset" == "true" ]]; then
        if confirm "Are you sure you want to reset all command statistics?" "n"; then
            local stats_dir="$COMMAND_STORE/stats"
            if [[ -d "$stats_dir" ]]; then
                rm -rf "$stats_dir"
                mkdir -p "$stats_dir"
                
                # Reset stats in command files too
                find "$COMMAND_STORE" -maxdepth 1 -name "*.json" | while read -r cmd_file; do
                    jq '.runs = 0 | .last_run = null | .last_exit_code = null | .last_duration = null' "$cmd_file" > "${cmd_file}.tmp" && 
                    mv "${cmd_file}.tmp" "$cmd_file"
                done
                
                print_success "Command statistics have been reset"
            else
                print_info "No statistics found to reset"
            fi
        else
            print_info "Operation cancelled"
        fi
        return 0
    fi
    
    # Check if any commands exist
    if [[ ! -n "$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" -print -quit 2>/dev/null)" ]]; then
        print_info "No commands found. Use 'aliasmate save' to add some."
        return 0
    fi
    
    # Collect stats data
    local temp_file
    temp_file=$(mktemp)
    
    # Get stats data from all command files
    jq -s 'sort_by(.runs) | reverse' "$COMMAND_STORE"/*.json > "$temp_file"
    
    # Check if we need to export the stats
    if [[ -n "$export_file" ]]; then
        jq '.' "$temp_file" > "$export_file"
        print_success "Statistics exported to $export_file"
        rm -f "$temp_file"
        return 0
    fi
    
    # Display stats with better performance for large command sets
    echo -e "${CYAN}Command Usage Statistics${NC}"
    echo -e "${CYAN}=======================${NC}"
    
    # Get total number of commands and runs more efficiently
    local cmd_count=$(find "$COMMAND_STORE" -maxdepth 1 -name "*.json" | wc -l)
    
    # Process in batches for better performance with large command sets
    local batch_size=50
    local batch_files=()
    local batch_count=0
    local run_count=0
    
    # Process files in batches to avoid loading everything into memory
    find "$COMMAND_STORE" -maxdepth 1 -name "*.json" | sort | while read -r file; do
        batch_files+=("$file")
        ((batch_count++))
        
        if [[ $batch_count -eq $batch_size ]]; then
            # Process this batch
            local batch_runs=$(jq -s 'map(.runs) | add' "${batch_files[@]}")
            run_count=$((run_count + batch_runs))
            
            # Reset for next batch
            batch_files=()
            batch_count=0
        fi
    done
    
    # Process any remaining files
    if [[ ${#batch_files[@]} -gt 0 ]]; then
        local batch_runs=$(jq -s 'map(.runs) | add' "${batch_files[@]}")
        run_count=$((run_count + batch_runs))
    fi
    
    echo -e "Total commands: ${YELLOW}$cmd_count${NC}"
    echo -e "Total executions: ${YELLOW}$run_count${NC}"
    echo
    
    # Most used commands
    echo -e "${GREEN}Most Used Commands:${NC}"
    echo -e "-----------------"
    
    jq -r '.[] | select(.runs > 0) | [.alias, .category, .runs, .last_run, .last_exit_code // "n/a"] | @tsv' "$temp_file" |
    head -n 10 |
    while IFS=$'\t' read -r alias category runs last_run exit_code; do
        # Format timestamp
        if [[ "$last_run" != "null" && -n "$last_run" ]]; then
            last_run_fmt=$(date -d "@$last_run" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || 
                          date -r "$last_run" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        else
            last_run_fmt="Never"
        fi
        
        # Format success/failure using colors
        if [[ "$exit_code" == "0" ]]; then
            status="${GREEN}Success${NC}"
        elif [[ "$exit_code" == "n/a" ]]; then
            status="N/A"
        else
            status="${RED}Failed ($exit_code)${NC}"
        fi
        
        echo -e "${BOLD}$alias${NC} (${BLUE}$category${NC}): ${YELLOW}$runs run(s)${NC}"
        echo -e "  Last run: $last_run_fmt - $status"
    done
    
    # Show commands that have never been run
    echo
    echo -e "${YELLOW}Never Used Commands:${NC}"
    echo -e "------------------"
    
    unused_count=$(jq -r '.[] | select(.runs == 0) | .alias' "$temp_file" | wc -l)
    if [[ $unused_count -gt 0 ]]; then
        jq -r '.[] | select(.runs == 0) | [.alias, .category] | @tsv' "$temp_file" |
        while IFS=$'\t' read -r alias category; do
            echo -e "${BOLD}$alias${NC} (${BLUE}$category${NC})"
        done
    else
        echo -e "No unused commands found"
    fi
    
    # Show detailed stats if available
    if [[ -d "$COMMAND_STORE/stats" ]]; then
        echo
        echo -e "${CYAN}Command Success Rates:${NC}"
        echo -e "---------------------"
        
        find "$COMMAND_STORE/stats" -name "*.csv" | while read -r stats_file; do
            alias_name=$(basename "$stats_file" .csv)
            # Skip if header only
            if [[ $(wc -l < "$stats_file") -le 1 ]]; then
                continue
            fi
            
            # Calculate success rate
            total=$(tail -n +2 "$stats_file" | wc -l)
            success=$(tail -n +2 "$stats_file" | grep ",0$" | wc -l)
            rate=$((success * 100 / total))
            
            # Average duration
            avg_duration=$(tail -n +2 "$stats_file" | awk -F, '{sum+=$2; count++} END {print sum/count}')
            
            echo -e "${BOLD}$alias_name${NC}: ${GREEN}$rate%${NC} success rate, avg duration: ${YELLOW}$(printf "%.2f" "$avg_duration")s${NC}"
        done
    fi
    
    # Clean up
    rm -f "$temp_file"
    
    return 0
}

# Record command execution result (called from run_command)
record_execution() {
    local alias_name="$1"
    local duration="$2"
    local exit_code="$3"
    
    # Skip if stats are disabled
    if [[ "$ENABLE_STATS" != "true" ]]; then
        return 0
    fi
    
    # Update command file
    local command_file="$COMMAND_STORE/$alias_name.json"
    if [[ -f "$command_file" ]]; then
        local timestamp=$(date +%s)
        local runs=$(jq -r '.runs' "$command_file")
        ((runs++))
        
        jq --arg last_run "$timestamp" \
           --arg exit_code "$exit_code" \
           --arg runs "$runs" \
           --arg duration "$duration" \
           '.runs = ($runs | tonumber) | 
            .last_run = ($last_run | tonumber) | 
            .last_exit_code = ($exit_code | tonumber) |
            .last_duration = ($duration | tonumber)' \
           "$command_file" > "${command_file}.tmp" && mv "${command_file}.tmp" "$command_file"
    fi
    
    # Update stats file
    local stats_dir="$COMMAND_STORE/stats"
    mkdir -p "$stats_dir"
    local stats_file="$stats_dir/${alias_name}.csv"
    
    # Create stats file with header if it doesn't exist
    if [[ ! -f "$stats_file" ]]; then
        echo "timestamp,duration,exit_code" > "$stats_file"
    fi
    
    # Append the stats
    local timestamp=$(date +%s)
    echo "$timestamp,$duration,$exit_code" >> "$stats_file"
    
    return 0
}
