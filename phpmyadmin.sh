#!/bin/bash

################################################################################
# Trexzactyl phpMyAdmin Installer
# 
# Description: Automated installer for phpMyAdmin
# Author: Trexzactyl Installer Team
# License: MIT
################################################################################

set -e

################################################################################
# VARIABLES
################################################################################

SCRIPT_VERSION="v1.0.0"
PHPMYADMIN_VERSION="5.2.1"
INSTALL_PATH="/var/www/phpmyadmin"

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
║             ██████╗ ██╗  ██╗██████╗ ███╗   ███╗          ║
║             ██╔══██╗██║  ██║██╔══██╗████╗ ████║          ║
║             ██████╔╝███████║██████╔╝██╔████╔██║          ║
║             ██╔═══╝ ██╔══██║██╔═══╝ ██║╚██╔╝██║          ║
║             ██║     ██║  ██║██║     ██║ ╚═╝ ██║          ║
║             ╚═╝     ╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝          ║
║                 PHPMYADMIN INSTALLER                       ║
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

    # Domain/subdomain
    while true; do
        read -p "Enter domain for phpMyAdmin (e.g., phpmyadmin.example.com): " FQDN
        if [[ ! -z "$FQDN" ]]; then
            break
        fi
        warning "Domain cannot be empty"
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

    # HTTP authentication
    read -p "Do you want to add HTTP authentication (recommended)? (y/n): " -n 1 -r HTTP_AUTH_CONFIRM
    echo
    if [[ $HTTP_AUTH_CONFIRM =~ ^[Yy]$ ]]; then
        CONFIGURE_HTTP_AUTH=true
        read -p "Enter username for HTTP auth: " HTTP_AUTH_USER
        while true; do
            read -sp "Enter password for HTTP auth: " HTTP_AUTH_PASS
            echo
            read -sp "Confirm password: " HTTP_AUTH_PASS_CONFIRM
            echo
            if [[ "$HTTP_AUTH_PASS" == "$HTTP_AUTH_PASS_CONFIRM" ]]; then
                break
            else
                warning "Passwords do not match. Please try again."
            fi
        done
    else
        CONFIGURE_HTTP_AUTH=false
    fi

    echo ""
    output "Configuration complete. Starting installation..."
    sleep 2
}

install_dependencies() {
    output "Installing dependencies..."
    
    apt update -y
    
    # Check PHP version
    if command -v php &> /dev/null; then
        output "PHP is already installed"
    else
        output "Installing PHP..."
        apt install -y php8.1 php8.1-{cli,fpm,mysql,mbstring,zip,gd,xml,curl,json}
    fi
    
    # Install Nginx if not present
    if command -v nginx &> /dev/null; then
        output "Nginx is already installed"
    else
        output "Installing Nginx..."
        apt install -y nginx
    fi
    
    # Install certbot if SSL is requested
    if [ "$CONFIGURE_SSL" = true ]; then
        if ! command -v certbot &> /dev/null; then
            apt install -y certbot python3-certbot-nginx
        fi
    fi
    
    # Install apache2-utils for htpasswd
    if [ "$CONFIGURE_HTTP_AUTH" = true ]; then
        apt install -y apache2-utils
    fi
    
    output "Dependencies installed successfully"
}

download_phpmyadmin() {
    output "Downloading phpMyAdmin..."
    
    # Create directory
    mkdir -p $INSTALL_PATH
    cd /tmp
    
    # Download phpMyAdmin
    wget https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
    
    # Extract
    tar xzf phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
    
    # Move files
    mv phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages/* $INSTALL_PATH/
    
    # Cleanup
    rm -rf phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages
    rm phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
    
    output "phpMyAdmin downloaded successfully"
}

configure_phpmyadmin() {
    output "Configuring phpMyAdmin..."
    
    # Create config directory
    mkdir -p $INSTALL_PATH/tmp
    chmod 777 $INSTALL_PATH/tmp
    
    # Generate blowfish secret
    BLOWFISH_SECRET=$(openssl rand -base64 32)
    
    # Create config file
    cat > $INSTALL_PATH/config.inc.php <<EOF
<?php
/**
 * phpMyAdmin Configuration
 * Generated by Trexzactyl Installer
 */

\$cfg['blowfish_secret'] = '$BLOWFISH_SECRET';

\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = 'localhost';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = false;

\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
\$cfg['TempDir'] = '$INSTALL_PATH/tmp';

// Security settings
\$cfg['CheckConfigurationPermissions'] = true;
\$cfg['AllowArbitraryServer'] = false;
\$cfg['LoginCookieValidity'] = 3600;
\$cfg['LoginCookieStore'] = 3600;
\$cfg['SessionSavePath'] = '$INSTALL_PATH/tmp';

// UI settings
\$cfg['ThemeDefault'] = 'pmahomme';
\$cfg['DefaultLang'] = 'en';
\$cfg['ShowPhpInfo'] = false;
\$cfg['ShowServerInfo'] = false;
\$cfg['ShowDbStructureCreation'] = true;
\$cfg['ShowDbStructureLastUpdate'] = true;
\$cfg['ShowDbStructureLastCheck'] = true;

// Import/Export settings
\$cfg['Export']['compression'] = 'zip';
\$cfg['Import']['charset'] = 'utf-8';
EOF
    
    # Set permissions
    chown -R www-data:www-data $INSTALL_PATH
    chmod 644 $INSTALL_PATH/config.inc.php
    
    output "phpMyAdmin configured successfully"
}

