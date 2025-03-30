# AliasMate v2

![Build Status](https://github.com/akhshyganesh/aliasmate-v2/workflows/Build%20and%20Test/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Version](https://img.shields.io/github/v/release/akhshyganesh/aliasmate-v2)

AliasMate is a powerful command management tool that helps you store, organize, and execute your most frequently used shell commands with ease.

## Features

- **Save commands with aliases**: Store any command with a memorable alias
- **Path tracking**: Commands remember where they should be executed
- **Categories & tags**: Organize commands by projects or contexts
- **Interactive TUI**: Easy-to-use terminal interface
- **Powerful search**: Find commands quickly as your library grows
- **Command history**: Track command usage and success rates
- **Multi-line commands**: Support for complex scripts
- **Import/Export**: Share your command libraries
- **Auto-completion**: Tab completion for bash and zsh
- **Cross-platform**: Works on Linux, macOS, and WSL (Windows Subsystem for Linux)

## Installation

### Quick Installation

```bash
# Using curl
curl -sSL https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash

# Using wget
wget -qO- https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash
```

### Package Managers

```bash
# Debian/Ubuntu
sudo apt install ./aliasmate_*.deb

# Fedora/CentOS
sudo dnf install ./aliasmate-*.rpm

# macOS
brew tap akhshyganesh/aliasmate
brew install aliasmate
```

### Manual Installation

```bash
git clone https://github.com/akhshyganesh/aliasmate-v2.git
cd aliasmate-v2
./scripts/build.sh
sudo ./scripts/install.sh
```

## Quick Start

```bash
# Save a command with an alias
aliasmate save deploy "kubectl apply -f deployment.yaml"

# Run the command
aliasmate run deploy

# Add a multi-line command
aliasmate save backup --multi

# List all commands
aliasmate ls

# Open the interactive TUI
aliasmate --tui
```

## Documentation

For complete documentation, visit our [User Guide](https://akhshyganesh.github.io/aliasmate-v2/docs/).

### Core Commands

- `aliasmate save <alias> <command>` - Save a command with an alias
- `aliasmate run <alias>` - Run a saved command
- `aliasmate edit <alias>` - Edit a command
- `aliasmate ls` - List all commands
- `aliasmate search <term>` - Search for commands
- `aliasmate rm <alias>` - Remove a command
- `aliasmate --tui` - Open the text user interface

## Configuration

AliasMate can be configured using:

```bash
aliasmate config set <key> <value>
```

Common configuration options:
- `editor` - Default editor for multi-line commands
- `store_path` - Custom location for storing aliases
- `theme` - UI theme (light/dark)
- `sync` - Enable/disable cloud sync

## Contributing

Contributions are welcome! Please see our [Contributing Guide](CONTRIBUTING.md) for more details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
