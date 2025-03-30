# Migrating from AliasMate v1 to v2

This guide helps users migrate from AliasMate v1 to v2, explaining key differences and providing a migration path.

## Key Changes in v2

AliasMate v2 includes many improvements over v1:

1. **New Architecture**: Completely rewritten for better performance and maintainability
2. **TUI Mode**: A full-featured Text User Interface
3. **Command Categories**: Organize commands by project or purpose
4. **Enhanced Search**: More powerful search capabilities
5. **Command Statistics**: Track how often commands are used
6. **Cloud Synchronization**: Sync commands across machines
7. **Better Path Handling**: Improved working directory management
8. **Multi-format Import/Export**: Support for JSON, YAML, and CSV
9. **Tab Completion**: Built-in completion for bash and zsh
10. **Documentation**: Comprehensive docs and examples

## Data Structure Changes

The command data format in v2 has been extended to include:

- **categories**: Organize commands by purpose/project
- **created/modified**: Timestamps for when commands were created/changed
- **runs**: Count of how many times a command has been executed
- **last_run**: When the command was last executed
- **last_exit_code**: Success/failure status of last execution
- **last_duration**: How long the command took to run

## Migration Process

### Automatic Migration

The easiest way to migrate is to let AliasMate v2 handle it automatically:

```bash
# Install AliasMate v2
curl -sSL https://raw.githubusercontent.com/akhshyganesh/aliasmate-v2/main/scripts/install.sh | bash

# Run AliasMate v2 for the first time
aliasmate

# If v1 data is detected, you'll be prompted to migrate
```

### Manual Migration Steps

If you prefer to migrate manually:

1. **Export v1 commands**:
   ```bash
   # Using AliasMate v1
   aliasmate export > v1_commands.json
   ```

2. **Import into v2**:
   ```bash
   # Using AliasMate v2
   aliasmate import v1_commands.json
   ```

3. **Verify the migration**:
   ```bash
   aliasmate ls
   ```

### Managing Command Categories

After migration, commands from v1 will be assigned to the "general" category. We recommend organizing them:

1. **Create categories**:
   ```bash
   aliasmate categories add project1
   aliasmate categories add project2
   ```

2. **Update command categories**:
   ```bash
   aliasmate edit my-command --category
   # Then enter the new category name
   ```

3. **Batch update commands**:
   ```bash
   aliasmate batch edit "project1" category "project1"
   ```

## Differences in Command Usage

### Command Format Changes

| Feature | v1 | v2 |
|---------|----|----|
| Save Command | `aliasmate add cmd "echo hi"` | `aliasmate save cmd "echo hi"` |
| Run Command | `aliasmate cmd` | `aliasmate run cmd` |
| List Commands | `aliasmate list` | `aliasmate ls` |
| Remove Command | `aliasmate remove cmd` | `aliasmate rm cmd` |
| Edit Command | `aliasmate edit cmd` | `aliasmate edit cmd` (unchanged) |

### New v2 Commands

These commands are new in v2:

1. **Categories**:
   ```bash
   aliasmate categories
   aliasmate categories add project1
   aliasmate categories rm project1
   ```

2. **Statistics**:
   ```bash
   aliasmate stats
   aliasmate stats --reset
   ```

3. **Search**:
   ```bash
   aliasmate search term
   aliasmate search term --category project1
   aliasmate search term --command  # Search command content
   ```

4. **Sync**:
   ```bash
   aliasmate sync setup
   aliasmate sync push
   aliasmate sync pull
   ```

5. **Configuration**:
   ```bash
   aliasmate config list
   aliasmate config set EDITOR vim
   ```

6. **TUI Mode**:
   ```bash
   aliasmate --tui
   ```

## Configuration Differences

AliasMate v2 uses a YAML configuration file instead of environment variables:

### v1 (Environment Variables)

```bash
export ALIASMATE_DIR="$HOME/.aliases"
```

### v2 (Config File)

```yaml
# ~/.config/aliasmate/config.yaml
COMMAND_STORE: $HOME/.local/share/aliasmate
EDITOR: nano
DEFAULT_UI: cli
```

To modify v2 configuration:

```bash
aliasmate config set COMMAND_STORE ~/my/custom/path
```

## Common Migration Issues

### Missing Commands

If some commands aren't migrated automatically:

```bash
# Check if they're in the v1 export
cat v1_commands.json

# If they're there but didn't import, try forcing the import
aliasmate import v1_commands.json --force
```

### Path Differences

v1 and v2 handle paths differently:

```bash
# Update command paths if needed
aliasmate ls --format json > all_commands.json
# Edit the JSON to update paths
aliasmate import all_commands.json --merge
```

### Custom Scripts Using AliasMate

If you have scripts that use AliasMate v1, update them:

```bash
# Old v1 usage in scripts
aliasmate add temp_cmd "echo test"
aliasmate temp_cmd
aliasmate remove temp_cmd

# New v2 usage in scripts
aliasmate save temp_cmd "echo test"
aliasmate run temp_cmd
aliasmate rm temp_cmd
```

## Return to Previous Version

If you need to return to v1 temporarily:

1. **Back up v2 data**:
   ```bash
   aliasmate export --output v2_backup.json
   ```

2. **Reinstall v1**:
   ```bash
   # Follow v1 installation instructions from the v1 repository
   ```

3. **Note**: v1 and v2 use different storage locations by default, so your v1 data should still be intact.

## Getting Help

If you encounter issues during migration:

1. Check the logs: `cat /tmp/aliasmate.log`
2. Read the documentation: `aliasmate --help`
3. Open an issue on our GitHub repository
