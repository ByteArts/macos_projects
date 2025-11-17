#!/usr/bin/env zsh

# Setup Auto Scroll Direction Service
# Description: Installs the auto scroll direction script as a launch agent
# Usage: ./setup_auto_scroll.sh [install|uninstall|status]

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Ensure we're on macOS
check_macos

PLIST_NAME="com.user.auto-scroll-direction"
PLIST_FILE="${SCRIPT_DIR}/${PLIST_NAME}.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
INSTALLED_PLIST="${LAUNCH_AGENTS_DIR}/${PLIST_NAME}.plist"

# Function to install the launch agent
install_service() {
    log_info "Installing auto scroll direction service..."

    # Ensure LaunchAgents directory exists
    ensure_directory "$LAUNCH_AGENTS_DIR"

    # Copy plist file
    cp "$PLIST_FILE" "$INSTALLED_PLIST"
    log_success "Copied plist to $INSTALLED_PLIST"

    # Load the launch agent
    launchctl load "$INSTALLED_PLIST"
    log_success "Launch agent loaded successfully"

    echo
    log_success "✅ Auto scroll direction service installed!"
    log_info "The script will now run automatically at login and adjust scroll direction based on connected devices."
    log_info "You can also run it manually: ./scripts/auto_scroll_direction.sh"
}

# Function to uninstall the launch agent
uninstall_service() {
    log_info "Uninstalling auto scroll direction service..."

    # Unload the launch agent if it's loaded
    if launchctl list | grep -q "$PLIST_NAME"; then
        launchctl unload "$INSTALLED_PLIST"
        log_success "Launch agent unloaded"
    fi

    # Remove plist file
    if [[ -f "$INSTALLED_PLIST" ]]; then
        rm "$INSTALLED_PLIST"
        log_success "Removed plist file"
    fi

    log_success "✅ Auto scroll direction service uninstalled!"
}

# Function to check service status
check_service_status() {
    echo "🔧 Auto Scroll Direction Service Status"
    echo "======================================="

    if [[ -f "$INSTALLED_PLIST" ]]; then
        echo "📋 Service file: INSTALLED"
        echo "   Location: $INSTALLED_PLIST"
    else
        echo "📋 Service file: NOT INSTALLED"
    fi

    if launchctl list | grep -q "$PLIST_NAME"; then
        echo "🔄 Service status: LOADED"
        echo "   The service will run automatically at login"
    else
        echo "🔄 Service status: NOT LOADED"
    fi

    echo
    echo "📊 Current scroll direction status:"
    "${SCRIPT_DIR}/auto_scroll_direction.sh" --check
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [install|uninstall|status]"
    echo
    echo "Setup Auto Scroll Direction Service"
    echo "Manages the installation of the auto scroll direction launch agent"
    echo
    echo "Commands:"
    echo "  install     Install the service to run at login"
    echo "  uninstall   Remove the service"
    echo "  status      Check current service status"
    echo
    echo "Examples:"
    echo "  $0 install      # Install the auto scroll service"
    echo "  $0 status       # Check service status"
    echo "  $0 uninstall    # Remove the service"
}

# Main script logic
main() {
    case "${1:-}" in
        install)
            if [[ -f "$INSTALLED_PLIST" ]]; then
                log_warning "Service already appears to be installed"
                if confirm "Reinstall the service?"; then
                    uninstall_service
                    install_service
                fi
            else
                install_service
            fi
            ;;
        uninstall)
            if [[ -f "$INSTALLED_PLIST" ]]; then
                uninstall_service
            else
                log_warning "Service does not appear to be installed"
            fi
            ;;
        status)
            check_service_status
            ;;
        "")
            check_service_status
            echo
            if confirm "Install the auto scroll direction service?"; then
                install_service
            fi
            ;;
        *)
            log_error "Unknown command: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
