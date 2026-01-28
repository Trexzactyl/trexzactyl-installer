#!/bin/bash

################################################################################
# FQDN Verification Library
# Verifies that the FQDN points to the server
################################################################################

# Check if FQDN is valid format
verify_fqdn_format() {
    local fqdn="$1"
    
    if [[ ! "$fqdn" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    
    return 0
}

# Get server's public IP
get_public_ip() {
    local ip
    
    # Try multiple services
    ip=$(curl -s -4 https://ifconfig.me 2>/dev/null)
    
    if [ -z "$ip" ]; then
        ip=$(curl -s -4 https://icanhazip.com 2>/dev/null)
    fi
    
    if [ -z "$ip" ]; then
        ip=$(curl -s -4 https://api.ipify.org 2>/dev/null)
    fi
    
    if [ -z "$ip" ]; then
        ip=$(curl -s -4 https://ipinfo.io/ip 2>/dev/null)
    fi
    
    echo "$ip"
}

# Resolve FQDN to IP
resolve_fqdn() {
    local fqdn="$1"
    local ip
    
    # Try to resolve with dig
    if command -v dig &> /dev/null; then
        ip=$(dig +short "$fqdn" A | tail -n1)
    # Try with host
    elif command -v host &> /dev/null; then
        ip=$(host "$fqdn" | grep "has address" | head -n1 | awk '{print $4}')
    # Try with nslookup
    elif command -v nslookup &> /dev/null; then
        ip=$(nslookup "$fqdn" | grep -A1 "Name:" | grep "Address:" | awk '{print $2}')
    fi
    
    echo "$ip"
}

# Verify FQDN points to this server
verify_fqdn() {
    local fqdn="$1"
    local auto_configure="${2:-false}"
    
    output "Verifying FQDN: $fqdn"
    
    # Check format
    if ! verify_fqdn_format "$fqdn"; then
        error "Invalid FQDN format: $fqdn"
    fi
    
    # Get server IP
    local server_ip=$(get_public_ip)
    
    if [ -z "$server_ip" ]; then
        warning "Could not determine server's public IP address"
        if [ "$auto_configure" = "false" ]; then
            if ! confirm "Continue anyway?"; then
                error "FQDN verification aborted"
            fi
        fi
        return 0
    fi
    
    output "Server IP: $server_ip"
    
    # Resolve FQDN
    local fqdn_ip=$(resolve_fqdn "$fqdn")
    
    if [ -z "$fqdn_ip" ]; then
        warning "Could not resolve FQDN: $fqdn"
        warning "Make sure DNS records are configured correctly"
        
        if [ "$auto_configure" = "false" ]; then
            echo ""
            echo "DNS Configuration:"
            echo "  Type: A"
            echo "  Name: $fqdn"
            echo "  Value: $server_ip"
            echo ""
            
            if ! confirm "Continue anyway?"; then
                error "FQDN verification aborted"
            fi
        fi
        return 0
    fi
    
    output "FQDN resolves to: $fqdn_ip"
    
    # Compare IPs
    if [ "$server_ip" != "$fqdn_ip" ]; then
        warning "FQDN does not point to this server!"
        warning "FQDN IP: $fqdn_ip"
        warning "Server IP: $server_ip"
        
        if [ "$auto_configure" = "false" ]; then
            echo ""
            echo "Please update your DNS records:"
            echo "  Type: A"
            echo "  Name: $fqdn"
            echo "  Current Value: $fqdn_ip"
            echo "  Should Be: $server_ip"
            echo ""
            
            if ! confirm "Continue anyway?"; then
                error "FQDN verification aborted"
            fi
        fi
        return 1
    fi
    
    success "FQDN verification successful!"
    return 0
}

# Check if domain is using Cloudflare
check_cloudflare() {
    local fqdn="$1"
    
    if command -v dig &> /dev/null; then
        local ns=$(dig +short NS "$fqdn" | head -n1)
        
        if [[ "$ns" == *"cloudflare"* ]]; then
            warning "Domain appears to be using Cloudflare"
            warning "Make sure SSL/TLS mode is set to 'Full' or 'Full (Strict)'"
            warning "Disable Cloudflare proxy (orange cloud) for Let's Encrypt to work"
            return 0
        fi
    fi
    
    return 1
}

# Install DNS tools if missing
install_dns_tools() {
    if ! command -v dig &> /dev/null; then
        output "Installing DNS tools..."
        
        if command -v apt &> /dev/null; then
            apt install -y dnsutils
        elif command -v yum &> /dev/null; then
            yum install -y bind-utils
        fi
    fi
}

# Export functions
export -f verify_fqdn_format
export -f get_public_ip
export -f resolve_fqdn
export -f verify_fqdn
export -f check_cloudflare
export -f install_dns_tools
