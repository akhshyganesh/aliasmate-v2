# AliasMate v2 Onboarding Guide

Welcome to AliasMate v2! This guide will help you get started with this powerful command management tool.

## What is AliasMate?

AliasMate is a command management tool that helps you store, organize, and execute your frequently used shell commands. It's designed to save you time and reduce errors by providing an easy way to manage complex commands.

## Installation

### Quick Installation

```bash
# Using curl
curl -sSL https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/scripts/install.sh | bash

# Using wget
wget -qO- https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/scripts/install.sh | bash
```

### Manual Installation

```bash
git clone https://github.com/akhshyganesh/aliasmate-v2.git
cd aliasmate-v2
./scripts/build.sh
sudo ./scripts/install.sh
```

## Troubleshooting Installation

If you encounter issues during installation:

### Command Not Found After Installation

If the `aliasmate` command is not found after installation, try the following:

1. **Add the installation directory to your PATH**:
   ```bash
   echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
   source ~/.bashrc
   ```

2. **Create a symlink in a directory that's in your PATH**:
   ```bash
   sudo ln -sf /usr/local/bin/aliasmate /usr/bin/aliasmate
   ```

3. **Check the installation log for errors**:
   Look for error messages in the installation output.

4. **Verify the executable exists**:
   ```bash
   ls -la /usr/local/bin/aliasmate
   ```
   If it exists but isn't working, ensure it has execute permissions:
   ```bash
   sudo chmod +x /usr/local/bin/aliasmate
   ```

5. **For Docker/container environments**:
   Some containers may have limited PATH settings or security policies. 
   Use the Docker-specific installation commands from the README.

### For More Help

If you continue to experience issues, please open an issue on our GitHub repository:
[https://github.com/akhshyganesh/aliasmate-v2/issues](https://github.com/akhshyganesh/aliasmate-v2/issues)

## First Steps

After installation, you'll want to:

1. **Verify installation**: Run `aliasmate --version` to confirm AliasMate is installed correctly.
2. **Start the TUI**: Run `aliasmate --tui` for an interactive interface (recommended for beginners).
3. **Set up shell completion**: This should happen automatically during installation, but you might need to restart your shell.

## Basic Usage

### Saving Commands

```bash
# Basic command saving
aliasmate save deploy "kubectl apply -f deployment.yaml"

# Save with a specific path
aliasmate save build-frontend "npm run build" --path ~/projects/frontend

# Save with a category
aliasmate save db-backup "pg_dump -U postgres db > backup.sql" --category database
```

### Running Commands

```bash
# Run a saved command
aliasmate run deploy

# List available commands
aliasmate ls

# Search for commands
aliasmate search kubectl
```

### Organizing Commands

```bash
# Create a new category
aliasmate category create project-x

# List all categories
aliasmate category ls

# Move a command to a category
aliasmate move deploy project-x
```

## Advanced Features

### Command Statistics

```bash
# View command usage statistics
aliasmate stats
```

### Multi-line Commands

```bash
# Create a multi-line command
aliasmate save backup --multi
# This will open your editor where you can enter multiple lines
```

### Cloud Synchronization

```bash
# Set up GitHub sync
aliasmate sync config --provider github --token YOUR_GITHUB_TOKEN --repo your-repo-name

# Enable sync
aliasmate sync enable

# Manually sync commands
aliasmate sync now
```

### Batch Operations

```bash
# Export commands to a file
aliasmate export all commands.json

# Import commands from a file
aliasmate import commands.json
```

## Tips & Tricks

1. **Use the TUI**: The text-based UI (`aliasmate --tui`) is great for exploring and managing your commands.
2. **Tab Completion**: Use tab completion to quickly enter command names and options.
3. **Aliases for AliasMate**: Set up an alias for the aliasmate command itself, e.g., `alias am='aliasmate'`

## Getting Help

- Use `aliasmate --help` or `aliasmate [command] --help` for command-specific help
- Check the [GitHub repository](https://github.com/akhshyganesh/aliasmate-v2) for more documentation
- Open an issue if you encounter any problems

## Next Steps

Now that you're set up with AliasMate, consider:

1. Migrating your existing aliases and complex commands
2. Setting up categories for different projects or contexts
3. Exploring the statistics to see which commands you use most frequently
4. Setting up cloud synchronization if you work across multiple machines
