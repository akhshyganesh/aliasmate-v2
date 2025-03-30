# AliasMate v2 Documentation

Welcome to the AliasMate v2 documentation. This guide will help you get started with AliasMate and make the most of its features.

## What is AliasMate?

AliasMate is a powerful command management tool that helps you store, organize, and execute your most frequently used shell commands with ease. It remembers not just the commands but also the directories where they should be executed, making it perfect for project-specific commands.

## Key Features

- **Command Aliases**: Store any command with a memorable name
- **Path Tracking**: Commands remember where they should be executed
- **Categories**: Organize commands by projects or contexts
- **Interactive TUI**: Easy-to-use terminal interface
- **Command History**: Track command usage and success rates
- **Multi-line Commands**: Support for complex scripts
- **Import/Export**: Share your command libraries
- **Auto-completion**: Tab completion for bash and zsh
- **Cloud Sync**: Synchronize your commands across machines

## Quick Start

### Installation

```bash
# Quick installation with curl
curl -sSL https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash

# Or with wget
wget -qO- https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash
```

### Basic Usage

1. **Save a command**

   ```bash
   # Save a simple command
   aliasmate save deploy "kubectl apply -f deployment.yaml"
   
   # Save a command with a category
   aliasmate save dbbackup "pg_dump mydb > backup.sql" --category database
   
   # Save a multi-line command
   aliasmate save complex --multi
   ```

2. **Run a command**

   ```bash
   # Run with default path
   aliasmate run deploy
   
   # Run with a custom path
   aliasmate run deploy --path /other/directory
   
   # Run with additional arguments
   aliasmate run dbbackup --args "--schema-only"
   ```

3. **List your commands**

   ```bash
   # List all commands
   aliasmate ls
   
   # List by category
   aliasmate ls --category database
   
   # Sort by usage
   aliasmate ls --sort usage
   ```

4. **Search commands**

   ```bash
   # Search by term
   aliasmate search kubectl
   
   # Search in a specific category
   aliasmate search db --category database
   ```

5. **Work with categories**

   ```bash
   # List categories
   aliasmate categories
   
   # Add a category
   aliasmate categories add project-x
   
   # Remove a category
   aliasmate categories rm project-x
   ```

6. **Import and export**

   ```bash
   # Export all commands
   aliasmate export --output my_commands.json
   
   # Export a specific category
   aliasmate export --category database
   
   # Import commands
   aliasmate import my_commands.json
   ```

7. **Check command statistics**

   ```bash
   # Show usage statistics
   aliasmate stats
   
   # Reset statistics
   aliasmate stats --reset
   ```

## Using the TUI

AliasMate includes a Text-based User Interface (TUI) that makes it easy to manage your commands:

```bash
aliasmate --tui
```

The TUI provides a menu-driven interface for all AliasMate functions:

- List and search commands
- Save new commands
- Run commands with custom options
- Edit existing commands
- Manage categories
- Import and export commands
- Check statistics
- Configure settings

## Configuration

AliasMate can be configured using the `config` command:

```bash
# List current configuration
aliasmate config list

# Get a specific setting
aliasmate config get EDITOR

# Set a configuration value
aliasmate config set DEFAULT_UI tui
```

### Important Configuration Options

- `COMMAND_STORE`: Location where commands are stored
- `EDITOR`: Default editor for multi-line commands
- `DEFAULT_UI`: Default interface (cli or tui)
- `THEME`: UI color theme
- `SYNC_ENABLED`: Enable/disable cloud sync

## Cloud Synchronization

AliasMate can synchronize your commands across multiple machines:

```bash
# Set up sync
aliasmate sync setup

# Push local commands to the cloud
aliasmate sync push

# Pull commands from the cloud
aliasmate sync pull

# Check sync status
aliasmate sync status
```

Supported sync providers:
- GitHub
- GitLab
- Dropbox
- Local directory (for NFS or other shared storage)

## Tab Completion

AliasMate provides tab completion for both Bash and Zsh:

```bash
# Enable for Bash
echo 'source <(aliasmate completion bash)' >> ~/.bashrc

# Enable for Zsh
echo 'source <(aliasmate completion zsh)' >> ~/.zshrc
```

## Troubleshooting

If you encounter issues with AliasMate, try these steps:

1. Check your configuration: `aliasmate config list`
2. View the logs: `cat /tmp/aliasmate.log`
3. Update to the latest version: `aliasmate --upgrade`
4. Reset configuration: `aliasmate config reset`

For more help, visit the [GitHub repository](https://github.com/akhshyganesh/aliasmate-v2) or open an issue.
