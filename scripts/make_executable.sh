#!/usr/bin/env bash
# Script to make all shell files executable in the repository

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the repository root directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${CYAN}Making all shell scripts executable in:${NC}"
echo -e "${YELLOW}$REPO_DIR${NC}\n"

# Find all .sh files in the repository
SCRIPT_FILES=$(find "$REPO_DIR" -type f -name "*.sh")
COUNT=0

for script in $SCRIPT_FILES; do
    # Make the file executable
    chmod +x "$script"
    echo -e "${GREEN}✓${NC} Made executable: ${YELLOW}$(basename "$script")${NC}"
    ((COUNT++))
done

echo -e "\n${GREEN}Complete!${NC} Made $COUNT shell scripts executable."
echo -e "You can now run any script directly with ./<script_name>.sh"
