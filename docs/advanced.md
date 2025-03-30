# AliasMate Advanced Usage Guide

This document covers advanced features and techniques for getting the most out of AliasMate.

## Command Management Strategies

### Working with Complex Commands

For multi-line commands or scripts, use the `--multi` flag when saving:

```bash
aliasmate save backup-db --multi
```

This will open your configured editor where you can create complex commands with proper formatting:

```bash
#!/bin/bash
# This is a database backup script
TODAY=$(date +%Y%m%d)
echo "Starting backup on $TODAY..."

# Create backup directory if it doesn't exist
mkdir -p ~/backups/db

# Perform database backup
pg_dump mydb > ~/backups/db/mydb_backup_$TODAY.sql

# Compress the backup
gzip ~/backups/db/mydb_backup_$TODAY.sql

echo "Backup completed successfully!"
```

### Parameterizing Commands

You can make commands more flexible by using the `--args` option when running:

```bash
# Save a command with placeholders
aliasmate save deploy "kubectl apply -f TEMPLATE_FILE -n NAMESPACE"

# Run with specific arguments
aliasmate run deploy --args "TEMPLATE_FILE=deployment.yaml NAMESPACE=production"
```

### Command Naming Conventions

Adopt a consistent naming convention for better organization:

- **Prefixes**: Use prefixes for related commands (`db-backup`, `db-restore`)
- **Environment indicators**: Include environment in name (`deploy-prod`, `deploy-stage`)
- **Verb-noun format**: Start with actions (`build-app`, `test-api`, `clean-logs`)

## Category Management

### Hierarchical Categories

Create a hierarchical organization using naming conventions:

```bash
# Create categories for different environments
aliasmate categories add dev
aliasmate categories add stage
aliasmate categories add prod

# Create project-specific categories
aliasmate categories add project1
aliasmate categories add project2

# Save commands with specific categories
aliasmate save build-p1-dev "npm run build:dev" --category project1
aliasmate save deploy-p1-prod "kubectl apply -f deploy.yaml" --category prod
```

### Category Migration

Move commands between categories:

```bash
# List commands in old category
aliasmate ls --category old-category

# For each command, update its category
aliasmate edit my-command --category
# Then enter the new category name
```

## Performance Optimization

### Batch Operations

For managing large command sets, use export/import for batch operations:

```bash
# Export all commands
aliasmate export --output all-commands.json

# Modify the JSON file with a text editor or script
# Then import the modified commands
aliasmate import all-commands.json --merge
```

### Cleanup Unused Commands

Regularly clean up commands you no longer use:

```bash
# Find unused commands
aliasmate stats | grep "Never"

# Remove unused commands
aliasmate rm <unused-command>
```

## Cloud Synchronization

### Advanced GitHub Sync

Use GitHub sync with personal branches:

```bash
# Set up sync with your personal branch
aliasmate sync setup --provider github --repo your-username/your-repo --branch personal-commands

# Create separate synchronized profiles
mkdir -p ~/.config/aliasmate/profiles/work
mkdir -p ~/.config/aliasmate/profiles/personal

# Set different command stores
aliasmate config set COMMAND_STORE ~/.config/aliasmate/profiles/work
```

### Automated Sync

Set up cron jobs for automatic synchronization:

```bash
# Add to crontab (sync every hour)
(crontab -l 2>/dev/null; echo "0 * * * * aliasmate sync pull > /dev/null 2>&1") | crontab -
```

## Integration with Other Tools

### Shell Integration

Add useful shell functions to your `.bashrc` or `.zshrc`:

```bash
# Quick alias for saving current command
save_last_cmd() {
  LASTCMD=$(fc -ln -1)
  aliasmate save "$1" "$LASTCMD"
}
alias alast='save_last_cmd'

# Quick search and execute
amfind() {
  aliasmate search "$1" | grep -v "^Found" | grep -v "^$" | grep -v "Search"
}
```

### Git Hooks Integration

Use AliasMate with Git hooks:

```bash
# Create a post-checkout hook
cat > .git/hooks/post-checkout << 'EOF'
#!/bin/bash
# Load project-specific aliases
if [ -f .aliasmate-commands.json ]; then
  aliasmate import .aliasmate-commands.json --merge
  echo "Loaded project commands from .aliasmate-commands.json"
fi
EOF
chmod +x .git/hooks/post-checkout
```

## Troubleshooting

### Debugging Command Execution

To debug command execution problems:

```bash
# Set log level to debug
aliasmate config set LOG_LEVEL debug

# Run the command
aliasmate run problematic-command

# Check the logs
cat /tmp/aliasmate.log
```

### Repairing Corrupt Commands

If you encounter corrupt command files:

```bash
# Export all working commands
aliasmate export --output backup.json

# Reset the command store
rm -rf $(aliasmate config get COMMAND_STORE)
aliasmate # Run once to recreate directories

# Import the backup
aliasmate import backup.json
```

## Performance Tips

- **Keep categories focused**: Too many categories can slow down performance
- **Use meaningful search terms**: Be specific when searching to reduce result sets
- **Archive old commands**: Export rarely used commands to separate files
- **Use the TUI for large command libraries**: The TUI handles large command sets more efficiently

## Security Considerations

- **Sensitive information**: Avoid storing sensitive credentials in commands
- **Use environment variables**: For tokens, passwords or keys
- **Sync security**: Be careful when syncing to public repositories
- **Inspect imported commands**: Always review commands before importing from others
