#!/usr/bin/env bash
# Common test utilities for AliasMate v2 tests

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directory paths
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$TEST_DIR")"
SRC_DIR="$ROOT_DIR/src"

# Mock functions to replace external dependencies
# These will be used in unit tests to avoid actual system changes

# Mock jq
mock_jq() {
    echo "Mocked jq output"
}

# Mock config file reading
mock_config() {
    # Set standard config values for testing
    COMMAND_STORE="$TEST_DIR/fixtures/command_store"
    LOG_FILE="$TEST_DIR/fixtures/logs/aliasmate.log"
    LOG_LEVEL="debug"
    VERSION_CHECK="false"
    EDITOR="echo"  # Just echo the file name instead of opening an editor
    DEFAULT_UI="cli"
    THEME="default"
    ENABLE_STATS="true"
    SYNC_ENABLED="false"
    SYNC_PROVIDER=""
    SYNC_INTERVAL="3600"
}

# Helper to create a test command store
create_test_command_store() {
    mkdir -p "$TEST_DIR/fixtures/command_store/categories"
    mkdir -p "$TEST_DIR/fixtures/command_store/stats"
    mkdir -p "$TEST_DIR/fixtures/logs"
    
    # Create a test command
    cat > "$TEST_DIR/fixtures/command_store/test_command.json" << EOF
{
  "alias": "test_command",
  "command": "echo 'This is a test command'",
  "path": "/tmp",
  "category": "test",
  "created": 1636729998,
  "modified": 1636729998,
  "runs": 0,
  "last_run": null
}
EOF

    # Create a test category
    touch "$TEST_DIR/fixtures/command_store/categories/test"
}

# Helper to clean up test environment
cleanup_test_environment() {
    if [[ -d "$TEST_DIR/fixtures" ]]; then
        rm -rf "$TEST_DIR/fixtures"
    fi
}

# Set up test environment before tests run
setup_test_environment() {
    cleanup_test_environment
    create_test_command_store
}

# Function to assert equality with nice formatting
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}PASS:${NC} $message"
        return 0
    else
        echo -e "${RED}FAIL:${NC} $message"
        echo -e "  Expected: ${YELLOW}$expected${NC}"
        echo -e "  Actual  : ${RED}$actual${NC}"
        return 1
    fi
}

# Function to assert not equal with nice formatting
assert_not_equal() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [[ "$unexpected" != "$actual" ]]; then
        echo -e "${GREEN}PASS:${NC} $message"
        return 0
    else
        echo -e "${RED}FAIL:${NC} $message"
        echo -e "  Unexpected: ${RED}$unexpected${NC}"
        echo -e "  Actual    : ${RED}$actual${NC}"
        return 1
    fi
}

# Function to assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File $file should exist}"
    
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}PASS:${NC} $message"
        return 0
    else
        echo -e "${RED}FAIL:${NC} $message"
        echo -e "  File does not exist: ${RED}$file${NC}"
        return 1
    fi
}

# Setup test environment on sourcing
setup_test_environment

# Make sure to clean up on exit
trap cleanup_test_environment EXIT
