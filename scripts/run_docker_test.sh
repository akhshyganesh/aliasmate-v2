#!/usr/bin/env bash
# Script to quickly build and run AliasMate in a Docker container for testing

set -e

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Building AliasMate Docker test environment...${NC}"

# Build the Docker image
docker build -t aliasmate-test .

echo -e "${GREEN}Docker image built successfully!${NC}"
echo -e "${YELLOW}Starting Docker container...${NC}"
echo -e "${CYAN}Inside the container, try running:${NC}"
echo -e "  aliasmate --help"
echo -e "  test-aliasmate"
echo -e "  am --version"
echo 

# Run the Docker container
docker run -it --rm aliasmate-test
