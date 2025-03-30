# AliasMate Tips and Tricks

This guide provides practical tips and tricks to help you get the most out of AliasMate.

## Command Naming Strategies

### Use Prefixes for Organization

Even with categories, using consistent prefixes helps with discovery:

```bash
# Docker-related commands
aliasmate save d-build "docker build -t myapp ."
aliasmate save d-run "docker run -p 8080:80 myapp"
aliasmate save d-logs "docker logs -f"

# Git-related commands
aliasmate save g-sync "git fetch && git pull"
aliasmate save g-clean "git clean -fd && git reset --hard"
```

### Create Command Families

Group related commands with shared naming conventions:

```bash
# Environment-specific deploy commands
aliasmate save deploy-dev "kubectl apply -f dev-deployment.yaml"
aliasmate save deploy-stage "kubectl apply -f stage-deployment.yaml"
aliasmate save deploy-prod "kubectl apply -f prod-deployment.yaml"
```

## Shell Integration Tips

### Create a Quick "Last Command" Shortcut

Add this to your `.bashrc` or `.zshrc`:

```bash
# Save the last executed command with an alias
last_cmd() {
  local cmd=$(fc -ln -1)
  aliasmate save "$1" "$cmd"
  echo "Command saved as '$1'"
}
alias alast='last_cmd'
```

Now you can quickly save the last command you executed:

```bash
# Run a complex command
find . -name "*.log" -type f -mtime +30 -exec rm {} \;

# Save it with an alias
alast cleanup-logs
```

### Custom Directory Navigation

Combine AliasMate with directory navigation:

```bash
# Add this to your .bashrc or .zshrc
goto() {
  local cmd_file="$HOME/.local/share/aliasmate/$1.json"
  if [[ -f "$cmd_file" ]]; then
    local path=$(jq -r '.path' "$cmd_file")
    if [[ -d "$path" ]]; then
      cd "$path" || return
      echo "Navigated to $(pwd)"
    else
      echo "Path no longer exists: $path"
    fi
  else
    echo "Unknown location: $1"
  fi
}
```

Use it to quickly navigate to command directories:

```bash
# Go to the directory associated with a command
goto project-build
```

## Command Templating Patterns

### Create Command Templates

Use placeholders in your commands:

```bash
# Save a template command
aliasmate save ssh-to "ssh user@__HOST__ -p __PORT__"

# Add a helper function to your shell
run_template() {
  local cmd_name="$1"
  shift
  local args="$*"
  aliasmate run "$cmd_name" --args "$args"
}
```

Then use it like this:

```bash
# Connect to different servers with the same template
run_template ssh-to "HOST=dev.example.com PORT=22"
run_template ssh-to "HOST=prod.example.com PORT=2222"
```

### Multi-step Commands

Create commands that execute multiple steps:

```bash
aliasmate save deploy-full --multi
```

Then in the editor:

```bash
#!/bin/bash
# Full deployment workflow
echo "Starting deployment..."

# Step 1: Build
echo "Building application..."
npm run build

# Step 2: Test
echo "Running tests..."
npm test

# Step 3: Deploy
echo "Deploying to server..."
rsync -avz --delete dist/ user@server:/var/www/app/

echo "Deployment complete!"
```

## TUI Power Tips

### Keyboard Navigation Efficiency

In the TUI mode, remember these shortcuts:

- **Tab**: Move between fields
- **Ctrl+N/Ctrl+P**: Next/Previous item in some dialogs
- **Space**: Select item in checkbox lists
- **/:?**: Search in some list views
- **q**: Quit current screen
- **h**: Help

### Custom TUI Colors

If you find the default colors hard to see, customize the theme:

```bash
# High contrast dark theme
aliasmate config set THEME dark

# More subtle light theme
aliasmate config set THEME light

# Minimal theme with fewer colors
aliasmate config set THEME minimal
```

## Working with Large Command Sets

### Create Project-specific Command Files

For each project, maintain a separate export file:

```bash
# Export all project-related commands
aliasmate ls --category myproject --format json > myproject-commands.json

# Later, import them when needed
aliasmate import myproject-commands.json --merge
```

### Use with Shell Project Switchers

If you use a project management tool like `direnv`, integrate AliasMate:

```bash
# In your .envrc file
export ALIASMATE_PROJECT="myproject"
aliasmate import ./.aliasmate-commands.json --merge > /dev/null 2>&1
echo "Loaded project-specific commands"
```

## Backup Strategies

### Automated Backups

Set up a cron job to create periodic backups:

```bash
# Add to crontab (weekly backup on Sunday at 1 AM)
0 1 * * 0 aliasmate export --output "$HOME/backups/aliasmate_$(date +\%Y\%m\%d).json" > /dev/null 2>&1
```

### Version Control Your Commands

Keep your command configurations in a private git repository:

```bash
# Create a git repo for your commands
mkdir -p ~/dotfiles/aliasmate
cd ~/dotfiles/aliasmate
git init

# Export your commands
aliasmate export --output commands.json

# Add to git
git add commands.json
git commit -m "Update command library"
```

## Troubleshooting Tips

### Force Refresh Command Cache

If commands seem stale or missing:

```bash
# Clear the cache
rm -rf ~/.cache/aliasmate/*

# Force reload
aliasmate sync pull --force
```

### Recovery from Corrupt Command Store

If your command store becomes corrupted:

```bash
# Create a backup first
cp -r ~/.local/share/aliasmate ~/aliasmate_backup

# Export everything that's still readable
aliasmate export --output ~/aliasmate_rescue.json

# Reset the command store
rm -rf ~/.local/share/aliasmate/*

# Import the rescued commands
aliasmate import ~/aliasmate_rescue.json
```

## Performance Tips

### Slim Down Your Command Store

For best performance, periodically clean up:

```bash
# Find unused commands
aliasmate stats | grep "Never used" | awk '{print $1}' > ~/unused_commands.txt

# Review and clean up
while read -r cmd; do
  aliasmate rm "$cmd" --force
done < ~/unused_commands.txt
```

### Use Fast Storage

If possible, move your command store to fast storage:

```bash
# Move to RAM disk for maximum performance (temporary)
aliasmate config set COMMAND_STORE /dev/shm/aliasmate

# Or use SSD storage (permanent)
aliasmate config set COMMAND_STORE ~/ssd/aliasmate
```
