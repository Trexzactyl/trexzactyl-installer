#!/bin/bash

################################################################################
# Trexzactyl Unified Installer
# 
# Description: Main installer with modern UI menu
# Author: Trexzactyl Installer Team
# License: MIT
################################################################################

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source UI components
source "$SCRIPT_DIR/ui/styles.sh" 2>/dev/null || {
    # Fallback if UI not available
    SUCCESS='\033[0;32m'
    DANGER='\033[0;31m'
    WARNING='\033[1;33m'
    INFO='\033[0;36m'
    RESET='\033[0m'
}

source "$SCRIPT_DIR/ui/functions.sh" 2>/dev/null || {
    # Fallback functions
    print_header() { echo "=== $1 ==="; }
    print_message() { echo "[$1] $2"; }
    print_menu_option() { echo "  [$1] $2"; }
    print_banner() { echo "TREXZACTYL INSTALLER"; }
    confirm() { read -p "$1 [y/N]: " -r; [[ $REPLY =~ ^[Yy]$ ]]; }
    pause() { read -p "Press any key to continue..." -n1 -s; echo ""; }
}

################################################################################
# VARIABLES
################################################################################

VERSION="1.0.0"
PANEL_INSTALLED=false
WINGS_INSTALLED=false
PHPMYADMIN_INSTALLED=false
DATABASE_HOST_SETUP=false

################################################################################
# UTILITY FUNCTIONS
################################################################################

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message "error" "This script must be run as root"
        exit 1
    fi
}

detect_installations() {
    # Check if panel is installed
    if [ -d "/var/www/trexzactyl" ] && [ -f "/var/www/trexzactyl/artisan" ]; then
        PANEL_INSTALLED=true
    fi
    
    # Check if wings is installed
    if [ -f "/usr/local/bin/wings" ]; then
        WINGS_INSTALLED=true
    fi
    
    # Check if phpMyAdmin is installed
    if [ -d "/var/www/phpmyadmin" ]; then
        PHPMYADMIN_INSTALLED=true
    fi
    
    # Check if database host is configured
    if systemctl list-units --full -all | grep -q mariadb; then
        if mysql -u root -e "SHOW DATABASES;" &>/dev/null 2>&1; then
            DATABASE_HOST_SETUP=true
        fi
    fi
}

show_system_info() {
    clear_screen
    print_header "System Information"
    echo ""
    
    print_message "info" "Operating System: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    print_message "info" "Kernel: $(uname -r)"
    print_message "info" "Architecture: $(uname -m)"
    print_message "info" "CPU Cores: $(nproc)"
    print_message "info" "Total RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    print_message "info" "Available Disk: $(df -h / | awk 'NR==2 {print $4}')"
    
    echo ""
    print_line
    echo ""
    
    print_message "info" "Installation Status:"
    echo ""
    
    if [ "$PANEL_INSTALLED" = true ]; then
        print_status "installed" "Trexzactyl Panel"
    else
        print_status "missing" "Trexzactyl Panel"
    fi
    
    if [ "$WINGS_INSTALLED" = true ]; then
        print_status "installed" "Wings Daemon"
    else
        print_status "missing" "Wings Daemon"
    fi
    
    if [ "$PHPMYADMIN_INSTALLED" = true ]; then
        print_status "installed" "phpMyAdmin"
    else
        print_status "missing" "phpMyAdmin"
    fi
    
    if [ "$DATABASE_HOST_SETUP" = true ]; then
        print_status "installed" "Database Host"
    else
        print_status "missing" "Database Host"
    fi
    
    echo ""
    pause
}

check_services() {
    clear_screen
    print_header "Service Status"
    echo ""
    
    services=("nginx" "mariadb" "redis-server" "php8.1-fpm" "trexzactyl" "wings" "docker")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            print_status "running" "$service"
        elif systemctl list-units --full -all | grep -q "$service.service"; then
            print_status "stopped" "$service"
        else
            print_status "missing" "$service"
        fi
    done
    
    echo ""
    pause
}

################################################################################
# INSTALLATION FUNCTIONS
################################################################################

install_panel() {
    clear_screen
    print_header "Installing Trexzactyl Panel"
    echo ""
    
    if [ "$PANEL_INSTALLED" = true ]; then
        print_message "warning" "Panel is already installed!"
        if confirm "Do you want to reinstall?"; then
            bash "$SCRIPT_DIR/install.sh"
        fi
    else
        bash "$SCRIPT_DIR/install.sh"
    fi
}

