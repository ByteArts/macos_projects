#!/usr/bin/env zsh

# Auto Scroll Direction Manager
# Description: Automatically adjusts natural scrolling based on connected input devices
#              - Turns OFF natural scrolling when a mouse is detected
#              - Turns ON natural scrolling when only trackpad is present
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
    # Check USB devices for mice or generic receivers that could be mice
    local usb_mice
    usb_mice=$(system_profiler SPUSBDataType 2>/dev/null | grep -iE "(mouse|receiver|dongle|wireless)" | wc -l)

    # Check Bluetooth devices for mice
    local bt_mice
    bt_mice=$(system_profiler SPBluetoothDataType 2>/dev/null | grep -E "(Mouse|Trackball)" | grep -v "Not Connected" | wc -l)

    # Check for HID devices with mouse-like properties (checking for pointing devices)
    local hid_mice
    hid_mice=$(ioreg -c IOHIDDevice 2>/dev/null | grep -E "(Pointing|Mouse|Receiver)" | wc -l)

    # Check for USB HID interfaces that could be mice (excluding built-in devices)
    local usb_hid_mice
    usb_hid_mice=$(ioreg -p IOUSB 2>/dev/null | grep -A 20 "AppleUserUSBHostHIDDevice" | grep -E "(Product|Manufacturer)" | grep -iE "(mouse|receiver|logitech|razer|corsair|steelseries)" | wc -l)

    # Check for non-trackpad/touchpad HID event services
    local external_pointing
    external_pointing=$(ioreg 2>/dev/null | grep -A 5 -B 5 "AppleUserHIDEventDriver" | grep -v -iE "(trackpad|touchpad|keyboard)" | grep -E "AppleUserHIDEventDriver" | wc -l)

    # Count USB HID devices that aren't built-in
    local usb_hid_count
    usb_hid_count=$(ioreg 2>/dev/null | grep -c "AppleUserUSBHostHIDDevice")

    # If any method detects potential mice/receivers or we have USB HID devices, return true
    if [[ $usb_mice -gt 0 ]] || [[ $bt_mice -gt 0 ]] || [[ $hid_mice -gt 0 ]] || [[ $usb_hid_mice -gt 0 ]] || [[ $external_pointing -gt 0 ]] || [[ $usb_hid_count -gt 0 ]]; then
        return 0  # Mouse detected
    else
        return 1  # No mouse detected
    fi
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
        log_success "Natural scrolling enabled (trackpad-style)"
    else
        defaults write -g com.apple.swipescrolldirection -bool false
        log_success "Natural scrolling disabled (traditional mouse-style)"
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
        log_info "Recommended setting: Natural scrolling OFF"
    else
        echo "🖱️  External mouse: NOT DETECTED"
        log_info "Recommended setting: Natural scrolling ON"
    fi

    echo
    echo "⚙️  Current Settings"
    echo "==================="

    if [[ "$current_setting" == "1" ]]; then
        echo "📱 Natural scrolling: ENABLED (trackpad-style)"
    else
        echo "🖱️  Natural scrolling: DISABLED (traditional mouse-style)"
    fi
}

# Function to show debug information about device detection
debug_detection() {
    echo "🔍 Debug: Device Detection Details"
    echo "=================================="

    # Check USB devices for mice or generic receivers
    local usb_mice
    usb_mice=$(system_profiler SPUSBDataType 2>/dev/null | grep -iE "(mouse|receiver|dongle|wireless)" | wc -l)
    echo "USB mice/receivers found: $usb_mice"

    # Check Bluetooth devices
    local bt_mice
    bt_mice=$(system_profiler SPBluetoothDataType 2>/dev/null | grep -E "(Mouse|Trackball)" | grep -v "Not Connected" | wc -l)
    echo "Bluetooth mice found: $bt_mice"

    # Check HID devices
    local hid_mice
    hid_mice=$(ioreg -c IOHIDDevice 2>/dev/null | grep -E "(Pointing|Mouse|Receiver)" | wc -l)
    echo "HID mice/pointing devices found: $hid_mice"

    # Check USB HID interfaces
    local usb_hid_mice
    usb_hid_mice=$(ioreg -p IOUSB 2>/dev/null | grep -A 20 "AppleUserUSBHostHIDDevice" | grep -E "(Product|Manufacturer)" | grep -iE "(mouse|receiver|logitech|razer|corsair|steelseries)" | wc -l)
    echo "USB HID mice found: $usb_hid_mice"

    # Check external pointing devices
    local external_pointing
    external_pointing=$(ioreg 2>/dev/null | grep -A 5 -B 5 "AppleUserHIDEventDriver" | grep -v -iE "(trackpad|touchpad|keyboard)" | grep -E "AppleUserHIDEventDriver" | wc -l)
    echo "External pointing devices found: $external_pointing"

    # Count USB HID devices
    local usb_hid_count
    usb_hid_count=$(ioreg 2>/dev/null | grep -c "AppleUserUSBHostHIDDevice")
    echo "Total USB HID devices: $usb_hid_count"

    echo
    echo "📋 Detected USB Input Devices:"
    system_profiler SPUSBDataType 2>/dev/null | grep -iE "(receiver|dongle|mouse|keyboard)" | sed 's/^/  /'

    echo
    echo "📋 USB HID Device Details:"
    ioreg 2>/dev/null | grep -A 2 -B 2 "AppleUserUSBHostHIDDevice" | grep -E "(Product|Manufacturer|class)" | head -10 | sed 's/^/  /'
}

# Function to apply appropriate settings
apply_settings() {
    local current_setting
    current_setting=$(get_natural_scrolling)

    if has_external_mouse; then
        log_info "External mouse detected"
        if [[ "$current_setting" == "1" ]]; then
            log_info "Disabling natural scrolling for mouse use..."
            set_natural_scrolling false
            log_success "✅ Natural scrolling disabled"
        else
            log_info "Natural scrolling already disabled"
        fi
    else
        log_info "Only trackpad detected"
        if [[ "$current_setting" != "1" ]]; then
            log_info "Enabling natural scrolling for trackpad use..."
            set_natural_scrolling true
            log_success "✅ Natural scrolling enabled"
        else
            log_info "Natural scrolling already enabled"
        fi
    fi
}

# Function to monitor and auto-adjust (runs in background)
monitor_devices() {
    log_info "Starting device monitor mode..."
    log_info "Press Ctrl+C to stop monitoring"

    local last_mouse_state=""

    while true; do
        local current_mouse_state
        if has_external_mouse; then
            current_mouse_state="mouse_present"
        else
            current_mouse_state="mouse_absent"
        fi

        # Only apply changes when state changes
        if [[ "$current_mouse_state" != "$last_mouse_state" ]]; then
            echo
            log_info "Input device state changed: $current_mouse_state"
            apply_settings
            last_mouse_state="$current_mouse_state"
        fi

        sleep 5  # Check every 5 seconds
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo
    echo "Auto Scroll Direction Manager"
    echo "Automatically adjusts macOS natural scrolling based on connected devices"
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
            if confirm "Apply recommended scroll direction setting?"; then
                apply_settings
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
