# AliasMate Test Plan

This document outlines the test cases for AliasMate to ensure all functionality works as expected.

## Installation Testing

- [ ] Install the package globally: `npm install -g .`
- [ ] Verify `aliasmate` command is available
- [ ] Verify `am` command is available

## Basic Command Testing

### Help and Version

- [ ] Test `aliasmate --help` displays help information
- [ ] Test `aliasmate --version` displays version information

### Add Command

- [ ] Test adding a new alias with all fields
- [ ] Test adding a new alias with only required fields
- [ ] Test adding a multi-line command alias
- [ ] Test validation (prevent empty name/command)
- [ ] Test duplicate name validation

### List Command

- [ ] Test listing aliases when none exist
- [ ] Test listing multiple aliases
- [ ] Test listing multi-line command aliases
- [ ] Verify all alias properties are displayed correctly

### Find Command

- [ ] Test finding by alias name
- [ ] Test finding by command content
- [ ] Test finding by tag
- [ ] Test finding by description
- [ ] Test case insensitivity
- [ ] Test handling no matches

### Remove Command

- [ ] Test removing an existing alias
- [ ] Test cancellation of removal
- [ ] Test behavior when no aliases exist

### Update Command

- [ ] Test updating command of an existing alias
- [ ] Test updating a single-line command to multi-line
- [ ] Test updating a multi-line command
- [ ] Test updating description of an existing alias
- [ ] Test updating tags of an existing alias
- [ ] Test behavior when no aliases exist

### Export Command

- [ ] Test exporting to default location
- [ ] Test exporting to custom location
- [ ] Verify exported file structure

### Import Command

- [ ] Test importing with 'merge' option
- [ ] Test importing with 'overwrite' option
- [ ] Test importing with 'append' option
- [ ] Test importing from invalid file
- [ ] Test importing invalid JSON structure

### Apply Command

- [ ] Test applying to Bash config
- [ ] Test applying to Zsh config
- [ ] Test applying to Fish config
- [ ] Test applying to custom file
- [ ] Test updating existing aliases section

### Run Command

- [ ] Test running a simple command alias
- [ ] Test running a multi-line command alias
- [ ] Test running a non-existent alias
- [ ] Verify current directory is preserved when running commands
- [ ] Test updating command after running
- [ ] Test cancellation of command execution

## Regression Testing

For each new feature, perform regression tests to ensure it doesn't break existing functionality:

1. Add several aliases (including multi-line)
2. List the aliases to confirm they were added correctly
3. Find aliases using different search terms
4. Update some aliases
5. Export aliases to a file
6. Remove some aliases
7. Import the previously exported aliases
8. Apply aliases to a shell configuration file
9. Run aliases with the run command

## Update Testing

After each update to the codebase:

1. Ensure all commands still work
2. Check that data persistence works correctly
3. Verify installation and commands work on fresh systems

## Non-Functional Testing

- [ ] Performance: Test with a large number of aliases (100+)
- [ ] Usability: Ensure error messages are clear and helpful
- [ ] Compatibility: Test on different Node.js versions and operating systems
