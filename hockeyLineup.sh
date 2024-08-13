#!/bin/bash

# Hockey Lineup Ice Time Calculator
# =================================
#
# This script calculates the expected time on ice and number of shifts per player 
# based on the number of skaters available and the shift duration. The script 
# divides skaters into forwards and defensemen, then calculates the time on ice 
# and expected shifts for each position.
#
# Functions:
# ----------
# calculate_time(skaters, shift_duration)
#     Calculates and prints the time on ice and expected shifts for forwards 
#     and defensemen.
#
# Usage:
# ------
# Run the script and provide the number of skaters and shift duration when prompted.

calculate_time() {
    local skaters=$1
    local shift_duration=$2  # Shift duration provided by the user
    local game_duration=60  # Default game duration

    local forwards defense

    case $skaters in
        5)  forwards=3; defense=2 ;;
        6|7)  forwards=$((skaters - 2)); defense=2 ;;
        8|9)  forwards=$((skaters - 3)); defense=3 ;;
        10) forwards=6; defense=4 ;;
        11) forwards=7; defense=4 ;;
        12) forwards=7; defense=5 ;;
        13) forwards=8; defense=5 ;;
        14|15) forwards=9; defense=$((skaters - 9)) ;;
        *)  forwards=$((skaters * 9 / 15)); defense=$((skaters - forwards)) ;;
    esac

    local total_forward_time=$(echo "$game_duration * 60" | bc)  # Convert game duration to seconds
    local time_on_ice=$(echo "scale=2; $total_forward_time / ($forwards * $shift_duration)" | bc)
    local total_defense_time=$(echo "$game_duration * 60" | bc)  # Convert game duration to seconds
    local defense_time_on_ice=$(echo "scale=2; $total_defense_time / ($defense * $shift_duration)" | bc)

    local total_shifts=$(echo "$game_duration * 60 / $shift_duration" | bc)
    local shifts_per_forward=$(echo "$total_shifts / $forwards" | bc)
    local shifts_per_defense=$(echo "$total_shifts / $defense" | bc)

    echo -e "\033[0;32mStrategy\033[0m"
    echo -e "  Number of Forwards: \033[0;32m$forwards\033[0m"
    echo -e "  Time on Ice per Forward: \033[0;32m$time_on_ice minutes\033[0m"
    echo -e "  Expected Shifts per Forward: \033[0;32m$shifts_per_forward shifts\033[0m"
    echo -e "  Number of Defense: \033[0;34m$defense\033[0m"
    echo -e "  Time on Ice per Defenseman: \033[0;34m$defense_time_on_ice minutes\033[0m"
    echo -e "  Expected Shifts per Defenseman: \033[0;34m$shifts_per_defense shifts\033[0m"
}

echo "Hockey Lineup Ice Time Calculator"
read -p "Enter the number of skaters available: " skaters
if [ "$skaters" -lt 5 ]; then
    echo "You need at least 5 skaters to run a game."
    exit 1
fi

read -p "Enter the shift duration (in seconds): " shift_duration

calculate_time $skaters $shift_duration
