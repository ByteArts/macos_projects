#!/usr/bin/env zsh

# Auto Scroll Direction Manager
# Description: Automatically adjusts natural scrolling based on trackpad status
#              - Turns ON natural scrolling only when built-in trackpad is enabled
#              - Turns OFF natural scrolling by default (when mouse connected or trackpad disabled)
# Usage: ./auto_scroll_direction.sh [--check|--apply|--monitor]
# Author: macOS Scripts Workspace

set -e  # Exit on any error

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../utils/common.sh"

# Ensure we're on macOS
check_macos

# Function to check if external mouse is connected
has_external_mouse() {
    # Check for connected Bluetooth mice by parsing only the "Connected:" section
    # of SPBluetoothDataType, avoiding false positives from paired-but-not-connected devices
    local bt_mouse
    bt_mouse=$(system_profiler SPBluetoothDataType 2>/dev/null | \
        awk '/^      Connected:/{found=1} /^      Not Connected:/{found=0} found && /Minor Type: Mouse/' | \
        wc -l)

    # Check for USB mice
    local usb_mouse
    usb_mouse=$(system_profiler SPUSBDataType 2>/dev/null | grep -i "mouse" | wc -l)

    if [[ $bt_mouse -gt 0 ]] || [[ $usb_mouse -gt 0 ]]; then
        return 0  # External mouse detected
    else
        return 1  # No external mouse
    fi
}

# Function to check if trackpad is being ignored due to mouse presence
is_trackpad_suppressed() {
    # Check the USBMouseStopsTrackpad setting
    local mouse_stops_trackpad
    mouse_stops_trackpad=$(ioreg -c IOHIDSystem -r 2>/dev/null | grep "USBMouseStopsTrackpad" | sed 's/.*USBMouseStopsTrackpad[^0-9]*\([0-9]\).*/\1/')

    # If USBMouseStopsTrackpad=1 and external mouse is present, trackpad is suppressed
    if [[ "$mouse_stops_trackpad" == "1" ]] && has_external_mouse; then
        return 0  # Trackpad is suppressed
    else
        return 1  # Trackpad is not suppressed
    fi
}

# Function to check if built-in trackpad is enabled
is_trackpad_enabled() {
    # Check if built-in trackpad exists
    local trackpad_exists
    trackpad_exists=$(ioreg -c AppleMultitouchDevice 2>/dev/null | grep -E "\"MT Built-In\" = Yes" | wc -l)

    # Also check for the Apple Internal Keyboard/Trackpad device
    local internal_trackpad
    internal_trackpad=$(ioreg -c AppleMultitouchDevice 2>/dev/null | grep -i "Apple Internal.*Trackpad" | wc -l)

    # If trackpad doesn't exist, it's not enabled
    if [[ $trackpad_exists -eq 0 ]] && [[ $internal_trackpad -eq 0 ]]; then
        return 1  # No trackpad found
    fi

    # If trackpad exists but is being suppressed by external mouse, it's not enabled
    if is_trackpad_suppressed; then
        return 1  # Trackpad is suppressed
    fi

    return 0  # Trackpad is enabled and active
}

# Function to get current natural scrolling setting
get_natural_scrolling() {
    defaults read -g com.apple.swipescrolldirection 2>/dev/null || echo "1"
}

# Function to set natural scrolling
set_natural_scrolling() {
    local enable="$1"
    if [[ "$enable" == "true" ]]; then
        defaults write -g com.apple.swipescrolldirection -bool true
        log_success "Natural scrolling ON (trackpad-style)"
    else
        defaults write -g com.apple.swipescrolldirection -bool false
        log_success "Natural scrolling OFF (traditional mouse-style)"
    fi
}

# Function to check current status
check_status() {
    local current_setting
    current_setting=$(get_natural_scrolling)

    echo "🖱️  Input Device Status"
    echo "======================"

    if has_external_mouse; then
        echo "🖱️  External mouse: DETECTED"
    else
        echo "🖱️  External mouse: NOT DETECTED"
    fi

    if is_trackpad_enabled; then
        echo "📱 Built-in trackpad: ENABLED (active)"
        log_info "Recommended setting: Natural scrolling ON"
    else
        echo "📱 Built-in trackpad: DISABLED (suppressed or not present)"
        log_info "Recommended setting: Natural scrolling OFF"
    fi

    echo
    echo "⚙️  Current Settings"
    echo "==================="

    if [[ "$current_setting" == "1" ]]; then
        echo "📱 Natural scrolling: ON (trackpad-style)"
    else
        echo "🖱️  Natural scrolling: OFF (traditional mouse-style)"
    fi
}

