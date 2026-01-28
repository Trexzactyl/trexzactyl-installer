#!/bin/bash

################################################################################
# Trexzactyl Panel Test Script
# 
# Description: Test Trexzactyl Panel installation
# Author: Trexzactyl Installer Team
# License: MIT
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PANEL_PATH="/var/www/trexzactyl"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

################################################################################
# FUNCTIONS
################################################################################

output() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test functions
test_directory_exists() {
    output "Checking if panel directory exists..."
    if [ -d "$PANEL_PATH" ]; then
        pass "Panel directory exists at $PANEL_PATH"
    else
        fail "Panel directory not found at $PANEL_PATH"
    fi
}

test_files_exist() {
    output "Checking if essential files exist..."
    
    local files=(".env" "artisan" "composer.json" "package.json")
    for file in "${files[@]}"; do
        if [ -f "$PANEL_PATH/$file" ]; then
            pass "File exists: $file"
        else
            fail "File missing: $file"
        fi
    done
}

test_nginx_config() {
    output "Testing Nginx configuration..."
    
    if nginx -t &>/dev/null; then
        pass "Nginx configuration is valid"
    else
        fail "Nginx configuration has errors"
    fi
    
    if [ -f "/etc/nginx/sites-enabled/trexzactyl.conf" ]; then
        pass "Trexzactyl Nginx config is enabled"
    else
        fail "Trexzactyl Nginx config not found"
    fi
}

test_services() {
    output "Checking service status..."
    
    local services=("nginx" "php8.1-fpm" "mariadb" "redis-server" "trexzactyl")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            pass "Service $service is running"
        else
            fail "Service $service is not running"
        fi
    done
}

test_database_connection() {
    output "Testing database connection..."
    
    cd $PANEL_PATH
    if php artisan db:show &>/dev/null; then
        pass "Database connection successful"
    else
        fail "Cannot connect to database"
    fi
}

test_permissions() {
    output "Checking file permissions..."
    
    local owner=$(stat -c '%U:%G' $PANEL_PATH)
    if [ "$owner" == "www-data:www-data" ]; then
        pass "Panel directory has correct ownership"
    else
        fail "Panel directory ownership is $owner (expected: www-data:www-data)"
    fi
    
    local storage_perm=$(stat -c '%a' $PANEL_PATH/storage)
    if [ "$storage_perm" == "755" ]; then
        pass "Storage directory has correct permissions"
    else
        warn "Storage directory permissions: $storage_perm (expected: 755)"
    fi
}

test_ssl() {
    output "Checking SSL configuration..."
    
    if [ -f "/etc/nginx/sites-enabled/trexzactyl.conf" ]; then
        if grep -q "ssl_certificate" /etc/nginx/sites-enabled/trexzactyl.conf; then
            pass "SSL is configured in Nginx"
        else
            warn "SSL not configured (this is okay for development)"
        fi
    fi
}

test_queue_worker() {
    output "Checking queue worker..."
    
    if systemctl is-active --quiet trexzactyl; then
        pass "Queue worker service is running"
        
        # Check if it's actually processing
        if journalctl -u trexzactyl --since "1 minute ago" | grep -q "Processing"; then
            pass "Queue worker is actively processing jobs"
        else
            warn "Queue worker running but not processing jobs (may be normal)"
        fi
    else
        fail "Queue worker service is not running"
    fi
}

test_cron() {
    output "Checking cron job..."
    
    if crontab -l 2>/dev/null | grep -q "artisan schedule:run"; then
        pass "Laravel scheduler cron job exists"
    else
        fail "Laravel scheduler cron job not found"
    fi
}

test_composer_dependencies() {
    output "Checking Composer dependencies..."
    
    if [ -d "$PANEL_PATH/vendor" ]; then
        pass "Composer dependencies installed"
    else
        fail "Composer vendor directory not found"
    fi
}

test_npm_dependencies() {
    output "Checking NPM dependencies..."
    
    if [ -d "$PANEL_PATH/node_modules" ]; then
        pass "NPM dependencies installed"
    else
        fail "NPM node_modules directory not found"
    fi
}

test_assets() {
    output "Checking compiled assets..."
    
    if [ -d "$PANEL_PATH/public/assets" ]; then
        if [ "$(ls -A $PANEL_PATH/public/assets)" ]; then
            pass "Frontend assets are compiled"
        else
            fail "Assets directory is empty"
        fi
    else
        fail "Assets directory not found"
    fi
}

test_logs() {
    output "Checking for errors in logs..."
    
    if [ -f "$PANEL_PATH/storage/logs/laravel.log" ]; then
        local error_count=$(grep -c "ERROR" $PANEL_PATH/storage/logs/laravel.log 2>/dev/null || echo 0)
        if [ "$error_count" -gt 10 ]; then
            warn "Found $error_count errors in Laravel logs"
        else
            pass "Laravel logs look clean (errors: $error_count)"
        fi
    else
        warn "No Laravel log file found yet"
    fi
}

test_env_config() {
    output "Checking environment configuration..."
    
    if [ -f "$PANEL_PATH/.env" ]; then
        pass ".env file exists"
        
        # Check critical settings
        if grep -q "APP_KEY=base64:" $PANEL_PATH/.env; then
            pass "Application key is set"
        else
            fail "Application key not set"
        fi
        
        if grep -q "APP_URL=" $PANEL_PATH/.env; then
            pass "Application URL is set"
        else
            warn "Application URL not set"
        fi
    else
        fail ".env file not found"
    fi
}

test_php_extensions() {
    output "Checking PHP extensions..."
    
    local extensions=("curl" "mbstring" "xml" "zip" "pdo" "mysql" "bcmath" "gd" "tokenizer")
    for ext in "${extensions[@]}"; do
        if php -m | grep -q "$ext"; then
            pass "PHP extension: $ext"
        else
            fail "PHP extension missing: $ext"
        fi
    done
}

test_disk_space() {
    output "Checking disk space..."
    
    local available=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$available" -gt 5 ]; then
        pass "Sufficient disk space: ${available}GB available"
    else
        warn "Low disk space: ${available}GB available"
    fi
}

test_memory() {
    output "Checking memory..."
    
    local total_mem=$(free -m | awk 'NR==2{print $2}')
    if [ "$total_mem" -gt 1500 ]; then
        pass "Sufficient memory: ${total_mem}MB"
    else
        warn "Low memory: ${total_mem}MB (recommended: 2GB+)"
    fi
}

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    TEST SUMMARY                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! Your installation looks good.${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed. Please review the output above.${NC}"
        exit 1
    fi
}

################################################################################
# MAIN
################################################################################

main() {
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║        TREXZACTYL PANEL INSTALLATION TEST                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Run all tests
    test_directory_exists
    test_files_exist
    test_env_config
    test_permissions
    test_composer_dependencies
    test_npm_dependencies
    test_assets
    test_php_extensions
    test_nginx_config
    test_ssl
    test_services
    test_database_connection
    test_queue_worker
    test_cron
    test_logs
    test_disk_space
    test_memory
    
    print_summary
}

main
