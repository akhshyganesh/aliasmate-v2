# AliasMate

AliasMate is a command-line tool to help you manage your shell aliases efficiently.

## Installation

```bash
# Install globally
npm install -g aliasmate

# Or, install from this directory
npm install -g .
```

## Usage

AliasMate can be used with either `aliasmate` or the shorter `am` command:

```bash
# Add a new alias
aliasmate add

# List all aliases
aliasmate list
# or
am list

# Find specific aliases
aliasmate find

# Remove an alias
aliasmate remove

# Update an existing alias
aliasmate update

# Export aliases to a file
aliasmate export

# Import aliases from a file
aliasmate import

# Apply aliases to your shell configuration
aliasmate apply

# Run a command stored as an alias
aliasmate run [alias-name]
```

## Features

- Add, update, and remove aliases
- Create and run multi-line command aliases
- List all aliases with descriptions and tags
- Find aliases by name, command, or tags
- Export aliases to share across machines
- Import aliases from files
- Apply aliases to your shell configuration
- Run commands directly from saved aliases

## License

MIT
