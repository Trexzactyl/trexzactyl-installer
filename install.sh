#!/bin/bash

################################################################################
# Trexzactyl Panel Installer
# 
# Description: Automated installer for Trexzactyl Panel
# Author: Trexzactyl Installer Team
# License: MIT
################################################################################

set -e

################################################################################
# VARIABLES
################################################################################

SCRIPT_VERSION="v1.0.0"
WEBSERVER="nginx"
PANEL_PATH="/var/www/trexzactyl"
GITHUB_REPO="https://github.com/trexzactyl/trexzactyl"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# FUNCTIONS
################################################################################

# Output functions
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

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VER=$VERSION_ID
    else
        error "Cannot detect OS. /etc/os-release not found."
    fi

    case "$OS" in
        ubuntu)
            if [[ "$OS_VER" != "20.04" && "$OS_VER" != "22.04" && "$OS_VER" != "24.04" ]]; then
                warning "Unsupported Ubuntu version: $OS_VER. Supported: 20.04, 22.04, 24.04"
            fi
            ;;
        debian)
            if [[ "$OS_VER" != "11" && "$OS_VER" != "12" ]]; then
                warning "Unsupported Debian version: $OS_VER. Supported: 11, 12"
            fi
            ;;
        *)
            error "Unsupported OS: $OS. Supported: Ubuntu 20.04/22.04/24.04, Debian 11/12"
            ;;
    esac

    output "Detected OS: $OS $OS_VER"
}

# Print banner
print_banner() {
    cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║        ████████╗██████╗ ███████╗██╗  ██╗███████╗          ║
║        ╚══██╔══╝██╔══██╗██╔════╝╚██╗██╔╝╚══███╔╝          ║
║           ██║   ██████╔╝█████╗   ╚███╔╝   ███╔╝           ║
║           ██║   ██╔══██╗██╔══╝   ██╔██╗  ███╔╝            ║
║           ██║   ██║  ██║███████╗██╔╝ ██╗███████╗          ║
║           ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝          ║
║                                                            ║
║                 TREXZACTYL PANEL INSTALLER                 ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo ""
    output "Version: $SCRIPT_VERSION"
    echo ""
}

# Get user input
get_user_input() {
    output "Configuration Setup"
    echo ""

    # Domain
    while true; do
        read -p "Enter your domain name (e.g., panel.example.com): " FQDN
        if [[ ! -z "$FQDN" ]]; then
            break
        fi
        warning "Domain name cannot be empty"
    done

    # SSL
    read -p "Do you want to automatically configure SSL with Let's Encrypt? (y/n): " -n 1 -r SSL_CONFIRM
    echo
    if [[ $SSL_CONFIRM =~ ^[Yy]$ ]]; then
        CONFIGURE_SSL=true
        read -p "Enter your email for Let's Encrypt (optional, press enter to skip): " LETSENCRYPT_EMAIL
    else
        CONFIGURE_SSL=false
    fi

    # Database
    output "Database Configuration"
    read -p "Enter database name [panel]: " DB_NAME
    DB_NAME=${DB_NAME:-panel}

    read -p "Enter database username [trexzactyl]: " DB_USER
    DB_USER=${DB_USER:-trexzactyl}

    while true; do
        read -sp "Enter database password (leave empty to generate): " DB_PASS
        echo
        if [[ -z "$DB_PASS" ]]; then
            DB_PASS=$(openssl rand -base64 32)
            output "Generated database password: $DB_PASS"
            break
        else
            read -sp "Confirm database password: " DB_PASS_CONFIRM
            echo
            if [[ "$DB_PASS" == "$DB_PASS_CONFIRM" ]]; then
                break
            else
                warning "Passwords do not match. Please try again."
            fi
        fi
    done

    # Admin User
    read -p "Do you want to create an admin user now? (y/n): " -n 1 -r ADMIN_CONFIRM
    echo
    if [[ $ADMIN_CONFIRM =~ ^[Yy]$ ]]; then
        CREATE_ADMIN=true
        read -p "Admin email: " ADMIN_EMAIL
        read -p "Admin username: " ADMIN_USERNAME
        read -p "Admin first name: " ADMIN_FIRSTNAME
        read -p "Admin last name: " ADMIN_LASTNAME
        while true; do
            read -sp "Admin password: " ADMIN_PASSWORD
            echo
            read -sp "Confirm admin password: " ADMIN_PASSWORD_CONFIRM
            echo
            if [[ "$ADMIN_PASSWORD" == "$ADMIN_PASSWORD_CONFIRM" ]]; then
                break
            else
                warning "Passwords do not match. Please try again."
            fi
        done
    else
        CREATE_ADMIN=false
    fi

    echo ""
    output "Configuration complete. Starting installation..."
    sleep 2
}

