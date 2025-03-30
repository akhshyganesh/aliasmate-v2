#!/usr/bin/env bash
# AliasMate v2 - Interactive tutorials and onboarding

# Function to run the onboarding tutorial
run_onboarding() {
    local step=1
    local total_steps=5
    
    clear
    print_header
    
    echo -e "\n${CYAN}Welcome to the AliasMate Onboarding Tutorial!${NC}"
    echo -e "This tutorial will guide you through the basics of using AliasMate."
    echo -e "Press ${YELLOW}[Enter]${NC} to continue through each step or ${YELLOW}[Ctrl+C]${NC} to exit at any time."
    read -r
    
    # Step 1: Introduction
    clear
    print_header
    echo -e "\n${BOLD}Step $step of $total_steps: Introduction${NC}"
    echo
    echo -e "AliasMate helps you ${GREEN}store${NC}, ${GREEN}organize${NC}, and ${GREEN}execute${NC} shell commands."
    echo -e "Instead of remembering complex commands or creating shell aliases,"
    echo -e "you can save them with AliasMate and run them with simple names."
    echo
    echo -e "Press ${YELLOW}[Enter]${NC} to continue..."
    read -r
    ((step++))
    
    # Step 2: Saving a command
    clear
    print_header
    echo -e "\n${BOLD}Step $step of $total_steps: Saving Your First Command${NC}"
    echo
    echo -e "Let's save a simple command:"
    echo
    echo -e "${YELLOW}aliasmate save hello \"echo Hello, World!\"${NC}"
    echo
    echo -e "This saves a command named '${GREEN}hello${NC}' that will print 'Hello, World!'"
    echo -e "Would you like to try this now? [y/n]"
    read -r response
    if [[ "$response" =~ ^[Yy] ]]; then
        aliasmate save hello "echo Hello, World!"
        echo -e "\n${GREEN}Command saved successfully!${NC}"
    fi
    echo
    echo -e "Press ${YELLOW}[Enter]${NC} to continue..."
    read -r
    ((step++))
    
    # Step 3: Running a command
    clear
    print_header
    echo -e "\n${BOLD}Step $step of $total_steps: Running Commands${NC}"
    echo
    echo -e "To run a saved command, use:"
    echo
    echo -e "${YELLOW}aliasmate run hello${NC}"
    echo
    if [[ "$response" =~ ^[Yy] ]]; then
        echo -e "Would you like to run your 'hello' command now? [y/n]"
        read -r run_response
        if [[ "$run_response" =~ ^[Yy] ]]; then
            echo -e "\n${CYAN}Running command:${NC}"
            aliasmate run hello
            echo
        fi
    fi
    echo -e "Press ${YELLOW}[Enter]${NC} to continue..."
    read -r
    ((step++))
    
    # Step 4: Listing and searching
    clear
    print_header
    echo -e "\n${BOLD}Step $step of $total_steps: Finding Your Commands${NC}"
    echo
    echo -e "To list all your saved commands:"
    echo -e "${YELLOW}aliasmate ls${NC}"
    echo
    echo -e "To search for specific commands:"
    echo -e "${YELLOW}aliasmate search <keyword>${NC}"
    echo
    echo -e "Would you like to list your commands now? [y/n]"
    read -r list_response
    if [[ "$list_response" =~ ^[Yy] ]]; then
        echo
        aliasmate ls
        echo
    fi
    echo -e "Press ${YELLOW}[Enter]${NC} to continue..."
    read -r
    ((step++))
    
    # Step 5: Next steps and conclusion
    clear
    print_header
    echo -e "\n${BOLD}Step $step of $total_steps: Next Steps${NC}"
    echo
    echo -e "Congratulations! You now know the basics of using AliasMate."
    echo
    echo -e "Here are some next steps to explore:"
    echo -e "• Use ${YELLOW}aliasmate --tui${NC} for an interactive interface"
    echo -e "• Create categories with ${YELLOW}aliasmate category create <name>${NC}"
    echo -e "• Save multi-line commands with ${YELLOW}aliasmate save <name> --multi${NC}"
    echo -e "• View usage statistics with ${YELLOW}aliasmate stats${NC}"
    echo
    echo -e "For more information, run ${YELLOW}aliasmate --help${NC} or visit:"
    echo -e "${GREEN}https://github.com/akhshyganesh/aliasmate-v2${NC}"
    echo
    echo -e "${GREEN}Tutorial complete! Happy command managing!${NC}"
    echo
    echo -e "Press ${YELLOW}[Enter]${NC} to exit..."
    read -r
}

