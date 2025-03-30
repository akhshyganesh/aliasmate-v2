# Contributing to AliasMate

Thank you for considering contributing to AliasMate! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct. Please be respectful and considerate of others when contributing.

## How Can I Contribute?

### Reporting Bugs

If you find a bug in AliasMate, please report it by creating an issue on GitHub. Include as much detail as possible:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Environment details (OS, bash/zsh version, etc.)
- Logs (you can find them at `/tmp/aliasmate.log`)

### Suggesting Enhancements

We welcome feature requests and enhancement suggestions. Please create an issue on GitHub with:

- A clear and descriptive title
- A detailed description of the proposed feature
- Any relevant examples of how the feature would work
- Why this feature would be useful to AliasMate users

### Pull Requests

We actively welcome pull requests:

1. Fork the repository
2. Create a new branch for your feature or bugfix: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Run the tests to ensure everything works
5. Commit your changes with clear messages
6. Push to your fork
7. Submit a pull request

## Development Setup

To set up your local development environment:

1. Clone your fork of the repository: `git clone https://github.com/YOUR_USERNAME/aliasmate-v2.git`
2. Change to the project directory: `cd aliasmate-v2`
3. Install development dependencies:
   ```bash
   sudo apt-get install shellcheck
   ```
   or on macOS:
   ```bash
   brew install shellcheck
   ```

## Development Guidelines

### Code Style

- Follow the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use 4 spaces for indentation
- Keep line length under 100 characters where possible
- Use descriptive variable and function names
- Add comments for complex logic
- **Make all shell scripts executable** with `chmod +x filename.sh`
- Start all shell scripts with `#!/usr/bin/env bash`

### Testing

- Write tests for new functionality
- Ensure all tests pass before submitting a pull request
- Run shellcheck to verify your code

```bash
shellcheck src/*.sh
```

### Documentation

- Update the documentation when adding or modifying features
- Document functions with clear descriptions of parameters and return values
- Keep the README and other documentation up to date

## Project Structure

Here's an overview of the project's structure:

