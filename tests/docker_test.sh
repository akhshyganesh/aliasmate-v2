#!/usr/bin/env bash
# AliasMate v2 - Docker Test Script

set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}┌────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│       AliasMate v2 Docker Tests        │${NC}"
echo -e "${BLUE}└────────────────────────────────────────┘${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker to run these tests.${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running. Please start Docker to run these tests.${NC}"
    exit 1
fi

# Define test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${CYAN}Running test: $test_name${NC}"
    echo -e "${YELLOW}Command: $test_command${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}Test passed: $test_name${NC}"
        return 0
    else
        echo -e "${RED}Test failed: $test_name${NC}"
        return 1
    fi
}

# Build the Docker image
echo -e "\n${CYAN}Building Docker test image...${NC}"
docker build -t aliasmate-test .

# Run the installation test
run_test "Installation Test" "docker run --rm aliasmate-test bash -c 'cd /app && ./scripts/install.sh && aliasmate --version'"

# Run the basic functionality test
run_test "Basic Functionality Test" "docker run --rm aliasmate-test bash -c 'cd /app && ./scripts/install.sh && aliasmate save test \"echo test\" && aliasmate run test'"

# Run the configuration test
run_test "Configuration Test" "docker run --rm aliasmate-test bash -c 'cd /app && ./scripts/install.sh && aliasmate config set EDITOR vim && aliasmate config get EDITOR | grep vim'"

# Run the export/import test
run_test "Export/Import Test" "docker run --rm aliasmate-test bash -c 'cd /app && ./scripts/install.sh && aliasmate save test \"echo test\" && aliasmate export --output /tmp/test.json && aliasmate rm test --force && aliasmate import /tmp/test.json && aliasmate run test'"

# Run all unit tests
run_test "All Unit Tests" "docker run --rm aliasmate-test bash -c 'cd /app && ./scripts/run_tests.sh'"

echo -e "\n${GREEN}All Docker tests completed successfully!${NC}"
