# Testing AliasMate with Docker

This guide explains how to use Docker for testing AliasMate.

## Quick Setup

```bash
# Build a Docker image for testing
docker build -t aliasmate-test .

# Run the container
docker run -it aliasmate-test
```

Once inside the container, you can use AliasMate commands normally:

```bash
# Show help
aliasmate --help

# Open the TUI
aliasmate --tui

# Try basic commands
aliasmate save hello "echo Hello, World!"
aliasmate run hello
```

## Why Test in Docker?

Testing in Docker provides several benefits:
- Clean environment without modifying your host system
- Easy to reset by recreating the container
- Consistent environment for testing features

## Troubleshooting

If you encounter issues with the Docker setup:

1. Make sure the `docker_install.sh` script is executable:
   ```bash
   chmod +x scripts/docker_install.sh
   ```

2. If you see file not found errors, the paths may be incorrect. Try:
   ```bash
   cd /usr/local/bin/aliasmate
   ls -la
   ```
   
   All required shell scripts should be present in this directory.
