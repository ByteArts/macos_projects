#!/usr/bin/env zsh

# Example macOS System Information Script
# Description: Displays basic system information about the Mac
# Usage: ./system_info.sh

set -e  # Exit on any error

echo "🍎 macOS System Information"
echo "=========================="
echo

# System version
echo "📋 System Version:"
sw_vers
echo

# Hardware information
echo "💻 Hardware Information:"
echo "Model: $(system_profiler SPHardwareDataType | grep 'Model Name' | awk -F': ' '{print $2}')"
echo "Processor: $(system_profiler SPHardwareDataType | grep 'Processor Name' | awk -F': ' '{print $2}')"
echo "Memory: $(system_profiler SPHardwareDataType | grep 'Memory' | awk -F': ' '{print $2}')"
echo

# Disk usage
echo "💾 Disk Usage:"
df -h / | tail -n 1 | awk '{print "Root Volume: " $3 " used of " $2 " (" $5 " full)"}'
echo

# Current user and shell
echo "👤 User Information:"
echo "Current user: $(whoami)"
echo "Shell: $SHELL"
echo "Home directory: $HOME"
echo

# Network information
echo "🌐 Network Information:"
echo "Hostname: $(hostname)"
# Get primary network interface
primary_interface=$(route get default | grep interface | awk '{print $2}')
if [[ -n "$primary_interface" ]]; then
    ip_address=$(ifconfig "$primary_interface" | grep 'inet ' | awk '{print $2}')
    echo "Primary IP: $ip_address"
fi
echo

echo "✅ System information collected successfully!"
