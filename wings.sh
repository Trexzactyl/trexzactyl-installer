#!/bin/bash

################################################################################
# Trexzactyl Wings Installer
# 
# Description: Automated installer for Trexzactyl Wings (Daemon)
# Author: Trexzactyl Installer Team
# License: MIT
################################################################################

set -e

################################################################################
# VARIABLES
################################################################################

SCRIPT_VERSION="v1.0.0"
WINGS_PATH="/etc/trexzactyl"
DOCKER_COMPOSE_VERSION="2.24.5"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

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
║                  WINGS DAEMON INSTALLER                    ║
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

    # Panel URL
    while true; do
        read -p "Enter your panel URL (e.g., https://panel.example.com): " PANEL_URL
        if [[ ! -z "$PANEL_URL" ]]; then
            # Remove trailing slash
            PANEL_URL="${PANEL_URL%/}"
            break
        fi
        warning "Panel URL cannot be empty"
    done

    # FQDN
    while true; do
        read -p "Enter this node's FQDN (e.g., node1.example.com): " FQDN
        if [[ ! -z "$FQDN" ]]; then
            break
        fi
        warning "FQDN cannot be empty"
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

    # Database for standalone node
    read -p "Is this a standalone node (not same server as panel)? (y/n): " -n 1 -r STANDALONE_CONFIRM
    echo
    if [[ $STANDALONE_CONFIRM =~ ^[Yy]$ ]]; then
        STANDALONE_NODE=true
    else
        STANDALONE_NODE=false
    fi

    echo ""
    output "Configuration complete. Starting installation..."
    sleep 2
}

install_dependencies() {
    output "Installing system dependencies..."
    
    apt update -y
    apt upgrade -y
    
    # Install required packages
    output "Installing Docker, curl, and other dependencies..."
    apt install -y curl tar unzip zip apt-transport-https ca-certificates gnupg lsb-release
    
    output "Dependencies installed successfully"
}

install_docker() {
    output "Installing Docker..."
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        output "Docker is already installed"
        docker --version
    else
        # Install Docker
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        
        # Enable and start Docker
        systemctl enable docker
        systemctl start docker
        
        output "Docker installed successfully"
    fi
}

enable_swap() {
    output "Configuring swap memory..."
    
    # Check if swap already exists
    SWAP_COUNT=$(swapon --show | wc -l)
    if [ "$SWAP_COUNT" -gt 0 ]; then
        output "Swap is already configured"
        return
    fi
    
    # Create 2GB swap file
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    
    # Make swap permanent
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    
    output "Swap configured successfully"
}

configure_kernel() {
    output "Configuring kernel parameters..."
    
    # Enable necessary kernel modules
    cat > /etc/modules-load.d/trexzactyl.conf <<EOF
br_netfilter
ip_tables
ip6_tables
xt_conntrack
xt_MASQUERADE
EOF
    
    # Load modules
    modprobe br_netfilter
    modprobe ip_tables
    modprobe ip6_tables
    modprobe xt_conntrack
    modprobe xt_MASQUERADE
    
    # Configure sysctl
    cat > /etc/sysctl.d/99-trexzactyl.conf <<EOF
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF
    
    sysctl --system
    
    output "Kernel configured successfully"
}

install_wings() {
    output "Installing Wings daemon..."
    
    # Create directory
    mkdir -p "$WINGS_PATH"
    cd "$WINGS_PATH" || exit
    
    # Download Wings
    output "Downloading latest Wings binary..."
    if [[ "$(uname -m)" == "x86_64" ]]; then
        ARCH="amd64"
    else
        ARCH="arm64"
    fi
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_${ARCH}"
    
    chmod u+x /usr/local/bin/wings
    
    output "Wings binary installed successfully"
}

configure_wings_service() {
    output "Configuring Wings systemd service..."
    
    # Create systemd service
    cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Trexzactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=$WINGS_PATH
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    output "Wings service configured successfully"
}

configure_firewall() {
    output "Configuring firewall rules..."
    
    # Check if UFW is installed
    if command -v ufw &> /dev/null; then
        output "UFW detected, configuring rules..."
        
        # Allow SSH
        ufw allow 22/tcp
        
        # Allow Wings
        ufw allow 8080/tcp
        ufw allow 2022/tcp
        
        # Allow game server ports (example range)
        ufw allow 25565:25600/tcp
        ufw allow 25565:25600/udp
        
        # Enable firewall
        echo "y" | ufw enable
        
        success "Firewall configured"
    else
        warning "UFW not installed. Please configure firewall manually."
        echo "Required ports:"
        echo "  - 8080/tcp (Wings API)"
        echo "  - 2022/tcp (Wings SFTP)"
        echo "  - Game server ports as needed"
    fi
}