# Display a specific tutorial by name
show_tutorial() {
    local tutorial="$1"
    
    case "$tutorial" in
        "categories")
            run_categories_tutorial
            ;;
        "sync")
            run_sync_tutorial
            ;;
        "advanced")
            run_advanced_tutorial
            ;;
        *)
            echo -e "${RED}Unknown tutorial: $tutorial${NC}"
            echo -e "Available tutorials: categories, sync, advanced"
            return 1
            ;;
    esac
}

# Category management tutorial
run_categories_tutorial() {
    clear
    print_header
    
    echo -e "\n${CYAN}Category Management Tutorial${NC}"
    echo -e "This tutorial will guide you through organizing commands with categories."
    echo -e "Press ${YELLOW}[Enter]${NC} to continue..."
    read -r
    
    # Tutorial content
    clear
    print_header
    echo -e "\n${BOLD}Creating and Managing Categories${NC}"
    echo
    echo -e "Categories help you organize commands by project, context, or purpose."
    echo
    echo -e "1. ${YELLOW}Creating a category:${NC}"
    echo -e "   aliasmate category create <name>"
    echo
    echo -e "2. ${YELLOW}Listing categories:${NC}"
    echo -e "   aliasmate category ls"
    echo
    echo -e "3. ${YELLOW}Saving a command to a category:${NC}"
    echo -e "   aliasmate save <name> \"<command>\" --category <category>"
    echo
    echo -e "4. ${YELLOW}Moving commands between categories:${NC}"
    echo -e "   aliasmate move <command> <category>"
    echo
    echo -e "5. ${YELLOW}Listing commands in a category:${NC}"
    echo -e "   aliasmate ls --category <category>"
    echo
    echo -e "Press ${YELLOW}[Enter]${NC} to exit..."
    read -r
}

# Sync management tutorial
run_sync_tutorial() {
    clear
    print_header
    
    echo -e "\n${CYAN}Cloud Synchronization Tutorial${NC}"
    echo -e "This tutorial will guide you through setting up command synchronization."
    echo -e "Press ${YELLOW}[Enter]${NC} to continue..."
    read -r
    
    # Tutorial content
    clear
    print_header
    echo -e "\n${BOLD}Setting Up Cloud Synchronization${NC}"
    echo
    echo -e "Cloud sync lets you share commands across multiple devices."
    echo
    echo -e "1. ${YELLOW}Configure sync provider:${NC}"
    echo -e "   aliasmate sync config --provider github --token <token> --repo <repo>"
    echo
    echo -e "2. ${YELLOW}Enable synchronization:${NC}"
    echo -e "   aliasmate sync enable"
    echo
    echo -e "3. ${YELLOW}Manual synchronization:${NC}"
    echo -e "   aliasmate sync now"
    echo
    echo -e "4. ${YELLOW}Check sync status:${NC}"
    echo -e "   aliasmate sync status"
    echo
    echo -e "5. ${YELLOW}Disable synchronization:${NC}"
    echo -e "   aliasmate sync disable"
    echo
    echo -e "Press ${YELLOW}[Enter]${NC} to exit..."
    read -r
}

# Advanced features tutorial
run_advanced_tutorial() {
    clear
    print_header
    
    echo -e "\n${CYAN}Advanced Features Tutorial${NC}"
    echo -e "This tutorial covers more advanced AliasMate capabilities."
    echo -e "Press ${YELLOW}[Enter]${NC} to continue..."
    read -r
    
    # Tutorial content
    clear
    print_header
    echo -e "\n${BOLD}Advanced AliasMate Features${NC}"
    echo
    echo -e "1. ${YELLOW}Multi-line commands:${NC}"
    echo -e "   aliasmate save <name> --multi"
    echo
    echo -e "2. ${YELLOW}Command statistics:${NC}"
    echo -e "   aliasmate stats"
    echo
    echo -e "3. ${YELLOW}Export & Import:${NC}"
    echo -e "   aliasmate export all commands.json"
    echo -e "   aliasmate import commands.json"
    echo
    echo -e "4. ${YELLOW}Custom path execution:${NC}"
    echo -e "   aliasmate save <name> \"<command>\" --path /custom/path"
    echo
    echo -e "5. ${YELLOW}Command editing:${NC}"
    echo -e "   aliasmate edit <name>"
    echo
    echo -e "Press ${YELLOW}[Enter]${NC} to exit..."
    read -r
}
