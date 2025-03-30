#!/usr/bin/env bash
# AliasMate v2 - Test Runner

set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Define variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$ROOT_DIR/tests"
SRC_DIR="$ROOT_DIR/src"
TEMP_DIR=$(mktemp -d)
FAILURES=0

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

# Print banner
echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│       AliasMate v2 Test Runner         │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# Check if we have the necessary tools
check_dependencies() {
    echo -e "\n${CYAN}Checking test dependencies...${NC}"
    
    local missing=0
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Warning: jq is not installed. Some tests may fail.${NC}"
        missing=1
    fi
    
    if ! command -v shellcheck &> /dev/null; then
        echo -e "${YELLOW}Warning: shellcheck is not installed. Code quality tests will be skipped.${NC}"
        missing=1
    fi
    
    if [ "$missing" -eq 1 ]; then
        echo -e "${YELLOW}Some dependencies are missing. Consider installing them for full test coverage.${NC}"
    else
        echo -e "${GREEN}All test dependencies are installed!${NC}"
    fi
}

# Run unit tests
run_unit_tests() {
    echo -e "\n${CYAN}Running unit tests...${NC}"
    
    for test_file in "$TEST_DIR"/unit/*.sh; do
        if [ -f "$test_file" ]; then
            echo -e "${YELLOW}Running test: $(basename "$test_file")${NC}"
            if bash "$test_file"; then
                echo -e "${GREEN}Test passed: $(basename "$test_file")${NC}"
            else
                echo -e "${RED}Test failed: $(basename "$test_file")${NC}"
                FAILURES=$((FAILURES + 1))
            fi
        fi
    done
}

# Run integration tests
run_integration_tests() {
    echo -e "\n${CYAN}Running integration tests...${NC}"
    
    for test_file in "$TEST_DIR"/integration/*.sh; do
        if [ -f "$test_file" ]; then
            echo -e "${YELLOW}Running test: $(basename "$test_file")${NC}"
            if bash "$test_file"; then
                echo -e "${GREEN}Test passed: $(basename "$test_file")${NC}"
            else
                echo -e "${RED}Test failed: $(basename "$test_file")${NC}"
                FAILURES=$((FAILURES + 1))
            fi
        fi
    done
}

# Run code quality tests with shellcheck
run_code_quality_tests() {
    echo -e "\n${CYAN}Running code quality tests...${NC}"
    
    if ! command -v shellcheck &> /dev/null; then
        echo -e "${YELLOW}Skipping shellcheck tests - shellcheck not installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Running shellcheck...${NC}"
    local shellcheck_errors=0
    
    # Allow shellcheck to fail without stopping the script
    set +e
    find "$SRC_DIR" -type f -name "*.sh" -exec shellcheck -x {} \;
    shellcheck_errors=$?
    set -e
    
    if [ "$shellcheck_errors" -eq 0 ]; then
        echo -e "${GREEN}Shellcheck passed!${NC}"
    else
        echo -e "${YELLOW}Shellcheck found issues. These are warnings but not fatal errors.${NC}"
    fi
}

# Main function
main() {
    check_dependencies
    run_code_quality_tests
    run_unit_tests
    run_integration_tests
    
    echo -e "\n${CYAN}Test results:${NC}"
    if [ "$FAILURES" -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}$FAILURES test(s) failed!${NC}"
        exit 1
    fi
}

# Run main function
main
