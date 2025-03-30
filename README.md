# AliasMate v2

![GitHub release](https://img.shields.io/github/v/release/akhshyganesh/aliasmate-v2)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey)

**AliasMate is a powerful command management tool that helps you store, organize, and execute your most frequently used shell commands with ease.**

<p align="center">
  <img src="docs/images/aliasmate-demo.gif" alt="AliasMate Demo" width="80%">
</p>

## Why AliasMate?

- **Never forget complex commands** - Store commands with meaningful aliases
- **Run in the right directory** - Commands remember their execution paths
- **Organize by project** - Group commands using categories
- **Track command usage** - See statistics about your most used commands
- **Share with colleagues** - Import/export command libraries

## Features

- 📋 **Command Storage** - Save and recall commands with descriptive names
- 📁 **Path Tracking** - Commands remember where they should be executed
- 🗂️ **Categories** - Organize commands by projects or contexts
- 👨‍💻 **Interactive TUI** - User-friendly terminal interface
- 🔍 **Advanced Search** - Find commands by name, content, or path
- 📊 **Command Statistics** - Track usage and success rates
- 📜 **Multi-line Commands** - Support for complex scripts
- 📤 **Import/Export** - Share your command libraries
- 🔄 **Cloud Sync** - Synchronize commands across machines via GitHub/GitLab
- 🚀 **Performance Optimization** - Efficiently handles large command libraries

## Installation

### Quick Installation

```bash
# Using curl
curl -sSL https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash

# Using wget
wget -qO- https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash
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
# Launch the interactive tutorial to learn basics
aliasmate tutorial

# Launch the TUI (recommended for beginners)
aliasmate --tui

# Save a command with an alias
aliasmate save deploy "kubectl apply -f deployment.yaml"

# Run the command
aliasmate run deploy

# Save a command with a category
aliasmate save build-app "npm run build" --category myproject

# Add a multi-line command
aliasmate save backup --multi

# List all commands
aliasmate ls

# Search commands
aliasmate search kubernetes
```

## Documentation

For detailed documentation and guides:

- Run `aliasmate tutorial` for an interactive onboarding experience
- Check out [Onboarding Guide](docs/ONBOARDING.md) for a step-by-step getting started guide
- Read the [User Manual](docs/USER_MANUAL.md) for comprehensive documentation
- Browse the [FAQ](docs/FAQ.md) for common questions and answers

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
- `EDITOR` - Default editor for multi-line commands (default: nano)
- `COMMAND_STORE` - Custom location for storing aliases
- `THEME` - UI theme (default, dark, light, minimal)
- `DEFAULT_UI` - Default interface mode (cli, tui)

## Cloud Synchronization

Synchronize your commands across multiple machines:

```bash
# Setup sync with GitHub
aliasmate sync setup --provider github

# Push your commands to the cloud
aliasmate sync push

# Pull commands from the cloud
aliasmate sync pull
```

## Tab Completion

Generate and install shell completion:

```bash
# For Bash
echo 'source <(aliasmate completion bash)' >> ~/.bashrc

# For Zsh
echo 'source <(aliasmate completion zsh)' >> ~/.zshrc
```

## Contributing

Contributions are welcome! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