configure_ssl() {
    if [ "$CONFIGURE_SSL" = true ]; then
        output "Configuring SSL with Let's Encrypt..."
        
        # Install certbot if not present
        if ! command -v certbot &> /dev/null; then
            apt install -y certbot
        fi
        
        # Generate certificate
        if [[ -z "$LETSENCRYPT_EMAIL" ]]; then
            certbot certonly --standalone -d $FQDN --non-interactive --agree-tos --register-unsafely-without-email
        else
            certbot certonly --standalone -d $FQDN --non-interactive --agree-tos --email $LETSENCRYPT_EMAIL
        fi
        
        # Create symbolic links for Wings
        mkdir -p $WINGS_PATH/certs
        ln -sf /etc/letsencrypt/live/$FQDN/fullchain.pem $WINGS_PATH/certs/cert.pem
        ln -sf /etc/letsencrypt/live/$FQDN/privkey.pem $WINGS_PATH/certs/cert.key
        
        success "SSL configured successfully"
    else
        warning "Skipping SSL configuration. You'll need to configure SSL manually."
    fi
}

create_config_template() {
    output "Creating Wings configuration template..."
    
    cat > $WINGS_PATH/config.yml <<EOF
debug: false
uuid: YOUR_NODE_UUID_HERE
token_id: YOUR_TOKEN_ID_HERE
token: YOUR_TOKEN_HERE
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: $([[ "$CONFIGURE_SSL" == "true" ]] && echo "true" || echo "false")
    cert: $WINGS_PATH/certs/cert.pem
    key: $WINGS_PATH/certs/cert.key
  upload_limit: 100
system:
  root_directory: /var/lib/trexzactyl/volumes
  log_directory: /var/log/trexzactyl/
  data: $WINGS_PATH
  sftp:
    bind_port: 2022
  crash_detection:
    enabled: true
    detect_clean_exit_as_crash: false
  backups:
    write_limit: 0
  transfers:
    download_limit: 0
allowed_mounts: []
remote: '$PANEL_URL'
EOF
    
    chmod 600 $WINGS_PATH/config.yml
    
    output "Configuration template created at: $WINGS_PATH/config.yml"
}

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        WINGS INSTALLATION COMPLETED SUCCESSFULLY!          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    success "Wings has been installed!"
    echo ""
    output "Next Steps:"
    echo ""
    echo "1. Go to your panel: $PANEL_URL/admin/nodes"
    echo "2. Create a new node or select existing node"
    echo "3. Go to 'Configuration' tab"
    echo "4. Copy the auto-deploy command"
    echo "5. Run the command on this server"
    echo ""
    echo "OR manually configure:"
    echo ""
    echo "1. Get your node configuration from the panel"
    echo "2. Edit: nano $WINGS_PATH/config.yml"
    echo "3. Replace YOUR_NODE_UUID_HERE, YOUR_TOKEN_ID_HERE, YOUR_TOKEN_HERE"
    echo "4. Start Wings: systemctl start wings"
    echo "5. Enable on boot: systemctl enable wings"
    echo ""
    output "Wings Configuration File: $WINGS_PATH/config.yml"
    output "Wings Logs: journalctl -u wings -f"
    echo ""
    output "Important Commands:"
    echo "  - Start Wings: systemctl start wings"
    echo "  - Stop Wings: systemctl stop wings"
    echo "  - Restart Wings: systemctl restart wings"
    echo "  - View Logs: journalctl -u wings -f"
    echo "  - Check Status: systemctl status wings"
    echo ""
    
    if [ "$CONFIGURE_SSL" = true ]; then
        success "SSL is configured and enabled"
        output "Certificate: $WINGS_PATH/certs/cert.pem"
        output "Private Key: $WINGS_PATH/certs/cert.key"
    else
        warning "SSL is not configured. Configure it manually if needed."
    fi
    
    echo ""
    output "Firewall Ports:"
    echo "  - 8080/tcp (Wings API)"
    echo "  - 2022/tcp (Wings SFTP)"
    echo "  - 25565-25600/tcp & udp (Game servers - example)"
    echo ""
    output "Thank you for using Trexzactyl Wings Installer!"
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
    
    output "Starting Wings installation..."
    
    install_dependencies
    install_docker
    enable_swap
    configure_kernel
    install_wings
    configure_wings_service
    configure_ssl
    create_config_template
    configure_firewall
    
    print_summary
}

# Run main function
main