install_wings() {
    clear_screen
    print_header "Installing Wings Daemon"
    echo ""
    
    if [ "$WINGS_INSTALLED" = true ]; then
        print_message "warning" "Wings is already installed!"
        if confirm "Do you want to reinstall?"; then
            bash "$SCRIPT_DIR/wings.sh"
        fi
    else
        bash "$SCRIPT_DIR/wings.sh"
    fi
}

install_phpmyadmin() {
    clear_screen
    print_header "Installing phpMyAdmin"
    echo ""
    
    if [ "$PHPMYADMIN_INSTALLED" = true ]; then
        print_message "warning" "phpMyAdmin is already installed!"
        if confirm "Do you want to reinstall?"; then
            bash "$SCRIPT_DIR/phpmyadmin.sh"
        fi
    else
        bash "$SCRIPT_DIR/phpmyadmin.sh"
    fi
}

setup_database_host() {
    clear_screen
    print_header "Setting Up Database Host"
    echo ""
    
    if [ "$DATABASE_HOST_SETUP" = true ]; then
        print_message "warning" "Database host appears to be already configured!"
        if confirm "Do you want to reconfigure?"; then
            bash "$SCRIPT_DIR/database.sh"
        fi
    else
        bash "$SCRIPT_DIR/database.sh"
    fi
}

update_panel() {
    clear_screen
    print_header "Updating Trexzactyl Panel"
    echo ""
    
    if [ "$PANEL_INSTALLED" = false ]; then
        print_message "error" "Panel is not installed!"
        pause
        return
    fi
    
    bash "$SCRIPT_DIR/update.sh"
}

uninstall_panel() {
    clear_screen
    print_header "Uninstalling Trexzactyl Panel"
    echo ""
    
    if [ "$PANEL_INSTALLED" = false ]; then
        print_message "error" "Panel is not installed!"
        pause
        return
    fi
    
    print_message "warning" "This will completely remove the panel!"
    if confirm "Are you absolutely sure?"; then
        bash "$SCRIPT_DIR/uninstall.sh"
    fi
}

run_tests() {
    clear_screen
    print_header "Running Installation Tests"
    echo ""
    
    bash "$SCRIPT_DIR/test.sh"
    pause
}

################################################################################
# MENU FUNCTIONS
################################################################################

show_main_menu() {
    clear_screen
    print_banner
    echo ""
    
    print_menu_option "1" "Install Panel" "Install Trexzactyl Panel with web interface"
    print_menu_option "2" "Install Wings" "Install Wings daemon for game servers"
    print_menu_option "3" "Install phpMyAdmin" "Install database management interface"
    print_menu_option "4" "Setup Database Host" "Configure dedicated database server"
    print_divider
    print_menu_option "5" "Update Panel" "Update panel to latest version"
    print_menu_option "6" "Uninstall Panel" "Remove panel completely"
    print_divider
    print_menu_option "7" "System Information" "View system and installation status"
    print_menu_option "8" "Check Services" "View status of all services"
    print_menu_option "9" "Run Tests" "Verify installation integrity"
    print_divider
    print_menu_option "0" "Exit" "Exit installer"
    
    echo ""
    echo -ne "${INFO}${DOT}${RESET} Select an option: "
    read -r choice
    
    case $choice in
        1) install_panel ;;
        2) install_wings ;;
        3) install_phpmyadmin ;;
        4) setup_database_host ;;
        5) update_panel ;;
        6) uninstall_panel ;;
        7) show_system_info ;;
        8) check_services ;;
        9) run_tests ;;
        0) exit_installer ;;
        *) 
            print_message "error" "Invalid option"
            sleep 1
            ;;
    esac
}

exit_installer() {
    clear_screen
    print_box_top
    print_box_empty
    print_box_line_centered "${SUCCESS}Thank you for using Trexzactyl Installer!${RESET}"
    print_box_empty
    print_box_line_centered "${MUTED}Visit: https://github.com/trexzactyl${RESET}"
    print_box_empty
    print_box_bottom
    echo ""
    exit 0
}

################################################################################
# MAIN
################################################################################

main() {
    check_root
    
    # Main loop
    while true; do
        detect_installations
        show_main_menu
    done
}

# Run main function
main