# Install dependencies
install_dependencies() {
    output "Installing system dependencies..."
    
    apt update -y
    apt upgrade -y
    
    # Add PHP repository
    apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    
    # Add Node.js repository
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    
    apt update -y
    
    # Install packages
    output "Installing PHP, Nginx, MariaDB, Redis, and other dependencies..."
    apt install -y php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} \
        mariadb-server nginx tar unzip git redis-server certbot python3-certbot-nginx \
        nodejs
    
    # Install Composer
    output "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    
    output "Dependencies installed successfully"
}

# Configure database
configure_database() {
    output "Configuring MariaDB..."
    
    systemctl start mariadb
    systemctl enable mariadb
    
    # Create database and user
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    
    output "Database configured successfully"
}

# Download and install panel
install_panel() {
    output "Downloading and installing Trexzactyl Panel..."
    
    # Create directory
    mkdir -p $PANEL_PATH
    cd $PANEL_PATH
    
    # Clone repository
    if [ -d "$PANEL_PATH/.git" ]; then
        output "Panel directory exists, pulling latest changes..."
        git pull
    else
        output "Cloning panel repository..."
        git clone $GITHUB_REPO .
    fi
    
    # Set permissions
    chown -R www-data:www-data $PANEL_PATH
    
    output "Panel downloaded successfully"
}

# Configure panel
configure_panel() {
    output "Configuring Trexzactyl Panel..."
    
    cd $PANEL_PATH
    
    # Copy environment file
    cp .env.example .env
    
    # Install Composer dependencies
    output "Installing Composer dependencies..."
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader -n
    
    # Generate encryption key
    php artisan key:generate --force
    
    # Configure environment
    php artisan p:environment:setup \
        --author="$ADMIN_EMAIL" \
        --url="https://$FQDN" \
        --timezone="UTC" \
        --cache="redis" \
        --session="redis" \
        --queue="redis" \
        --redis-host="127.0.0.1" \
        --redis-pass="" \
        --redis-port="6379" \
        --no-interaction || {
        output "Manual environment configuration..."
        sed -i "s|APP_URL=.*|APP_URL=https://$FQDN|" .env
        sed -i "s|DB_HOST=.*|DB_HOST=127.0.0.1|" .env
        sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
        sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|" .env
        sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env
    }
    
    # Create required directories
    mkdir -p storage/framework/{sessions,views,cache}
    mkdir -p storage/logs
    mkdir -p bootstrap/cache
    
    # Set permissions
    chmod -R 755 storage bootstrap/cache
    chown -R www-data:www-data $PANEL_PATH
    
    # Run migrations
    output "Running database migrations..."
    php artisan migrate --seed --force
    
    # Install frontend dependencies and build
    output "Building frontend assets..."
    npm install --legacy-peer-deps
    npm run build
    
    # Clear caches
    php artisan config:clear
    php artisan cache:clear
    php artisan view:clear
    
    output "Panel configured successfully"
}

