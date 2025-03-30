# AliasMate v2 API Reference

This document describes the internal API of AliasMate v2 for developers who want to extend the functionality or integrate it with other tools.

## Module Structure

AliasMate is organized into modular components:

1. **Core Modules** - Essential functionality located in `src/core/`
2. **Feature Modules** - Specific features located in `src/`
3. **Configuration** - Located in `config/`

## Core Modules

### config.sh

Functions for managing configuration.

```bash
# Load configuration from config files
# Returns:
#   Sets global configuration variables
load_config()

# Get a configuration value
# Arguments:
#   $1 - Configuration key
# Returns:
#   Configuration value (stdout)
get_config()

# Set a configuration value
# Arguments:
#   $1 - Configuration key
#   $2 - Configuration value
# Returns:
#   0 on success, 1 on failure
set_config()
```

### logging.sh

Functions for logging.

```bash
# Initialize the logging system
# Returns:
#   0 on success
init_logging()

# Log a message at debug level
# Arguments:
#   $1 - Message to log
log_debug()

# Log a message at info level
# Arguments:
#   $1 - Message to log
log_info()

# Log a message at warning level
# Arguments:
#   $1 - Message to log
log_warning()

# Log a message at error level
# Arguments:
#   $1 - Message to log
log_error()
```

### utils.sh

Utility functions.

```bash
# Check if a command exists
# Arguments:
#   $1 - Command to check
# Returns:
#   0 if command exists, 1 otherwise
command_exists()

# Validate an alias name
# Arguments:
#   $1 - Alias name to validate
# Returns:
#   0 if valid, 1 otherwise
validate_alias()

# Generate a unique ID
# Arguments:
#   $1 - Optional prefix
# Returns:
#   Unique ID (stdout)
generate_id()
```

## Feature Modules

### commands.sh

Functions for managing commands.

```bash
# Save a command with an alias
# Arguments:
#   $1 - Alias name
#   $2 - Command to save
#   --category - Optional category (default: general)
#   --multi - Flag to enable multi-line command input
# Returns:
#   0 on success, 1 on failure
save_command()

# Run a command by its alias
# Arguments:
#   $1 - Alias name
#   --path - Optional path override
#   --args - Optional arguments to pass to the command
# Returns:
#   Exit code of the command
run_command()

# List all saved commands
# Arguments:
#   --category - Optional category filter
#   --format - Output format (table, json, csv, names)
#   --sort - Sort field (alias, path, runs, last_run)
# Returns:
#   Formatted command list (stdout)
list_commands()

# Edit an existing command
# Arguments:
#   $1 - Alias name
#   --cmd - Flag to edit only the command
#   --path - Flag to edit only the path
#   --category - Flag to edit only the category
# Returns:
#   0 on success, 1 on failure
edit_command()

# Remove a command
# Arguments:
#   $1 - Alias name
#   --force - Flag to skip confirmation
# Returns:
#   0 on success, 1 on failure
remove_command()
```

### categories.sh

Functions for managing categories.

```bash
# List all categories
# Arguments:
#   --format - Output format (table, json, csv, names)
# Returns:
#   Formatted category list (stdout)
list_categories()

# Add a new category
# Arguments:
#   $1 - Category name
# Returns:
#   0 on success, 1 on failure
add_category()

# Remove a category
# Arguments:
#   $1 - Category name
#   --force - Skip confirmation
# Returns:
#   0 on success, 1 on failure
remove_category()

# Rename a category
# Arguments:
#   $1 - Old category name
#   $2 - New category name
# Returns:
#   0 on success, 1 on failure
rename_category()
```

### search.sh

Functions for searching commands.

```bash
# Search commands by name, content, or path
# Arguments:
#   $1 - Search term
#   --category - Optional category filter
#   --command - Flag to search only in command content
#   --path - Flag to search only in paths
#   --alias - Flag to search only in alias names
# Returns:
#   Formatted search results (stdout)
search_commands()
```

### sync.sh

Functions for cloud synchronization.

```bash
# Setup cloud synchronization
# Arguments:
#   --provider - Sync provider (github, gitlab, dropbox, local)
#   --token - Authentication token
#   --repo - Repository or path
# Returns:
#   0 on success, 1 on failure
setup_sync()

# Push commands to remote storage
# Returns:
#   0 on success, 1 on failure
sync_push()

# Pull commands from remote storage
# Returns:
#   0 on success, 1 on failure
sync_pull()

# Check sync status
# Returns:
#   Sync status information (stdout)
sync_status()
```

### stats.sh

Functions for command statistics.

```bash
# Show command usage statistics
# Arguments:
#   --reset - Flag to reset statistics
#   --export - Export file path
# Returns:
#   Formatted statistics (stdout)
show_stats()

# Record command execution
# Arguments:
#   $1 - Alias name
#   $2 - Execution duration
#   $3 - Exit code
# Returns:
#   0 on success
record_execution()
```

### tui.sh

Functions for the terminal user interface.

```bash
# Launch the TUI
# Returns:
#   0 on success, non-zero on error
launch_tui()
```

## Data Storage

### Command Storage Format

Commands are stored as JSON files:

```json
{
  "alias": "command-name",
  "command": "actual command to run",
  "path": "/default/execution/path",
  "category": "category-name",
  "created": 1636729998,
  "modified": 1636729998,
  "runs": 5,
  "last_run": 1636730000,
  "last_exit_code": 0,
  "last_duration": 0.5
}
```

### Directory Structure

