#!/bin/bash

# Define terminal emulator (e.g., Kitty)
terminal_emulator="kitty"

# Define scratchpad title
scratchpad_title="Scratchpad Terminal"

# Define sleep duration
sleep_duration=1.0

# Function to display error notification
display_error_notification() {
    local error_message="$1"
    osascript -e "display notification \"$error_message\" with title \"Error\""
}

# Function to handle errors
handle_error() {
    local error_message="$1"
    echo "Error: $error_message"
    display_error_notification "$error_message"
    exit 1
}

# Check if scratchpad window is already open
scratchpad_info=$(yabai -m query --windows | jq -r --arg title "$scratchpad_title" '.[] | select(.title == $title)') || handle_error "Failed to query scratchpad window info"
scratchpad_id=$(echo "$scratchpad_info" | jq -r '.id') || handle_error "Failed to extract scratchpad window ID"

if [ -n "$scratchpad_id" ]; then
    # If scratchpad window is open
    is_minimized=$(echo "$scratchpad_info" | jq -r '.["is-minimized"]')
    if [ "$is_minimized" = "true" ]; then
        # If scratchpad window is minimized, restore it in the current space
        current_space=$(yabai -m query --spaces --space | jq '.index') || handle_error "Failed to get current space"
        yabai -m window "$scratchpad_id" --space "$current_space" || handle_error "Failed to restore the window"
        yabai -m window --focus "$scratchpad_id" || handle_error "Failed to focus the window"
    elif [ "$is_minimized" = "false" ]; then
        # If scratchpad window is not minimized, minimize it
        yabai -m window "$scratchpad_id" --minimize || handle_error "Failed to minimize the window"
    fi
else
    # Get main display dimensions
    # Open Kitty with title
    kitty --title "$scratchpad_title" "$HOME" || handle_error "Failed to open terminal emulator" &

    sleep "$sleep_duration"

    # Get the window ID of the newly created Kitty window by title
    scratchpad_info=$(yabai -m query --windows | jq -r --arg title "$scratchpad_title" '.[] | select(.title == $title)') || handle_error "Failed to query scratchpad window info"
    scratchpad_id=$(echo "$scratchpad_info" | jq -r '.id') || handle_error "Failed to extract scratchpad window ID"
    is_floating=$(echo "$scratchpad_info" | jq -r '.["is-floating"]') || handle_error "Failed to check if scratchpad window is floating"

    if [ -z "$scratchpad_id" ]; then
        p_id=$(pgrep -f "kitty --title $scratchpad_title")
        sleep "$sleep_duration"
        kill "$p_id" || handle_error "Failed to close the new Kitty window"
        handle_error "Failed to get scratchpad window ID after creating a new window"
    fi

    if [ "$is_floating" = false ]; then
       # If the window is not floating, set to float
       yabai -m window "$scratchpad_id" --toggle float || handle_error "Failed to set window to float"
    fi

    main_display_info=$(yabai -m query --displays | jq -r '.[] | select(.["has-focus"] == true) | .frame') || handle_error "Failed to get main display dimensions"
    main_width=$(echo "$main_display_info" | jq -r '.w' | awk -F '.' '{print $1}') || handle_error "Failed to parse main display width"
    main_height=$(echo "$main_display_info" | jq -r '.h' | awk -F '.' '{print $1}') || handle_error "Failed to parse main display height"

    # Define window dimensions and position
    window_width=$((main_width / 4))
    window_height=$((main_height / 2))
    # Calculate window position to center it
    window_start_x=$(( (main_width - window_width) / 2 ))
    window_start_y=$(( (main_height - window_height) / 2 ))

    echo $scratchpad_id $main_width $main_height $window_start_x $window_start_y

    # Resize the window to the specified dimensions
    yabai -m window "$scratchpad_id" --resize abs:"$window_width":"$window_height" || handle_error "Failed to resize window"

    # Move the window to the specified position
    yabai -m window "$scratchpad_id" --move abs:"$window_start_x":"$window_start_y" || handle_error "Failed to move window"
fi
