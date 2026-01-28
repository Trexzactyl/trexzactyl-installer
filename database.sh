#!/bin/bash

################################################################################
# Trexzactyl Database Host Installer
# 
# Description: Setup dedicated database server for game servers
# Author: Trexzactyl Installer Team
# License: MIT
################################################################################

set -e

################################################################################
# VARIABLES
################################################################################

SCRIPT_VERSION="v1.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VER=$VERSION_ID
    else
        error "Cannot detect OS. /etc/os-release not found."
    fi

    output "Detected OS: $OS $OS_VER"
}

print_banner() {
    cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║        ██████╗  █████╗ ████████╗ █████╗ ██████╗          ║
║        ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗         ║
║        ██║  ██║███████║   ██║   ███████║██████╔╝         ║
║        ██║  ██║██╔══██║   ██║   ██╔══██║██╔══██╗         ║
║        ██████╔╝██║  ██║   ██║   ██║  ██║██████╔╝         ║
║        ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═════╝          ║
║                                                            ║
║              DATABASE HOST INSTALLER                       ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo ""
    output "Version: $SCRIPT_VERSION"
    echo ""
}

get_user_input() {
    output "Configuration Setup"
    echo ""
    output "This will setup a database server for game servers to use."
    echo ""

    # Panel connection details
    read -p "Enter panel database host [127.0.0.1]: " PANEL_DB_HOST
    PANEL_DB_HOST=${PANEL_DB_HOST:-127.0.0.1}
    
    read -p "Enter panel database name [panel]: " PANEL_DB_NAME
    PANEL_DB_NAME=${PANEL_DB_NAME:-panel}
    
    read -p "Enter panel database username [trexzactyl]: " PANEL_DB_USER
    PANEL_DB_USER=${PANEL_DB_USER:-trexzactyl}
    
    read -sp "Enter panel database password: " PANEL_DB_PASS
    echo
    
    # Database host configuration
    read -p "Enter this database host IP address: " DB_HOST_IP
    
    # Create dedicated user for database management
    read -p "Enter username for database management [dbadmin]: " DB_ADMIN_USER
    DB_ADMIN_USER=${DB_ADMIN_USER:-dbadmin}
    
    while true; do
        read -sp "Enter password for database management (leave empty to generate): " DB_ADMIN_PASS
        echo
        if [[ -z "$DB_ADMIN_PASS" ]]; then
            DB_ADMIN_PASS=$(openssl rand -base64 32)
            output "Generated database admin password: $DB_ADMIN_PASS"
            break
        else
            read -sp "Confirm password: " DB_ADMIN_PASS_CONFIRM
            echo
            if [[ "$DB_ADMIN_PASS" == "$DB_ADMIN_PASS_CONFIRM" ]]; then
                break
            else
                warning "Passwords do not match. Please try again."
            fi
        fi
    done

    echo ""
    output "Configuration complete. Starting installation..."
    sleep 2
}

install_mariadb() {
    output "Installing MariaDB..."
    
    apt update -y
    apt install -y mariadb-server mariadb-client
    
    # Start and enable MariaDB
    systemctl start mariadb
    systemctl enable mariadb
    
    output "MariaDB installed successfully"
}

secure_mariadb() {
    output "Securing MariaDB installation..."
    
    # Set root password and secure installation
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$(openssl rand -base64 32)';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    
    output "MariaDB secured successfully"
}

configure_mariadb() {
    output "Configuring MariaDB for remote connections..."
    
    # Create custom configuration
    cat > /etc/mysql/mariadb.conf.d/99-trexzactyl.cnf <<EOF
[mysqld]
# Bind to all interfaces
bind-address = 0.0.0.0

# Performance settings
max_connections = 500
max_allowed_packet = 256M
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Logging
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Security
local_infile = 0
EOF
    
    # Restart MariaDB
    systemctl restart mariadb
    
    output "MariaDB configured successfully"
}

create_database_user() {
    output "Creating database management user..."
    
    mysql -u root <<EOF
CREATE USER IF NOT EXISTS '${DB_ADMIN_USER}'@'%' IDENTIFIED BY '${DB_ADMIN_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_ADMIN_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    
    success "Database management user created"
}

