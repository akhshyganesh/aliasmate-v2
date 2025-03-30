#!/usr/bin/env bash
# Integration tests for command management

# Source the common test setup
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$TEST_DIR/common.sh"

# Function to setup the test environment
setup() {
    # Create a temporary directory for command store
    export COMMAND_STORE="$ALIASMATE_TEST_DIR/command_store"
    mkdir -p "$COMMAND_STORE/categories"
    mkdir -p "$COMMAND_STORE/stats"
    
    # Create config directory
    export CONFIG_DIR="$ALIASMATE_TEST_DIR/config"
    mkdir -p "$CONFIG_DIR"
    
    # Create a config file
    cat > "$CONFIG_DIR/config.yaml" << EOF
COMMAND_STORE: $COMMAND_STORE
LOG_FILE: $ALIASMATE_TEST_DIR/aliasmate.log
LOG_LEVEL: debug
VERSION_CHECK: false
EDITOR: echo
EOF

    # Source the required files
    source "$SRC_DIR/core/config.sh"
    source "$SRC_DIR/core/logging.sh"
    source "$SRC_DIR/core/utils.sh"
    source "$SRC_DIR/commands.sh"
    source "$SRC_DIR/categories.sh"
    
    # Initialize the environment
    load_config
    init_logging
}

# Function to test saving a command
test_save_command() {
    echo "Testing save_command function..."
    
    # Test saving a simple command
    save_command "test_cmd" "echo 'Hello, World!'" --category "test"
    
    if [[ ! -f "$COMMAND_STORE/test_cmd.json" ]]; then
        echo "FAIL: Command file was not created"
        return 1
    fi
    
    # Verify the category was created
    if [[ ! -f "$COMMAND_STORE/categories/test" ]]; then
        echo "FAIL: Category file was not created"
        return 1
    fi
    
    # Verify the command content
    local command=$(jq -r '.command' "$COMMAND_STORE/test_cmd.json")
    local category=$(jq -r '.category' "$COMMAND_STORE/test_cmd.json")
    
    if [[ "$command" != "echo 'Hello, World!'" ]]; then
        echo "FAIL: Command content is incorrect"
        echo "Expected: echo 'Hello, World!'"
        echo "Got: $command"
        return 1
    fi
    
    if [[ "$category" != "test" ]]; then
        echo "FAIL: Category is incorrect"
        echo "Expected: test"
        echo "Got: $category"
        return 1
    fi
    
    echo "PASS: save_command test passed"
    return 0
}

# Function to test listing commands
test_list_commands() {
    echo "Testing list_commands function..."
    
    # First, save some test commands
    save_command "test_cmd1" "echo 'Command 1'" --category "test"
    save_command "test_cmd2" "echo 'Command 2'" --category "test"
    save_command "another_cmd" "echo 'Another command'" --category "other"
    
    # Test listing all commands
    local output=$(list_commands --format json)
    
    # Verify we have 3 commands
    local count=$(echo "$output" | jq '. | length')
    if [[ "$count" != "3" ]]; then
        echo "FAIL: Expected 3 commands, got $count"
        return 1
    fi
    
    # Test listing commands by category
    local category_output=$(list_commands --category test --format json)
    local category_count=$(echo "$category_output" | jq '. | length')
    
    if [[ "$category_count" != "2" ]]; then
        echo "FAIL: Expected 2 commands in 'test' category, got $category_count"
        return 1
    fi
    
    echo "PASS: list_commands test passed"
    return 0
}

# Function to test removing a command
test_remove_command() {
    echo "Testing remove_command function..."
    
    # First, save a test command
    save_command "temp_cmd" "echo 'Temporary command'" --category "test"
    
    # Verify it exists
    if [[ ! -f "$COMMAND_STORE/temp_cmd.json" ]]; then
        echo "FAIL: Command file was not created for removal test"
        return 1
    fi
    
    # Remove the command
    remove_command "temp_cmd" "--force"
    
    # Verify it's gone
    if [[ -f "$COMMAND_STORE/temp_cmd.json" ]]; then
        echo "FAIL: Command file was not removed"
        return 1
    fi
    
    echo "PASS: remove_command test passed"
    return 0
}

# Main test runner
run_integration_tests() {
    setup
    
    local failed=0
    
    if ! test_save_command; then
        failed=1
    fi
    
    if ! test_list_commands; then
        failed=1
    fi
    
    if ! test_remove_command; then
        failed=1
    fi
    
    if [[ $failed -eq 0 ]]; then
        echo "All integration tests passed!"
    else
        echo "Some integration tests failed!"
    fi
    
    return $failed
}

# Run the tests
run_integration_tests
exit $?
