#!/bin/bash

################################################################################
# Trexzactyl Panel Uninstaller
# 
# Description: Remove Trexzactyl Panel and all components
# Author: Trexzactyl Installer Team
# License: MIT
################################################################################

set -e

################################################################################
# VARIABLES
################################################################################

PANEL_PATH="/var/www/trexzactyl"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

################################################################################
# FUNCTIONS
################################################################################

output() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

print_banner() {
    cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║        TREXZACTYL PANEL UNINSTALLER                        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo ""
}

confirm_uninstall() {
    warning "This will completely remove Trexzactyl Panel!"
    warning "All panel data, databases, and configurations will be deleted."
    echo ""
    read -p "Are you sure you want to continue? Type 'yes' to confirm: " CONFIRM
    
    if [[ "$CONFIRM" != "yes" ]]; then
        output "Uninstallation cancelled."
        exit 0
    fi
    
    echo ""
    read -p "Enter the database name to remove (or press enter to skip): " DB_NAME
    
    if [[ ! -z "$DB_NAME" ]]; then
        read -p "Enter the database user to remove (or press enter to skip): " DB_USER
    fi
}

stop_services() {
    output "Stopping services..."
    
    systemctl stop trexzactyl.service 2>/dev/null || true
    systemctl disable trexzactyl.service 2>/dev/null || true
    
    output "Services stopped"
}

remove_files() {
    output "Removing panel files..."
    
    if [ -d "$PANEL_PATH" ]; then
        rm -rf $PANEL_PATH
        output "Panel files removed"
    else
        warning "Panel directory not found: $PANEL_PATH"
    fi
}

remove_nginx_config() {
    output "Removing Nginx configuration..."
    
    rm -f /etc/nginx/sites-enabled/trexzactyl.conf
    rm -f /etc/nginx/sites-available/trexzactyl.conf
    
    systemctl reload nginx 2>/dev/null || true
    
    output "Nginx configuration removed"
}

remove_systemd_service() {
    output "Removing systemd service..."
    
    rm -f /etc/systemd/system/trexzactyl.service
    systemctl daemon-reload
    
    output "Systemd service removed"
}

remove_database() {
    if [[ ! -z "$DB_NAME" ]]; then
        output "Removing database..."
        
        mysql -u root <<EOF
DROP DATABASE IF EXISTS ${DB_NAME};
EOF
        
        if [[ ! -z "$DB_USER" ]]; then
            mysql -u root <<EOF
DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF
        fi
        
        output "Database removed"
    else
        warning "Skipping database removal"
    fi
}

remove_cron() {
    output "Removing cron jobs..."
    
    crontab -l | grep -v "$PANEL_PATH/artisan schedule:run" | crontab - 2>/dev/null || true
    
    output "Cron jobs removed"
}

remove_ssl() {
    output "Removing SSL certificates..."
    
    read -p "Enter the domain to remove SSL certificates (or press enter to skip): " FQDN
    
    if [[ ! -z "$FQDN" ]]; then
        certbot delete --cert-name $FQDN --non-interactive 2>/dev/null || true
        output "SSL certificates removed"
    else
        warning "Skipping SSL certificate removal"
    fi
}

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        UNINSTALLATION COMPLETED SUCCESSFULLY!              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    warning "The following packages were NOT removed (in case they're used by other applications):"
    echo "  - PHP"
    echo "  - MariaDB/MySQL"
    echo "  - Nginx"
    echo "  - Redis"
    echo "  - Node.js"
    echo "  - Composer"
    echo ""
    output "If you want to remove these packages, run:"
    echo "  apt remove --purge php8.1* mariadb-server nginx redis-server nodejs composer"
    echo ""
}

################################################################################
# MAIN
################################################################################

main() {
    print_banner
    check_root
    confirm_uninstall
    
    output "Starting uninstallation process..."
    
    stop_services
    remove_systemd_service
    remove_cron
    remove_nginx_config
    remove_files
    remove_database
    remove_ssl
    
    print_summary
}

main
