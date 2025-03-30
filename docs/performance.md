# Performance Optimization Guide

This guide provides tips and best practices for optimizing AliasMate's performance, especially when managing large command libraries.

## General Optimizations

### Use Categories Effectively

Organize your commands into logical categories:

```bash
# Create focused categories
aliasmate categories add kubernetes
aliasmate categories add database
aliasmate categories add devops

# Save commands with appropriate categories
aliasmate save k8s-pods "kubectl get pods" --category kubernetes
```

This improves both search performance and organization.

### Prefer TUI for Large Libraries

The Text User Interface (TUI) is optimized for large command sets:

```bash
aliasmate --tui
```

TUI includes pagination and more efficient data handling for large collections.

### Use Specific Search Terms

When searching, be as specific as possible:

```bash
# Less efficient - broad search
aliasmate search db

# More efficient - specific search
aliasmate search postgres --category database
```

### Use Specific Output Formats

When you only need certain information, use specific output formats:

```bash
# When you only need names
aliasmate ls --format names

# When you need structured data for scripting
aliasmate ls --format json
```

## Command Management

### Archive Unused Commands

Regularly export and remove rarely used commands:

```bash
# Export commands not used in a long time
aliasmate stats | grep "Never" | awk '{print $1}' > unused.txt
while read -r cmd; do
  aliasmate export "$cmd" --output "archive/$cmd.json"
  aliasmate rm "$cmd" --force
done < unused.txt
```

### Batch Operations

For bulk changes, use batch operations:

```bash
# Edit multiple commands at once
aliasmate batch edit "old-path" path "/new/path"

# Import multiple command files
aliasmate batch import ./commands/
```

## Technical Optimizations

### Command Store Location

For faster disk I/O, consider moving your command store to a faster storage location:

```bash
# Move to SSD or RAM disk
aliasmate config set COMMAND_STORE /mnt/ssd/aliasmate
```

### Caching

AliasMate implements caching for frequently accessed data. To clear the cache if needed:

```bash
rm -rf ~/.cache/aliasmate/*
```

### Background Processing

For resource-intensive operations, AliasMate can run tasks in the background:

```bash
# Export large command sets
aliasmate export --output large-export.json &
```

## Statistics Management

### Prune Historical Data

For very active command usage, consider periodically resetting statistics:

```bash
# Keep overall usage counts but clear detailed history
aliasmate stats --reset
```

## Synchronization Optimization

### Selective Synchronization

Instead of syncing everything, create separate profiles:

```bash
# Create work profile
mkdir -p ~/.config/aliasmate/profiles/work
aliasmate config set COMMAND_STORE ~/.config/aliasmate/profiles/work

# Set up sync
aliasmate sync setup --provider github --repo work/commands

# Create personal profile
mkdir -p ~/.config/aliasmate/profiles/personal
aliasmate config set COMMAND_STORE ~/.config/aliasmate/profiles/personal

# Set up different sync
aliasmate sync setup --provider github --repo personal/commands
```

### Scheduled Synchronization

Set up automatic synchronization during idle times:

```bash
# Add to crontab (sync at midnight)
crontab -e
# Add line:
0 0 * * * aliasmate sync pull > /dev/null 2>&1
```

## Monitoring Performance

### Logging

Enable debug logging to identify performance bottlenecks:

```bash
aliasmate config set LOG_LEVEL debug
```

Then check the logs for performance insights:

```bash
grep "duration" /tmp/aliasmate.log
```

## Hardware Recommendations

For very large command libraries (1000+ commands):

- Use SSD storage for command store
- Ensure at least 4GB of RAM
- Use a modern multi-core processor

## Best Practices Summary

1. **Organize with categories**: Keep related commands together
2. **Use specific searches**: Narrow down search criteria
3. **Archive infrequently used commands**: Export and remove rarely used commands
4. **Use batch operations**: For bulk changes
5. **Choose the right UI**: TUI for large libraries, CLI for scripts
6. **Monitor and tune**: Check logs for performance issues
