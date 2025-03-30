# AliasMate Usage Guide

This guide explains how to use AliasMate to manage your command aliases effectively.

## Basic Usage

### Terminal User Interface (TUI)

The easiest way to use AliasMate is through its Terminal User Interface:

```bash
aliasmate --tui
```

This will open a menu-driven interface that provides access to all features:

![TUI Main Menu](images/tui-menu.png)

Navigate using the arrow keys and press Enter to select an option.

### Command Line Interface (CLI)

For quick operations or in scripts, you can use the command line interface.

## Managing Commands

### Saving Commands

```bash
# Basic syntax
aliasmate save <alias> <command>

# Examples
aliasmate save list-ports "netstat -tuln"
aliasmate save check-disk "df -h | grep /dev/sda"
```

#### With Categories

```bash
# Assign a category
aliasmate save backup-db "pg_dump mydb > backup.sql" --category database
```

#### Multi-line Commands

```bash
# Open editor for complex commands
aliasmate save deploy-app --multi
```

This will open your default editor (configured via `EDITOR`) where you can enter a multi-line command.

### Running Commands

```bash
# Basic syntax
aliasmate run <alias>

# Examples
aliasmate run list-ports
aliasmate run backup-db
```

#### With Custom Path

By default, commands run in the same directory where they were saved. To override:

```bash
aliasmate run backup-db --path /different/path
```

#### With Arguments

```bash
aliasmate run deploy-app --args "--force --version=1.2.3"
```

### Listing Commands

```bash
# List all commands
aliasmate ls

# List with a specific category
aliasmate ls --category database

# Sort by usage count
aliasmate ls --sort usage

# Different output formats
aliasmate ls --format json
aliasmate ls --format csv
aliasmate ls --format names  # Just alias names
```

### Searching Commands

```bash
# Search all fields
aliasmate search postgres

# Search in specific fields
aliasmate search nginx --command  # Only in command text
aliasmate search db --alias       # Only in alias names
aliasmate search /var --path      # Only in paths

# Search in a category
aliasmate search backup --category database
```

### Editing Commands

```bash
# Edit all fields
aliasmate edit backup-db

# Edit specific fields
aliasmate edit backup-db --cmd      # Just the command
aliasmate edit backup-db --path     # Just the path
aliasmate edit backup-db --category # Just the category
```

### Removing Commands

```bash
# Remove a command
aliasmate rm backup-db

# Remove without confirmation
aliasmate rm backup-db --force
```

## Managing Categories

```bash
# List all categories
aliasmate categories

# Add a new category
aliasmate categories add project-x

# Remove a category
aliasmate categories rm project-x

# Rename a category
aliasmate categories rename project-x new-project
```

## Import and Export

### Exporting Commands

```bash
# Export all commands
aliasmate export --output my_commands.json

# Export in different formats
aliasmate export --format json  # Default
aliasmate export --format yaml
aliasmate export --format csv

# Export a specific command
aliasmate export backup-db --output backup-db.json
```

### Importing Commands

```bash
# Import commands
aliasmate import my_commands.json

# Merge with existing commands
aliasmate import my_commands.json --merge
```

## Statistics

```bash
# Show command usage statistics
aliasmate stats

# Reset statistics
aliasmate stats --reset

# Export statistics
aliasmate stats --export stats.json
```

## Batch Operations

```bash
# Batch import multiple files
aliasmate batch import /path/to/files/

# Batch edit commands matching a pattern
aliasmate batch edit "database" category "db-commands"

# Batch run commands matching a pattern
aliasmate batch run "backup" --path /custom/path
```

## Cloud Synchronization

```bash
# Set up sync with GitHub
aliasmate sync setup --provider github --token YOUR_TOKEN --repo user/repo

# Push commands to cloud
aliasmate sync push

# Pull commands from cloud
aliasmate sync pull

# Check sync status
aliasmate sync status
```

## Configuration

```bash
# List current configuration
aliasmate config list

# Get a specific setting
aliasmate config get EDITOR

# Set a configuration value
aliasmate config set EDITOR vim
aliasmate config set DEFAULT_UI tui
aliasmate config set THEME dark

# Reset configuration to defaults
aliasmate config reset
```

## Keyboard Shortcuts in TUI

| Key | Function |
|-----|----------|
| Tab | Navigate between fields |
| Enter | Select/Confirm |
| Esc | Cancel/Back |
| Arrow keys | Navigate menus |
| h | Help screen |
| q | Quit current screen |
| / | Search |
| r | Refresh current view |
| s | Save new command |
| e | Edit selected command |
| d | Delete selected command |
