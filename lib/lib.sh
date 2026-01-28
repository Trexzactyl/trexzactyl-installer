#!/bin/bash

################################################################################
# Common Library Functions
# Shared functions used across all installers
################################################################################

# Color definitions (if not already defined)
if [ -z "$GREEN" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
fi

################################################################################
# OUTPUT FUNCTIONS
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

################################################################################
# SYSTEM DETECTION
################################################################################

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VER=$VERSION_ID
        OS_NAME=$PRETTY_NAME
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        OS_VER=$(lsb_release -sr)
        OS_NAME=$(lsb_release -sd)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
        OS_VER=$DISTRIB_RELEASE
        OS_NAME=$DISTRIB_DESCRIPTION
    else
        OS=$(uname -s)
        OS_VER=$(uname -r)
        OS_NAME="$OS $OS_VER"
    fi
    
    export OS OS_VER OS_NAME
}

check_os_support() {
    local supported_os=("ubuntu" "debian")
    local supported=false
    
    for os in "${supported_os[@]}"; do
        if [ "$OS" = "$os" ]; then
            supported=true
            break
        fi
    done
    
    if [ "$supported" = false ]; then
        error "Unsupported operating system: $OS_NAME"
    fi
    
    # Check version
    case "$OS" in
        ubuntu)
            if [[ ! "$OS_VER" =~ ^(20.04|22.04|24.04)$ ]]; then
                warning "Ubuntu version $OS_VER may not be fully supported. Recommended: 20.04, 22.04, 24.04"
            fi
            ;;
        debian)
            if [[ ! "$OS_VER" =~ ^(11|12)$ ]]; then
                warning "Debian version $OS_VER may not be fully supported. Recommended: 11, 12"
            fi
            ;;
    esac
}

################################################################################
# PRIVILEGE CHECKING
################################################################################

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (or with sudo)"
    fi
}

################################################################################
# PACKAGE MANAGEMENT
################################################################################

update_repos() {
    output "Updating package repositories..."
    apt update -qq
}

install_package() {
    local package="$1"
    
    if dpkg -l | grep -q "^ii  $package "; then
        output "$package is already installed"
        return 0
    fi
    
    output "Installing $package..."
    apt install -y -qq "$package" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        success "$package installed successfully"
        return 0
    else
        error "Failed to install $package"
        return 1
    fi
}

################################################################################
# SERVICE MANAGEMENT
################################################################################

enable_service() {
    local service="$1"
    
    if systemctl is-enabled --quiet "$service"; then
        output "$service is already enabled"
    else
        output "Enabling $service..."
        systemctl enable "$service" > /dev/null 2>&1
        success "$service enabled"
    fi
}

start_service() {
    local service="$1"
    
    if systemctl is-active --quiet "$service"; then
        output "$service is already running"
    else
        output "Starting $service..."
        systemctl start "$service" > /dev/null 2>&1
        
        if systemctl is-active --quiet "$service"; then
            success "$service started successfully"
        else
            error "Failed to start $service"
        fi
    fi
}

restart_service() {
    local service="$1"
    
    output "Restarting $service..."
    systemctl restart "$service" > /dev/null 2>&1
    
    if systemctl is-active --quiet "$service"; then
        success "$service restarted successfully"
    else
        error "Failed to restart $service"
    fi
}

################################################################################
# FILE OPERATIONS
################################################################################

backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$file" ]; then
        cp "$file" "$backup"
        output "Backed up $file to $backup"
    fi
}

download_file() {
    local url="$1"
    local output="$2"
    
    output "Downloading $(basename "$output")..."
    
    if command -v wget &> /dev/null; then
        wget -q -O "$output" "$url"
    elif command -v curl &> /dev/null; then
        curl -s -o "$output" "$url"
    else
        error "Neither wget nor curl is available"
    fi
    
    if [ -f "$output" ]; then
        success "Downloaded $(basename "$output")"
    else
        error "Failed to download $(basename "$output")"
    fi
}

################################################################################
# USER INPUT
################################################################################

ask() {
    local prompt="$1"
    local default="${2:-}"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " response
        echo "${response:-$default}"
    else
        read -p "$prompt: " response
        echo "$response"
    fi
}

ask_secret() {
    local prompt="$1"
    
    read -sp "$prompt: " response
    echo ""
    echo "$response"
}

confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        read -p "$prompt [Y/n]: " -n 1 -r response
    else
        read -p "$prompt [y/N]: " -n 1 -r response
    fi
    
    echo ""
    
    response=${response:-$default}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# PASSWORD GENERATION
################################################################################

generate_password() {
    local length="${1:-32}"
    
    if command -v openssl &> /dev/null; then
        openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
    else
        tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
    fi
}

################################################################################
# IP ADDRESS FUNCTIONS
################################################################################

get_ip() {
    local ip
    
    # Try multiple services
    ip=$(curl -s -4 ifconfig.me 2>/dev/null)
    
    if [ -z "$ip" ]; then
        ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    fi
    
    if [ -z "$ip" ]; then
        ip=$(curl -s -4 api.ipify.org 2>/dev/null)
    fi
    
    if [ -z "$ip" ]; then
        ip=$(hostname -I | awk '{print $1}')
    fi
    
    echo "$ip"
}

################################################################################
# VALIDATION
################################################################################

validate_email() {
    local email="$1"
    
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_url() {
    local url="$1"
    
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+(\.[a-zA-Z]{2,})?(/.*)?$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_domain() {
    local domain="$1"
    
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

################################################################################
# DATABASE FUNCTIONS
################################################################################

mysql_secure_installation_auto() {
    output "Securing MySQL installation..."
    
    mysql -u root <<-EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
    
    success "MySQL secured"
}

create_database() {
    local db_name="$1"
    
    output "Creating database: $db_name"
    
    mysql -u root <<-EOF
CREATE DATABASE IF NOT EXISTS \`${db_name}\`;
EOF
    
    success "Database created: $db_name"
}

create_db_user() {
    local username="$1"
    local password="$2"
    local database="$3"
    local host="${4:-127.0.0.1}"
    
    output "Creating database user: $username@$host"
    
    mysql -u root <<-EOF
CREATE USER IF NOT EXISTS '${username}'@'${host}' IDENTIFIED BY '${password}';
GRANT ALL PRIVILEGES ON \`${database}\`.* TO '${username}'@'${host}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    
    success "Database user created: $username@$host"
}

################################################################################
# FIREWALL FUNCTIONS
################################################################################

configure_firewall() {
    local ports=("$@")
    
    if ! command -v ufw &> /dev/null; then
        warning "UFW not installed. Skipping firewall configuration."
        return 0
    fi
    
    output "Configuring firewall..."
    
    # Allow SSH
    ufw allow 22/tcp > /dev/null 2>&1
    
    # Allow specified ports
    for port in "${ports[@]}"; do
        output "Allowing port: $port"
        ufw allow "$port" > /dev/null 2>&1
    done
    
    # Enable firewall
    echo "y" | ufw enable > /dev/null 2>&1
    
    success "Firewall configured"
}

################################################################################
# EXPORT ALL FUNCTIONS
################################################################################

export -f output warning error success
export -f detect_distro check_os_support check_root
export -f update_repos install_package
export -f enable_service start_service restart_service
export -f backup_file download_file
export -f ask ask_secret confirm
export -f generate_password
export -f get_ip
export -f validate_email validate_url validate_domain
export -f mysql_secure_installation_auto create_database create_db_user
export -f configure_firewall