# Function to show debug information about device detection
debug_detection() {
    echo "🔍 Debug: Trackpad Detection Details"
    echo "===================================="

    # Check for built-in trackpad
    local trackpad_exists
    trackpad_exists=$(ioreg -c AppleMultitouchDevice 2>/dev/null | grep -E "\"MT Built-In\" = Yes" | wc -l)
    echo "MT Built-In trackpad devices found: $trackpad_exists"

    # Check for Apple Internal Keyboard/Trackpad
    local internal_trackpad
    internal_trackpad=$(ioreg -c AppleMultitouchDevice 2>/dev/null | grep -i "Apple Internal.*Trackpad" | wc -l)
    echo "Apple Internal Trackpad devices found: $internal_trackpad"

    echo
    echo "🖱️  External Mouse Detection"
    echo "============================"

    # Check for connected Bluetooth mice (Connected: section of SPBluetoothDataType only)
    local bt_mouse
    bt_mouse=$(system_profiler SPBluetoothDataType 2>/dev/null | \
        awk '/^      Connected:/{found=1} /^      Not Connected:/{found=0} found && /Minor Type: Mouse/' | \
        wc -l)
    echo "Bluetooth mice found: $bt_mouse"

    # Check for USB mice
    local usb_mouse
    usb_mouse=$(system_profiler SPUSBDataType 2>/dev/null | grep -i "mouse" | wc -l)
    echo "USB mice found: $usb_mouse"

    if has_external_mouse; then
        echo "✅ External mouse: DETECTED"
    else
        echo "❌ External mouse: NOT DETECTED"
    fi

    echo
    echo "⚙️  Trackpad Suppression Settings"
    echo "================================="

    # Check USBMouseStopsTrackpad setting
    local mouse_stops_trackpad
    mouse_stops_trackpad=$(ioreg -c IOHIDSystem -r 2>/dev/null | grep "USBMouseStopsTrackpad" | sed 's/.*USBMouseStopsTrackpad[^0-9]*\([0-9]\).*/\1/')
    echo "USBMouseStopsTrackpad setting: ${mouse_stops_trackpad:-not found}"

    if is_trackpad_suppressed; then
        echo "🚫 Trackpad is SUPPRESSED (ignored by system)"
    else
        echo "✅ Trackpad is NOT suppressed"
    fi

    echo
    echo "📊 Final Trackpad Status"
    echo "========================"
    if is_trackpad_enabled; then
        echo "✅ Trackpad status: ENABLED (active and responding)"
    else
        echo "❌ Trackpad status: DISABLED (not active)"
    fi

    echo
    echo "📋 Multitouch Devices:"
    ioreg -c AppleMultitouchDevice -r 2>/dev/null | grep -E "(\"Product\"|MT Built-In)" | sed 's/^/  /'
}

# Function to apply appropriate settings
apply_settings() {
    local current_setting
    current_setting=$(get_natural_scrolling)

    # Only enable natural scrolling if built-in trackpad is enabled
    # Default to disabled in all other cases
    if is_trackpad_enabled; then
        log_info "Built-in trackpad is enabled"
        if [[ "$current_setting" != "1" ]]; then
            log_info "Turning natural scrolling ON for trackpad use..."
            set_natural_scrolling true
            log_success "✅ Natural scrolling ON"
        else
            log_info "Natural scrolling already ON"
        fi
    else
        log_info "Built-in trackpad is disabled (mouse connected or trackpad off)"
        if [[ "$current_setting" == "1" ]]; then
            log_info "Turning natural scrolling OFF..."
            set_natural_scrolling false
            log_success "✅ Natural scrolling turned OFF"
        else
            log_info "Natural scrolling already OFF"
        fi
    fi
}

# Function to monitor and auto-adjust (runs in background)
monitor_devices() {
    log_info "Starting device monitor mode..."
    log_info "Press Ctrl+C to stop monitoring"

    local last_trackpad_state=""

    while true; do
        local current_trackpad_state
        if is_trackpad_enabled; then
            current_trackpad_state="trackpad_enabled"
        else
            current_trackpad_state="trackpad_disabled"
        fi

        # Only apply changes when state changes
        if [[ "$current_trackpad_state" != "$last_trackpad_state" ]]; then
            echo
            log_info "Trackpad state changed: $current_trackpad_state"
            apply_settings
            last_trackpad_state="$current_trackpad_state"
        fi

        sleep 5  # Check every 5 seconds
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo
    echo "Auto Scroll Direction Manager"
    echo "Automatically adjusts macOS natural scrolling based on trackpad status"
    echo
    echo "Behavior:"
    echo "  - Turns natural scrolling ON when built-in trackpad is active"
    echo "  - Turns natural scrolling OFF by default (when mouse connected or trackpad disabled)"
    echo
    echo "Options:"
    echo "  --check     Check current device status and settings"
    echo "  --apply     Apply appropriate scroll direction setting"
    echo "  --monitor   Monitor devices and auto-adjust (runs continuously)"
    echo "  --debug     Show detailed device detection information"
    echo "  --help      Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --check      # Check current status"
    echo "  $0 --apply      # Apply settings once"
    echo "  $0 --monitor    # Run continuous monitoring"
    echo "  $0 --debug      # Debug device detection"
    echo
    echo "Note: Changes take effect immediately but may require app restart for some applications."
}

# Main script logic
main() {
    case "${1:-}" in
        --check)
            check_status
            ;;
        --apply)
            apply_settings
            ;;
        --monitor)
            # Set up trap to handle Ctrl+C gracefully
            trap 'log_info "Monitoring stopped"; exit 0' INT
            monitor_devices
            ;;
        --debug)
            debug_detection
            ;;
        --help|-h)
            show_usage
            ;;
        "")
            # Default behavior: check and apply
            check_status
            echo

            # Check if recommended setting is already applied
            local current_setting
            current_setting=$(get_natural_scrolling)
            local settings_match=false

            if is_trackpad_enabled; then
                # Trackpad enabled: recommended setting is ON (1)
                if [[ "$current_setting" == "1" ]]; then
                    settings_match=true
                fi
            else
                # Trackpad disabled: recommended setting is OFF (not 1)
                if [[ "$current_setting" != "1" ]]; then
                    settings_match=true
                fi
            fi

            if [[ "$settings_match" == "true" ]]; then
                log_success "✅ Recommended setting is already applied"
            else
                if confirm "Apply recommended scroll direction setting?"; then
                    apply_settings
                fi
            fi
            ;;
        *)
            log_error "Unknown option: $1"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
