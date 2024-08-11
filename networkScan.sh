#!/bin/bash

# ===================================================
# Network Device Scanner
# ===================================================
# Author: noytou
# Date: 2024-06-11
# Version: 1.4
#
# Description:
# ------------
# This Bash script scans the internal network to identify connected devices,
# including their IP addresses, MAC addresses, and hostnames (if available).
# The script compares the current scan results with the previous scan to
# identify new or removed devices. The results are stored in a specified
# directory for future analysis.
#
# Usage:
# ------
# - Customize the IP range according to your network configuration.
# - Run the script with appropriate permissions.
# - View the scan results in the /home/scans directory.
#
# IP Range:
# ---------
# - The IP range should be set according to your network.
#   Example for 192.168.0.1 router: "192.168.0.1/24"
#
# Dependencies:
# -------------
# - Ensure you have the following packages installed:
#   1. arp-scan: Used for network scanning.
#      Install with: sudo apt-get install arp-scan
#   2. jq: Used for processing JSON data.
#      Install with: sudo apt-get install jq
#
# Output:
# -------
# - The results are saved to /home/scans/previous_scan.json.
#
# ===================================================

# Directory and file to store previous scan results
SCAN_DIRECTORY="/home/scans"
PREVIOUS_SCAN_FILE="$SCAN_DIRECTORY/previous_scan.json"

# Ensure the scan directory exists
mkdir -p "$SCAN_DIRECTORY"

# Function to scan the network
scan_network() {
    local ip_range="$1"
    # Replace 'wlan0' with your actual network interface name
    sudo arp-scan --interface=wlp4s0  --localnet | grep -E "^[0-9]" | awk '{print $1, $2}' | sort | uniq | while read ip mac; do
        # Try to resolve the hostname using getent
        hostname=$(getent hosts "$ip" | awk '{print $2}')
        if [ -z "$hostname" ]; then
            # Fallback to nslookup if getent fails
            hostname=$(nslookup "$ip" 2>/dev/null | awk -F'= ' 'NR==5 {print $2}')
            if [ -z "$hostname" ]; then
                hostname="Unknown"
            fi
        fi
        # Output each line as a JSON object
        echo "{\"ip\":\"$ip\",\"mac\":\"$mac\",\"hostname\":\"$hostname\"}"
    done
}

# Load previous scan results
load_previous_scan() {
    if [ -f "$PREVIOUS_SCAN_FILE" ]; then
        cat "$PREVIOUS_SCAN_FILE"
    else
        echo "[]"
    fi
}

# Save current scan results
save_current_scan() {
    local current_scan="$1"
    echo "$current_scan" > "$PREVIOUS_SCAN_FILE"
}

# Compare scans and find new/removed devices
compare_scans() {
    local previous_scan="$1"
    local current_scan="$2"

    new_devices=$(echo "$current_scan" | jq -c '.[]' | while read current_device; do
        ip=$(echo "$current_device" | jq -r '.ip')
        if ! echo "$previous_scan" | jq -c '.[]' | jq -r '.ip' | grep -q "$ip"; then
            echo "$current_device"
        fi
    done)

    removed_devices=$(echo "$previous_scan" | jq -c '.[]' | while read previous_device; do
        ip=$(echo "$previous_device" | jq -r '.ip')
        if ! echo "$current_scan" | jq -c '.[]' | jq -r '.ip' | grep -q "$ip"; then
            echo "$previous_device"
        fi
    done)

    echo "New Devices: $new_devices"
    echo "Removed Devices: $removed_devices"
}

# Display devices
display_devices() {
    local devices="$1"
    local label="$2"
    echo -e "\n$label:"
    echo "$devices" | jq -c '.[]' | while read device; do
        ip=$(echo "$device" | jq -r '.ip')
        mac=$(echo "$device" | jq -r '.mac')
        hostname=$(echo "$device" | jq -r '.hostname')
        echo "IP: $ip, MAC: $mac, Hostname: $hostname"
    done
}

# Main script execution
IP_RANGE="192.168.0.0/24"

echo "Scanning network..."
current_scan=$(scan_network "$IP_RANGE")

# Debugging output: Print the scan results before processing with jq
echo "Raw scan output:"
echo "$current_scan"

# Process scan results as JSON
current_scan=$(echo "$current_scan" | jq -s '.')

previous_scan=$(load_previous_scan)

compare_scans "$previous_scan" "$current_scan" | tee "$SCAN_DIRECTORY/scan_comparison.txt"

display_devices "$current_scan" "Current Devices"
display_devices "$(compare_scans "$previous_scan" "$current_scan" | jq '.new_devices')" "New Devices"
display_devices "$(compare_scans "$previous_scan" "$current_scan" | jq '.removed_devices')" "Removed Devices"

save_current_scan "$current_scan"

echo -e "\nScan completed and saved to $PREVIOUS_SCAN_FILE."