# Configure web server
configure_webserver() {
    output "Configuring Nginx..."
    
    # Remove default config
    rm -f /etc/nginx/sites-enabled/default
    
    # Create Nginx config
    cat > /etc/nginx/sites-available/trexzactyl.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $FQDN;

    root $PANEL_PATH/public;
    index index.php;

    access_log /var/log/nginx/trexzactyl.access.log;
    error_log  /var/log/nginx/trexzactyl.error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \\n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/trexzactyl.conf /etc/nginx/sites-enabled/trexzactyl.conf
    
    # Test and reload Nginx
    nginx -t || error "Nginx configuration test failed"
    systemctl restart nginx
    systemctl enable nginx
    
    output "Nginx configured successfully"
}

# Configure SSL
configure_ssl() {
    if [ "$CONFIGURE_SSL" = true ]; then
        output "Configuring SSL with Let's Encrypt..."
        
        if [[ -z "$LETSENCRYPT_EMAIL" ]]; then
            certbot --nginx -d $FQDN --non-interactive --agree-tos --register-unsafely-without-email --redirect
        else
            certbot --nginx -d $FQDN --non-interactive --agree-tos --email $LETSENCRYPT_EMAIL --redirect
        fi
        
        output "SSL configured successfully"
    else
        warning "Skipping SSL configuration. You can configure it later with: certbot --nginx -d $FQDN"
    fi
}

# Setup queue worker
setup_queue_worker() {
    output "Setting up queue worker service..."
    
    # Copy service file
    cp $PANEL_PATH/trexzactyl.service /etc/systemd/system/trexzactyl.service
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable trexzactyl.service
    systemctl start trexzactyl.service
    
    output "Queue worker configured successfully"
}

# Setup cron
setup_cron() {
    output "Setting up cron jobs..."
    
    # Add cron job for Laravel scheduler
    (crontab -l 2>/dev/null; echo "* * * * * php $PANEL_PATH/artisan schedule:run >> /dev/null 2>&1") | crontab -
    
    output "Cron jobs configured successfully"
}

# Create admin user
create_admin_user() {
    if [ "$CREATE_ADMIN" = true ]; then
        output "Creating admin user..."
        
        cd $PANEL_PATH
        php artisan p:user:make \
            --email="$ADMIN_EMAIL" \
            --username="$ADMIN_USERNAME" \
            --name-first="$ADMIN_FIRSTNAME" \
            --name-last="$ADMIN_LASTNAME" \
            --password="$ADMIN_PASSWORD" \
            --admin=1 \
            --no-interaction || {
            warning "Automated user creation failed. You can create a user manually with: php artisan p:user:make"
        }
        
        output "Admin user created successfully"
    else
        warning "Admin user creation skipped. Create one with: cd $PANEL_PATH && php artisan p:user:make"
    fi
}

# Setup Redis
setup_redis() {
    output "Configuring Redis..."
    
    systemctl enable redis-server
    systemctl start redis-server
    
    output "Redis configured successfully"
}

# Print summary
print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           INSTALLATION COMPLETED SUCCESSFULLY!             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    output "Panel URL: https://$FQDN"
    output "Panel Path: $PANEL_PATH"
    output "Database: $DB_NAME"
    output "Database User: $DB_USER"
    output "Database Password: $DB_PASS"
    echo ""
    
    if [ "$CREATE_ADMIN" = true ]; then
        output "Admin User: $ADMIN_USERNAME"
        output "Admin Email: $ADMIN_EMAIL"
    else
        warning "Remember to create an admin user: cd $PANEL_PATH && php artisan p:user:make"
    fi
    
    echo ""
    output "Important Commands:"
    echo "  - View queue worker logs: journalctl -u trexzactyl -f"
    echo "  - Restart queue worker: systemctl restart trexzactyl"
    echo "  - Clear cache: cd $PANEL_PATH && php artisan cache:clear"
    echo ""
    output "Thank you for using Trexzactyl Panel Installer!"
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
    
    output "Starting installation process..."
    
    install_dependencies
    configure_database
    install_panel
    configure_panel
    configure_webserver
    configure_ssl
    setup_redis
    setup_queue_worker
    setup_cron
    create_admin_user
    
    print_summary
}

# Run main function
main
