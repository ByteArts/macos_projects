#!/usr/bin/env zsh

# Hello World Script for macOS
# A simple example script to get started

# Source common utilities
source "$(dirname "$0")/../utils/common.sh"

# Check if we're on macOS
check_macos

echo "🚀 Welcome to your macOS scripting workspace!"
echo

log_info "This is a sample script to demonstrate basic functionality"
log_success "✅ Script executed successfully!"
log_warning "⚠️  Remember to make scripts executable with: chmod +x script_name.sh"

echo
echo "📝 Next steps:"
echo "  1. Create your own scripts in the scripts/ directory"
echo "  2. Use utilities from utils/common.sh in your scripts"
echo "  3. Check out examples/ for more script templates"
echo "  4. Read the README.md for development guidelines"

echo
echo "🍎 Happy scripting on macOS!"