configure_firewall() {
    output "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        # Allow MySQL from specific sources
        output "Opening MySQL port (3306)"
        ufw allow 3306/tcp
        
        success "Firewall configured"
        warning "Make sure to restrict access to trusted IPs only in production!"
    else
        warning "UFW not found. Please configure firewall manually to allow port 3306."
    fi
}

create_panel_integration() {
    output "Setting up panel integration..."
    
    # This creates a script that the panel can use to create databases
    cat > /usr/local/bin/trexzactyl-db-manager <<'DBSCRIPT'
#!/bin/bash
# Trexzactyl Database Manager
# This script is called by the panel to manage databases

ACTION=$1
DB_NAME=$2
DB_USER=$3
DB_PASS=$4

case "$ACTION" in
    create)
        mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
        echo "Database ${DB_NAME} created successfully"
        ;;
    delete)
        mysql -u root <<EOF
DROP DATABASE IF EXISTS \`${DB_NAME}\`;
DROP USER IF EXISTS '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
        echo "Database ${DB_NAME} deleted successfully"
        ;;
    *)
        echo "Usage: $0 {create|delete} db_name db_user db_pass"
        exit 1
        ;;
esac
DBSCRIPT
    
    chmod +x /usr/local/bin/trexzactyl-db-manager
    
    output "Panel integration script created at: /usr/local/bin/trexzactyl-db-manager"
}

test_connection() {
    output "Testing database connection..."
    
    # Test local connection
    if mysql -u ${DB_ADMIN_USER} -p${DB_ADMIN_PASS} -e "SELECT 1;" &>/dev/null; then
        success "Local database connection successful"
    else
        error "Local database connection failed"
    fi
}

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║    DATABASE HOST INSTALLATION COMPLETED SUCCESSFULLY!      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    success "Database host has been configured!"
    echo ""
    output "Database Host Information:"
    echo "  Host: $DB_HOST_IP"
    echo "  Port: 3306"
    echo ""
    output "Management Credentials:"
    echo "  Username: $DB_ADMIN_USER"
    echo "  Password: $DB_ADMIN_PASS"
    echo ""
    output "IMPORTANT: Add this database host to your panel:"
    echo ""
    echo "  1. Log into your Trexzactyl Panel as admin"
    echo "  2. Go to: Admin Panel → Databases → Database Hosts"
    echo "  3. Click 'Create New'"
    echo "  4. Enter the following details:"
    echo "     - Name: $(hostname) Database"
    echo "     - Host: $DB_HOST_IP"
    echo "     - Port: 3306"
    echo "     - Username: $DB_ADMIN_USER"
    echo "     - Password: $DB_ADMIN_PASS"
    echo "  5. Click 'Create Database Host'"
    echo ""
    output "Security Recommendations:"
    echo "  - Restrict firewall to only allow panel and node IPs"
    echo "  - Use strong passwords"
    echo "  - Enable SSL/TLS for MySQL connections"
    echo "  - Regular backups"
    echo "  - Monitor logs: /var/log/mysql/"
    echo ""
    output "Testing Connection from Panel Server:"
    echo "  mysql -u $DB_ADMIN_USER -p -h $DB_HOST_IP"
    echo ""
    output "Database Management Script:"
    echo "  /usr/local/bin/trexzactyl-db-manager"
    echo ""
    output "Useful Commands:"
    echo "  - Restart MariaDB: systemctl restart mariadb"
    echo "  - View logs: tail -f /var/log/mysql/error.log"
    echo "  - MySQL console: mysql -u root"
    echo ""
    output "Thank you for using Trexzactyl Database Host Installer!"
    echo ""
}

################################################################################
# MAIN INSTALLATION
################################################################################

main() {
    print_banner
    check_root
    detect_os
    get_user_input
    
    output "Starting database host installation..."
    
    install_mariadb
    secure_mariadb
    configure_mariadb
    create_database_user
    configure_firewall
    create_panel_integration
    test_connection
    
    print_summary
}

# Run main function
main
