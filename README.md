# macOS Scripts Workspace

A workspace for developing macOS shell scripts, automation tools, and system administration utilities.

## Project Structure

- `scripts/` - Main scripts for various macOS tasks
- `utils/` - Utility functions and helper scripts
- `examples/` - Example scripts and templates
- `docs/` - Documentation and guides

## Available Scripts

### Auto Scroll Direction Manager
Automatically adjusts macOS "natural scrolling" setting based on connected input devices:
- **Disables** natural scrolling when an external mouse is detected
- **Enables** natural scrolling when only trackpad is present

**Enhanced Detection**: Detects USB mice, Bluetooth mice, wireless receivers, dongles, and generic HID pointing devices.

```bash
# Check current status
./scripts/auto_scroll_direction.sh --check

# Apply recommended settings
./scripts/auto_scroll_direction.sh --apply

# Debug device detection (if mouse not detected)
./scripts/auto_scroll_direction.sh --debug

# Run continuous monitoring
./scripts/auto_scroll_direction.sh --monitor

# Service Management
./scripts/setup_auto_scroll.sh install    # Install as login service
./scripts/setup_auto_scroll.sh status     # Check service status
./scripts/setup_auto_scroll.sh uninstall  # Remove the service
```

## Getting Started

1. Create new scripts in the `scripts/` directory
2. Use the `utils/` directory for reusable functions
3. Refer to `examples/` for common patterns and templates
4. Test all scripts thoroughly before deployment

## macOS Development Guidelines

- Use `#!/usr/bin/env zsh` or `#!/bin/bash` shebangs appropriately
- Test scripts on current macOS version
- Handle system permissions properly
- Use macOS-specific paths (e.g., `/usr/local/bin`, `/opt/homebrew/bin`)
- Consider SIP (System Integrity Protection) restrictions

## Common macOS Commands

- `defaults` - Read/write system preferences
- `launchctl` - Manage launch daemons and agents
- `diskutil` - Disk management utilities
- `security` - Keychain and certificate management
- `system_profiler` - System information
- `osascript` - AppleScript execution

## Best Practices

- Always validate input parameters
- Use proper error handling with `set -e` and `trap`
- Include usage instructions in script headers
- Test with different user permissions
- Consider both Intel and Apple Silicon Macs

## Example Usage

```bash
# Make a script executable
chmod +x scripts/my_script.sh

# Run a script
./scripts/my_script.sh

# Check script syntax
bash -n scripts/my_script.sh
```

## Development Tools

This workspace is optimized for:
- Shell scripting with syntax highlighting
- Script debugging and testing
- macOS system integration
- Automation workflows
