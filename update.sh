#!/bin/bash

################################################################################
# Trexzactyl Panel Updater
# 
# Description: Update Trexzactyl Panel to the latest version
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
BLUE='\033[0;34m'
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
║        TREXZACTYL PANEL UPDATER                            ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo ""
}

check_panel_exists() {
    if [ ! -d "$PANEL_PATH" ]; then
        error "Panel not found at $PANEL_PATH. Please install the panel first."
    fi
}

backup_panel() {
    output "Creating backup..."
    
    BACKUP_DIR="/var/backups/trexzactyl"
    BACKUP_NAME="trexzactyl_backup_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p $BACKUP_DIR
    
    # Backup files
    tar -czf "$BACKUP_DIR/${BACKUP_NAME}_files.tar.gz" -C $(dirname $PANEL_PATH) $(basename $PANEL_PATH)
    
    # Backup database
    read -p "Enter database name to backup [panel]: " DB_NAME
    DB_NAME=${DB_NAME:-panel}
    
    read -p "Enter database username [trexzactyl]: " DB_USER
    DB_USER=${DB_USER:-trexzactyl}
    
    read -sp "Enter database password: " DB_PASS
    echo
    
    mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/${BACKUP_NAME}_database.sql"
    
    output "Backup created at: $BACKUP_DIR/${BACKUP_NAME}"
    output "Files: ${BACKUP_NAME}_files.tar.gz"
    output "Database: ${BACKUP_NAME}_database.sql"
    
    echo ""
    read -p "Press enter to continue with update..."
}

enable_maintenance_mode() {
    output "Enabling maintenance mode..."
    
    cd $PANEL_PATH
    php artisan down
    
    output "Maintenance mode enabled"
}

stop_queue_worker() {
    output "Stopping queue worker..."
    
    systemctl stop trexzactyl.service
    
    output "Queue worker stopped"
}

update_files() {
    output "Updating panel files..."
    
    cd $PANEL_PATH
    
    # Stash any local changes
    git stash
    
    # Pull latest changes
    git pull origin main || git pull origin master
    
    output "Panel files updated"
}

update_dependencies() {
    output "Updating dependencies..."
    
    cd $PANEL_PATH
    
    # Update Composer dependencies
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
    
    # Update NPM dependencies
    npm install --legacy-peer-deps
    
    output "Dependencies updated"
}

rebuild_assets() {
    output "Rebuilding frontend assets..."
    
    cd $PANEL_PATH
    npm run build
    
    output "Assets rebuilt"
}

run_migrations() {
    output "Running database migrations..."
    
    cd $PANEL_PATH
    php artisan migrate --seed --force
    
    output "Migrations completed"
}

clear_caches() {
    output "Clearing caches..."
    
    cd $PANEL_PATH
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear
    php artisan route:clear
    
    output "Caches cleared"
}

set_permissions() {
    output "Setting permissions..."
    
    chown -R www-data:www-data $PANEL_PATH
    chmod -R 755 $PANEL_PATH/storage $PANEL_PATH/bootstrap/cache
    
    output "Permissions set"
}

start_queue_worker() {
    output "Starting queue worker..."
    
    systemctl start trexzactyl.service
    
    output "Queue worker started"
}

disable_maintenance_mode() {
    output "Disabling maintenance mode..."
    
    cd $PANEL_PATH
    php artisan up
    
    output "Maintenance mode disabled"
}

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           UPDATE COMPLETED SUCCESSFULLY!                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    output "Panel has been updated to the latest version"
    output "Your backup is located at: /var/backups/trexzactyl/"
    echo ""
    output "If you encounter any issues, you can restore from backup:"
    echo "  1. Stop services: systemctl stop trexzactyl nginx"
    echo "  2. Restore files: tar -xzf /var/backups/trexzactyl/[backup]_files.tar.gz -C /var/www/"
    echo "  3. Restore database: mysql -u [user] -p [database] < /var/backups/trexzactyl/[backup]_database.sql"
    echo "  4. Start services: systemctl start trexzactyl nginx"
    echo ""
}

################################################################################
# MAIN
################################################################################

main() {
    print_banner
    check_root
    check_panel_exists
    
    warning "This will update Trexzactyl Panel to the latest version."
    read -p "Do you want to continue? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        output "Update cancelled"
        exit 0
    fi
    
    backup_panel
    enable_maintenance_mode
    stop_queue_worker
    update_files
    update_dependencies
    rebuild_assets
    run_migrations
    clear_caches
    set_permissions
    start_queue_worker
    disable_maintenance_mode
    
    print_summary
}

main
