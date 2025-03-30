# AliasMate Keyboard Shortcuts

This document provides a comprehensive list of keyboard shortcuts available in AliasMate's TUI (Terminal User Interface) mode.

## Global Shortcuts

These shortcuts work throughout the TUI:

| Shortcut | Description |
|----------|-------------|
| **Tab** | Move between fields |
| **Shift+Tab** | Move between fields (reverse) |
| **Enter** | Confirm/Select current item |
| **Esc** | Cancel current operation/Go back |
| **Ctrl+C** | Exit AliasMate |
| **h** | Display help for current screen |
| **q** | Quit current screen/Go back |
| **?** | Show keyboard shortcuts |

## Main Menu Navigation

| Shortcut | Description |
|----------|-------------|
| **Up/Down** | Navigate menu items |
| **1-9** | Quick select menu items by number |
| **/** | Quick search in menu |
| **r** | Refresh display |

## Command List View

| Shortcut | Description |
|----------|-------------|
| **Up/Down** | Navigate command list |
| **PgUp/PgDown** | Page up/down through long lists |
| **Home/End** | Jump to beginning/end of list |
| **Enter** | Select command for actions |
| **s** | Create new command |
| **e** | Edit selected command |
| **d** | Delete selected command |
| **r** | Run selected command |
| **c** | Copy selected command to clipboard |
| **/** | Search within displayed commands |
| **f** | Filter commands |
| **Space** | View command details |

## Command Edit View

| Shortcut | Description |
|----------|-------------|
| **Tab** | Move between form fields |
| **Ctrl+W** | Clear current field |
| **Ctrl+U** | Clear from cursor to beginning of line |
| **Ctrl+K** | Clear from cursor to end of line |
| **Ctrl+A** | Move to beginning of line |
| **Ctrl+E** | Move to end of line |
| **Esc** | Cancel editing |
| **Ctrl+S** | Save command (in editor mode) |

## Search Interface

| Shortcut | Description |
|----------|-------------|
| **Enter** | Execute search |
| **Tab** | Toggle between search fields |
| **Up/Down** | Navigate search history |
| **Ctrl+C** | Cancel search |
| **Esc** | Clear search/Cancel |

## Category Management

| Shortcut | Description |
|----------|-------------|
| **Up/Down** | Navigate categories |
| **Enter** | Select category |
| **a** | Add new category |
| **d** | Delete selected category |
| **r** | Rename selected category |
| **Esc** | Exit category management |

## Export/Import Screen

| Shortcut | Description |
|----------|-------------|
| **Tab** | Switch between form fields |
| **Enter** | Confirm action |
| **1-3** | Quick select options |
| **Esc** | Cancel operation |

## Statistics View

| Shortcut | Description |
|----------|-------------|
| **Space** | Page down through statistics |
| **b** | Page up through statistics |
| **r** | Reset statistics (with confirmation) |
| **e** | Export statistics |
| **q** | Exit statistics view |

## Configuration Screen

| Shortcut | Description |
|----------|-------------|
| **Up/Down** | Navigate configuration options |
| **Enter** | Select option to modify |
| **r** | Reset configuration (with confirmation) |
| **q** | Exit configuration screen |

## Synchronization Interface

| Shortcut | Description |
|----------|-------------|
| **1-4** | Quick select sync options |
| **p** | Push commands to remote |
| **f** | Pull commands from remote |
| **s** | Show sync status |
| **c** | Configure sync |
| **q** | Exit sync interface |

## Dialog Controls

These shortcuts work in dialogs:

| Shortcut | Description |
|----------|-------------|
| **Tab** | Move between buttons |
| **Space** | Toggle checkboxes |
| **Y/y** | Confirm (Yes) in Yes/No dialogs |
| **N/n** | Decline (No) in Yes/No dialogs |
| **Enter** | Activate selected button |
| **Esc** | Cancel dialog |

## Multi-line Editor Mode

When editing multi-line commands:

| Shortcut | Description |
|----------|-------------|
| **Ctrl+X** | Save and exit (nano) |
| **Ctrl+O, Enter** | Save (nano) |
| **Ctrl+C** | Cancel (nano) |
| **:wq** | Save and exit (vim) |
| **:q!** | Exit without saving (vim) |

## Tips for Different Terminals

- **iTerm2 (macOS)**: All shortcuts should work as expected
- **Terminal.app (macOS)**: PgUp/PgDown might require Fn key
- **GNOME Terminal (Linux)**: All shortcuts should work as expected
- **Konsole (KDE)**: All shortcuts should work as expected
- **Windows Terminal (WSL)**: May need to adjust terminal settings for certain key combinations

## Customizing Shortcuts

Currently, keyboard shortcuts in AliasMate are not customizable. Future versions may include this feature.

## Troubleshooting Keyboard Issues

If some shortcuts don't work:

1. Check if your terminal is capturing those keys
2. Verify your terminal type is correctly detected
3. Try setting `TERM` environment variable: `export TERM=xterm-256color`
4. For remote sessions, ensure SSH is configured to forward key combinations
