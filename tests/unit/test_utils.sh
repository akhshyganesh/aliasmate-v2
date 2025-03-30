#!/usr/bin/env bash
# Unit tests for utils.sh functions

# Source the common test setup
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$TEST_DIR/common.sh"

# Source the utils.sh file
source "$SRC_DIR/core/utils.sh"

# Test command_exists function
test_command_exists() {
    echo "TEST: command_exists - should return 0 for existing commands"
    
    # Bash should exist on all systems
    if command_exists bash; then
        echo "PASS: command_exists correctly identified 'bash'"
    else
        echo "FAIL: command_exists failed to identify 'bash'"
        return 1
    fi
    
    echo "TEST: command_exists - should return 1 for non-existing commands"
    
    # This command should not exist
    if ! command_exists thiscmdshldnotexist123xyz; then
        echo "PASS: command_exists correctly rejected non-existent command"
    else
        echo "FAIL: command_exists incorrectly identified non-existent command"
        return 1
    fi
    
    return 0
}

# Test validate_alias function
test_validate_alias() {
    echo "TEST: validate_alias - should accept valid alias names"
    
    # Valid alias names
    local valid_names=("test" "test123" "test_123" "test-123" "a" "A" "TEST")
    
    for name in "${valid_names[@]}"; do
        if validate_alias "$name"; then
            echo "PASS: validate_alias correctly accepted '$name'"
        else
            echo "FAIL: validate_alias incorrectly rejected '$name'"
            return 1
        fi
    done
    
    echo "TEST: validate_alias - should reject invalid alias names"
    
    # Invalid alias names
    local invalid_names=("" "test@123" "test 123" "test.123" "test,123" "test/123")
    
    for name in "${invalid_names[@]}"; do
        if ! validate_alias "$name"; then
            echo "PASS: validate_alias correctly rejected '$name'"
        else
            echo "FAIL: validate_alias incorrectly accepted '$name'"
            return 1
        fi
    done
    
    # Test length validation
    local long_name=$(printf "a%.0s" {1..51})  # 51 characters
    
    echo "TEST: validate_alias - should reject names longer than 50 characters"
    if ! validate_alias "$long_name"; then
        echo "PASS: validate_alias correctly rejected long name"
    else
        echo "FAIL: validate_alias incorrectly accepted long name"
        return 1
    fi
    
    return 0
}

# Test generate_id function
test_generate_id() {
    echo "TEST: generate_id - should generate unique IDs"
    
    local id1=$(generate_id)
    local id2=$(generate_id)
    
    if [[ "$id1" != "$id2" ]]; then
        echo "PASS: generate_id generated unique IDs"
    else
        echo "FAIL: generate_id generated identical IDs"
        return 1
    fi
    
    echo "TEST: generate_id - should respect prefix parameter"
    
    local prefix="test"
    local id=$(generate_id "$prefix")
    
    if [[ "$id" == "${prefix}_"* ]]; then
        echo "PASS: generate_id respected prefix parameter"
    else
        echo "FAIL: generate_id ignored prefix parameter"
        return 1
    fi
    
    return 0
}

# Run all tests
run_tests() {
    local failed=0
    
    # Run each test function
    if ! test_command_exists; then
        failed=1
    fi
    
    if ! test_validate_alias; then
        failed=1
    fi
    
    if ! test_generate_id; then
        failed=1
    fi
    
    return $failed
}

# Execute tests
run_tests
exit $?