configure_nginx() {
    output "Configuring Nginx..."
    
    # Create Nginx configuration
    cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $FQDN;
    
    root $INSTALL_PATH;
    index index.php;

    access_log /var/log/nginx/phpmyadmin.access.log;
    error_log /var/log/nginx/phpmyadmin.error.log;

    client_max_body_size 100M;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \\n post_max_size=100M";
    }

    location ~* ^.+\.(jpg|jpeg|gif|css|png|js|ico|xml)$ {
        access_log off;
        expires 30d;
    }

    location ~ /\.ht {
        deny all;
    }

    location ~ /(libraries|setup/frames|setup/libs) {
        deny all;
        return 404;
    }
EOF

    # Add HTTP authentication if requested
    if [ "$CONFIGURE_HTTP_AUTH" = true ]; then
        cat >> /etc/nginx/sites-available/phpmyadmin.conf <<EOF

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.phpmyadmin_htpasswd;
EOF
    fi

    cat >> /etc/nginx/sites-available/phpmyadmin.conf <<EOF
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
    
    # Remove default if exists
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    nginx -t || error "Nginx configuration test failed"
    
    # Reload Nginx
    systemctl reload nginx
    
    output "Nginx configured successfully"
}

configure_http_auth() {
    if [ "$CONFIGURE_HTTP_AUTH" = true ]; then
        output "Configuring HTTP authentication..."
        
        # Create htpasswd file
        htpasswd -cb /etc/nginx/.phpmyadmin_htpasswd "$HTTP_AUTH_USER" "$HTTP_AUTH_PASS"
        chmod 644 /etc/nginx/.phpmyadmin_htpasswd
        
        success "HTTP authentication configured"
    fi
}

configure_ssl() {
    if [ "$CONFIGURE_SSL" = true ]; then
        output "Configuring SSL with Let's Encrypt..."
        
        if [[ -z "$LETSENCRYPT_EMAIL" ]]; then
            certbot --nginx -d $FQDN --non-interactive --agree-tos --register-unsafely-without-email --redirect
        else
            certbot --nginx -d $FQDN --non-interactive --agree-tos --email $LETSENCRYPT_EMAIL --redirect
        fi
        
        success "SSL configured successfully"
    else
        warning "Skipping SSL configuration. Configure manually with: certbot --nginx -d $FQDN"
    fi
}

setup_security() {
    output "Setting up additional security measures..."
    
    # Remove setup directory if exists
    rm -rf $INSTALL_PATH/setup
    
    # Create .htaccess for additional protection (Nginx will use the location blocks)
    cat > $INSTALL_PATH/.htaccess <<EOF
# Deny access to configuration files
<Files config.inc.php>
    Require all denied
</Files>

# Deny access to temporary files
<FilesMatch "\.(bak|conf|dist|fla|in[ci]|log|psd|sh|sql|sw[op])|~$">
    Require all denied
</FilesMatch>
EOF
    
    # Set restrictive permissions
    find $INSTALL_PATH -type d -exec chmod 755 {} \;
    find $INSTALL_PATH -type f -exec chmod 644 {} \;
    chmod 600 $INSTALL_PATH/config.inc.php
    
    output "Security measures applied"
}

configure_firewall() {
    output "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 80/tcp
        ufw allow 443/tcp
        success "Firewall rules added"
    else
        warning "UFW not found. Please configure firewall manually."
    fi
}

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║      PHPMYADMIN INSTALLATION COMPLETED SUCCESSFULLY!       ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    success "phpMyAdmin has been installed!"
    echo ""
    
    if [ "$CONFIGURE_SSL" = true ]; then
        output "Access phpMyAdmin at: https://$FQDN"
    else
        output "Access phpMyAdmin at: http://$FQDN"
    fi
    
    echo ""
    
    if [ "$CONFIGURE_HTTP_AUTH" = true ]; then
        output "HTTP Authentication:"
        echo "  Username: $HTTP_AUTH_USER"
        echo "  Password: [as configured]"
        echo ""
    fi
    
    output "Database Credentials:"
    echo "  Use your MySQL/MariaDB database credentials to log in"
    echo ""
    output "Installation Path: $INSTALL_PATH"
    output "Configuration File: $INSTALL_PATH/config.inc.php"
    output "Nginx Config: /etc/nginx/sites-available/phpmyadmin.conf"
    echo ""
    output "Important Security Notes:"
    echo "  - Always use HTTPS in production"
    echo "  - Use strong database passwords"
    echo "  - Consider using HTTP authentication (already configured)"
    echo "  - Regularly update phpMyAdmin"
    echo "  - Monitor access logs: /var/log/nginx/phpmyadmin.access.log"
    echo ""
    output "Update phpMyAdmin:"
    echo "  Download latest version and extract to $INSTALL_PATH"
    echo "  Keep config.inc.php file"
    echo ""
    output "Useful Commands:"
    echo "  - Restart Nginx: systemctl restart nginx"
    echo "  - View logs: tail -f /var/log/nginx/phpmyadmin.error.log"
    echo ""
    output "Thank you for using Trexzactyl phpMyAdmin Installer!"
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
    
    output "Starting phpMyAdmin installation..."
    
    install_dependencies
    download_phpmyadmin
    configure_phpmyadmin
    configure_http_auth
    configure_nginx
    configure_ssl
    setup_security
    configure_firewall
    
    print_summary
}

# Run main function
main
