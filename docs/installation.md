# Installation Guide

This guide provides detailed instructions for installing AliasMate v2 on different platforms.

## System Requirements

- **Operating System**: Linux, macOS, or Windows (with WSL)
- **Shell**: Bash 4.0+ or Zsh
- **Dependencies**:
  - `jq` (for JSON processing)
  - `curl` or `wget` (for installation and updates)
  - `dialog` or `whiptail` (for TUI functionality)

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

#### Debian/Ubuntu

```bash
# Download the latest .deb package
curl -LO https://github.com/akhshyganesh/aliasmate-v2/releases/latest/download/aliasmate_*.deb

# Install the package
sudo apt install ./aliasmate_*.deb
```

#### Fedora/CentOS/RHEL

```bash
# Download the latest .rpm package
curl -LO https://github.com/akhshyganesh/aliasmate-v2/releases/latest/download/aliasmate-*.rpm

# Install the package
sudo dnf install ./aliasmate-*.rpm
```

#### macOS (Homebrew)

```bash
# Add the tap
brew tap akhshyganesh/aliasmate

# Install AliasMate
brew install aliasmate
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

## Updating AliasMate

To update to the latest version:

```bash
aliasmate --upgrade
```

## Uninstalling

To remove AliasMate from your system:

```bash
# Remove the executable
sudo rm /usr/local/bin/aliasmate

# Remove configuration
rm -rf ~/.config/aliasmate

# Remove command store (WARNING: This will delete all your saved commands)
rm -rf ~/.local/share/aliasmate
```
