# Contributing to AliasMate v2

Thank you for your interest in contributing to AliasMate! This document provides detailed guidelines to help you contribute effectively.

## Development Environment Setup

1. **Fork and clone the repository**

   ```bash
   git clone https://github.com/YOUR-USERNAME/aliasmate-v2.git
   cd aliasmate-v2
   ```

2. **Install development dependencies**

   ```bash
   # For Debian/Ubuntu
   sudo apt-get install jq shellcheck dialog

   # For macOS
   brew install jq shellcheck dialog
   ```

3. **Running tests**

   ```bash
   # Run all tests
   ./scripts/run_tests.sh
   
   # Run shellcheck only
   find ./src -type f -name "*.sh" -exec shellcheck -x {} \;
   ```

## Project Structure

