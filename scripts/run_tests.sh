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

# Print banner
echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│       AliasMate v2 Test Runner         │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# Check if we have the necessary tools
check_dependencies() {
    echo -e "\n${CYAN}Checking test dependencies...${NC}"
    
    if ! command -v shellcheck &> /dev/null; then
        echo -e "${RED}Error: shellcheck is required for testing${NC}"
        echo "Please install shellcheck using your package manager."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error: jq is required for testing${NC}"
        echo "Please install jq using your package manager."
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies are met!${NC}"
}

# Run shellcheck on all shell scripts
run_shellcheck() {
    echo -e "\n${CYAN}Running shellcheck...${NC}"
    
    # Find all shell scripts in src directory
    local scripts=$(find "$SRC_DIR" -type f -name "*.sh")
    local script_count=$(echo "$scripts" | wc -l)
    
    echo -e "Found ${YELLOW}$script_count${NC} scripts to check"
    
    # Run shellcheck on each script
    local failures=0
    for script in $scripts; do
        echo -e "Checking: ${CYAN}$(basename "$script")${NC}"
        if ! shellcheck -x "$script"; then
            ((failures++))
        fi
    done
    
    if [[ $failures -eq 0 ]]; then
        echo -e "${GREEN}All scripts passed shellcheck!${NC}"
    else
        echo -e "${RED}$failures scripts failed shellcheck!${NC}"
        exit 1
    fi
}

# Run unit tests
run_unit_tests() {
    echo -e "\n${CYAN}Running unit tests...${NC}"
    
    # Check if we have any unit tests
    if [[ ! -d "$TEST_DIR/unit" ]]; then
        echo -e "${YELLOW}No unit tests found. Skipping...${NC}"
        return 0
    fi
    
    # Find all test files
    local test_files=$(find "$TEST_DIR/unit" -type f -name "test_*.sh")
    local test_count=$(echo "$test_files" | wc -l)
    
    if [[ $test_count -eq 0 ]]; then
        echo -e "${YELLOW}No unit test files found. Skipping...${NC}"
        return 0
    }
    
    echo -e "Found ${YELLOW}$test_count${NC} test files"
    
    # Run each test file
    local failures=0
    local total_tests=0
    local passed_tests=0
    
    for test_file in $test_files; do
        echo -e "Running tests in: ${CYAN}$(basename "$test_file")${NC}"
        
        # Make the test file executable if it isn't already
        chmod +x "$test_file"
        
        # Run the test file and capture output
        if ! output=$("$test_file" 2>&1); then
            echo -e "${RED}Test file failed!${NC}"
            echo "$output"
            ((failures++))
        else
            # Parse test results
            local file_tests=$(echo "$output" | grep -c "^TEST:")
            local file_passed=$(echo "$output" | grep -c "^PASS:")
            
            echo -e "  ${GREEN}$file_passed${NC}/${YELLOW}$file_tests${NC} tests passed"
            
            total_tests=$((total_tests + file_tests))
            passed_tests=$((passed_tests + file_passed))
        fi
    done
    
    # Print summary
    echo -e "\n${CYAN}Unit Test Summary:${NC}"
    echo -e "Total Tests: ${YELLOW}$total_tests${NC}"
    echo -e "Passed Tests: ${GREEN}$passed_tests${NC}"
    echo -e "Failed Tests: ${RED}$((total_tests - passed_tests))${NC}"
    
    if [[ $failures -gt 0 || $passed_tests -lt $total_tests ]]; then
        echo -e "${RED}Unit tests failed!${NC}"
        exit 1
    else
        echo -e "${GREEN}All unit tests passed!${NC}"
    fi
}

# Run integration tests
run_integration_tests() {
    echo -e "\n${CYAN}Running integration tests...${NC}"
    
    # Check if we have any integration tests
    if [[ ! -d "$TEST_DIR/integration" ]]; then
        echo -e "${YELLOW}No integration tests found. Skipping...${NC}"
        return 0
    fi
    
    # Find all test files
    local test_files=$(find "$TEST_DIR/integration" -type f -name "test_*.sh")
    local test_count=$(echo "$test_files" | wc -l)
    
    if [[ $test_count -eq 0 ]]; then
        echo -e "${YELLOW}No integration test files found. Skipping...${NC}"
        return 0
    }
    
    echo -e "Found ${YELLOW}$test_count${NC} test files"
    
    # Set up test environment
    local test_dir="$TEMP_DIR/aliasmate_test"
    mkdir -p "$test_dir"
    export ALIASMATE_TEST_DIR="$test_dir"
    
    # Run each test file
    local failures=0
    
    for test_file in $test_files; do
        echo -e "Running test: ${CYAN}$(basename "$test_file")${NC}"
        
        # Make the test file executable if it isn't already
        chmod +x "$test_file"
        
        # Run the test file and capture output
        if ! output=$("$test_file" 2>&1); then
            echo -e "${RED}Test failed!${NC}"
            echo "$output"
            ((failures++))
        else
            echo -e "${GREEN}Test passed!${NC}"
        fi
    done
    
    # Clean up
    rm -rf "$test_dir"
    
    if [[ $failures -gt 0 ]]; then
        echo -e "${RED}Integration tests failed!${NC}"
        exit 1
    else
        echo -e "${GREEN}All integration tests passed!${NC}"
    fi
}

# Function to clean up temporary files
cleanup() {
    echo -e "\n${CYAN}Cleaning up...${NC}"
    rm -rf "$TEMP_DIR"
}

# Main test flow
main() {
    check_dependencies
    run_shellcheck
    run_unit_tests
    run_integration_tests
    cleanup
    
    echo -e "\n${GREEN}┌────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│       All tests passed successfully!    │${NC}"
    echo -e "${GREEN}└────────────────────────────────────────┘${NC}"
}

# Execute the main function
main

# Trap for cleanup
trap cleanup EXIT
