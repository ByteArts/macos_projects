#!/usr/bin/env zsh

# Common utility functions for macOS scripts
# Source this file in other scripts: source utils/common.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as admin
is_admin() {
    dseditgroup -o checkmember -m "$(whoami)" admin >/dev/null 2>&1
}

# Require admin privileges
require_admin() {
    if ! is_admin; then
        log_error "This script requires administrator privileges"
        exit 1
    fi
}

# Get macOS version
get_macos_version() {
    sw_vers -productVersion
}

# Check if Homebrew is installed
has_homebrew() {
    command_exists brew
}

# Install Homebrew if not present
install_homebrew() {
    if ! has_homebrew; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# Backup a file with timestamp
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup_name="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_name"
        log_success "Backed up $file to $backup_name"
    fi
}

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_success "Created directory: $dir"
    fi
}

# Prompt user for confirmation
confirm() {
    local message="$1"
    echo -n "$message (y/N): "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}
