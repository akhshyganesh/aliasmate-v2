# Using AliasMate in Docker

This guide covers how to install and use AliasMate in Docker containers.

## Quick Installation

The simplest way to install AliasMate in a Docker container:

```bash
# Clone the repository
git clone https://github.com/akhshyganesh/aliasmate-v2.git
cd aliasmate-v2

# Make the Docker installation script executable
chmod +x scripts/docker_install.sh

# Run the Docker-specific installation script
./scripts/docker_install.sh
```

## Using the Pre-built Docker Image

We provide a pre-built Docker image with AliasMate already installed:

```bash
# Pull and run the image
docker pull akhshyganesh/aliasmate:latest
docker run -it akhshyganesh/aliasmate:latest
```

## Troubleshooting Docker Installation

If you encounter issues after installation:

### Missing Files Error

If you see errors like `/usr/local/bin/main.sh: line XX: /usr/local/bin/utils.sh: No such file or directory`, try running:

```bash
# Fix common Docker installation issues
chmod +x scripts/fix_docker_install.sh
./scripts/fix_docker_install.sh
```

### Manual Fix

You can also manually correct the installation:

1. Make sure all scripts are in `/usr/local/bin/aliasmate/`
2. Fix the main executable:

```bash
cat > /usr/local/bin/aliasmate << 'EOF'
#!/usr/bin/env bash
cd /usr/local/bin/aliasmate
source /usr/local/bin/aliasmate/main.sh "$@"
EOF
chmod +x /usr/local/bin/aliasmate
```

## Building Your Own Docker Image

To build your own Docker image with AliasMate:

```bash
# Build the image
docker build -t aliasmate .

# Run the container
docker run -it aliasmate
```
