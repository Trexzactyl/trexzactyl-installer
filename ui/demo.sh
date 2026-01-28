#!/bin/bash

# Demo script to showcase the UI

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/styles.sh"
source "$SCRIPT_DIR/functions.sh"

# Demo 1: Banner
clear_screen
print_banner
sleep 2

# Demo 2: Header
print_header "Welcome to Trexzactyl Installer"
sleep 1

# Demo 3: Messages
print_message "success" "Installation completed successfully!"
print_message "error" "Failed to connect to database"
print_message "warning" "This action cannot be undone"
print_message "info" "Checking system requirements..."
sleep 2

# Demo 4: Loading
echo ""
print_loading "Installing dependencies" 3
print_loading "Configuring services" 2
print_loading "Starting application" 2
sleep 1

# Demo 5: Progress bar
echo ""
echo "Downloading files..."
for i in {1..100}; do
    print_progress $i 100
    sleep 0.02
done
sleep 1

# Demo 6: Status
clear_screen
print_header "Service Status"
echo ""
print_status "running" "Nginx Web Server"
print_status "running" "MariaDB Database"
print_status "stopped" "Redis Cache"
print_status "installed" "PHP 8.1"
print_status "missing" "Wings Daemon"
sleep 2

# Demo 7: Menu
clear_screen
print_box_top
print_box_empty
print_box_line_centered "${HEADER_COLOR}${BOLD}MAIN MENU${RESET}"
print_box_empty
print_box_bottom
echo ""
print_menu_option "1" "Install Panel" "Full panel installation"
print_menu_option "2" "Install Wings" "Daemon installation"
print_menu_option "3" "Configure SSL" "Let's Encrypt setup"
print_menu_option "0" "Exit" "Exit installer"
sleep 2

# Demo 8: Confirmation
echo ""
if confirm "Do you want to continue?"; then
    print_message "success" "User confirmed!"
else
    print_message "info" "User cancelled"
fi

sleep 1
clear_screen
echo "Demo complete!"
