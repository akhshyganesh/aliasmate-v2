# Installation Guide

This guide will help you install AliasMate v2 on your system.

## System Requirements

- Linux or macOS
- Bash 4.0 or higher
- Required dependencies: `curl`, `bash`
- Recommended dependencies: `jq` (for better YAML/JSON handling)

## Installation Methods

### Quick Installation Script

The fastest way to install AliasMate is using our installation script:

```bash
# Using curl
curl -sSL https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash

# Using wget
wget -qO- https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash
```

The script will:
1. Check for dependencies and install missing ones (requires sudo)
2. Download the latest release
3. Install AliasMate to `/usr/local/bin`
4. Set up configuration files
5. Add shell completion to your `.bashrc` or `.zshrc` if you're using a supported shell

### Package Managers

For package manager installation:

#### Homebrew (macOS)

```bash
brew tap akhshyganesh/aliasmate
brew install aliasmate
```

#### Debian/Ubuntu (APT)

```bash
# Add the repository
echo "deb [trusted=yes] https://apt.akhshyganesh.com/ /" | sudo tee /etc/apt/sources.list.d/aliasmate.list
sudo apt update
sudo apt install aliasmate
```

#### Fedora/CentOS (RPM)

```bash
sudo dnf copr enable akhshyganesh/aliasmate
sudo dnf install aliasmate
```

### Manual Installation

For a manual installation:

1. Download the latest release tarball:
   ```bash
   curl -LO https://github.com/akhshyganesh/aliasmate-v2/releases/latest/download/aliasmate-*.tar.gz
   ```

2. Extract the tarball:
   ```bash
   tar -xzf aliasmate-*.tar.gz
   ```

3. Move the executable to your PATH:
   ```bash
   sudo cp aliasmate /usr/local/bin/
   sudo chmod +x /usr/local/bin/aliasmate
   ```

4. Set up configuration:
   ```bash
   mkdir -p ~/.config/aliasmate
   cp config.yaml ~/.config/aliasmate/
   ```

## Post-Installation Setup

### Shell Completion

To enable tab completion:

```bash
# For Bash
echo 'source <(aliasmate completion bash)' >> ~/.bashrc
source ~/.bashrc

# For Zsh
echo 'source <(aliasmate completion zsh)' >> ~/.zshrc
source ~/.zshrc
```

### First Run

After installation, verify that AliasMate is working correctly:

```bash
aliasmate --version
```

You should see the current version number displayed.

To create your first command:

```bash
aliasmate save hello "echo 'Hello, World!'"
aliasmate run hello
```

## Docker Usage (For Testing Only)

AliasMate includes Docker configuration for development and testing purposes. Note that Docker is not the recommended way to use AliasMate in production.

### Running Tests in Docker

```bash
# Build and run the test container
docker-compose up -d aliasmate-test

# Enter the container
docker-compose exec aliasmate-test bash

# Run tests
./scripts/run_tests.sh
```

### Testing Installation in Docker

```bash
# Run a fresh container
docker run -it --rm ubuntu:22.04 bash

# Install prerequisites
apt update && apt install curl -y

# Run the installer
curl -sSL https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash
```

## Troubleshooting Installation

If you encounter issues during installation:

1. **Missing dependencies**: Ensure `jq` is installed:
   ```bash
   # Debian/Ubuntu
   sudo apt install jq
   
   # Fedora/CentOS
   sudo dnf install jq
   
   # macOS
   brew install jq
   ```

2. **Permission errors**: Check that you have write permissions to the installation directory:
   ```bash
   sudo chown -R $(whoami) /usr/local/bin
   ```

3. **Command not found**: Make sure `/usr/local/bin` is in your PATH:
   ```bash
   echo $PATH
   ```
   
   If it's not, add it:
   ```bash
   echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

4. **Manual install**: If all else fails, clone the repository and run:
   ```bash
   git clone https://github.com/akhshyganesh/aliasmate-v2.git
   cd aliasmate-v2
   ./scripts/build.sh
   sudo ./scripts/install.sh
   ```
