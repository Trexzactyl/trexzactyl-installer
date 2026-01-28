# Troubleshooting Guide

This guide covers common issues and their solutions for Trexzactyl Panel.

## Installation Issues

### Error: "This script must be run as root"

**Problem**: Script requires root privileges.

**Solution**:
```bash
sudo su
bash install.sh
```

### Error: "Unsupported OS"

**Problem**: Your operating system is not supported.

**Solution**: Use a supported OS:
- Ubuntu 20.04, 22.04, or 24.04
- Debian 11 or 12

### Error: "Cannot detect OS"

**Problem**: `/etc/os-release` file is missing.

**Solution**: This is unusual. Verify your OS installation or manually install required packages.

### Installation Hangs

**Problem**: Script appears frozen during installation.

**Solution**:
1. Wait patiently (some steps take time)
2. Check your internet connection
3. Press Ctrl+C and restart the installer
4. Check system resources (RAM, disk space)

## Database Issues

### Error: "Access denied for user"

**Problem**: Database credentials are incorrect.

**Solution**:
```bash
# Check credentials in .env file
cat /var/www/trexzactyl/.env | grep DB_

# Test database connection
mysql -u trexzactyl -p -h 127.0.0.1 panel

# Reset database password if needed
mysql -u root
ALTER USER 'trexzactyl'@'127.0.0.1' IDENTIFIED BY 'newpassword';
FLUSH PRIVILEGES;
```

### Error: "SQLSTATE[HY000] [2002] Connection refused"

**Problem**: MariaDB service is not running.

**Solution**:
```bash
# Check MariaDB status
systemctl status mariadb

# Start MariaDB
systemctl start mariadb

# Enable on boot
systemctl enable mariadb
```

### Error: "Too many connections"

**Problem**: Database connection limit reached.

**Solution**:
```bash
# Edit MariaDB config
nano /etc/mysql/mariadb.conf.d/50-server.cnf

# Add under [mysqld]:
max_connections = 500

# Restart MariaDB
systemctl restart mariadb
```

## Web Server Issues

### Error: "502 Bad Gateway"

**Problem**: PHP-FPM is not running or misconfigured.

**Solution**:
```bash
# Check PHP-FPM status
systemctl status php8.1-fpm

# Restart PHP-FPM
systemctl restart php8.1-fpm

# Check Nginx error log
tail -f /var/log/nginx/trexzactyl.error.log
```

### Error: "404 Not Found"

**Problem**: Nginx configuration issue or missing files.

**Solution**:
```bash
# Verify panel files exist
ls -la /var/www/trexzactyl/public

# Check Nginx config
nginx -t

# Verify site is enabled
ls -la /etc/nginx/sites-enabled/

# Restart Nginx
systemctl restart nginx
```

### Error: "500 Internal Server Error"

**Problem**: Application error, usually permissions or configuration.

**Solution**:
```bash
# Check Laravel logs
tail -f /var/www/trexzactyl/storage/logs/laravel.log

# Fix permissions
chown -R www-data:www-data /var/www/trexzactyl
chmod -R 755 /var/www/trexzactyl/storage
chmod -R 755 /var/www/trexzactyl/bootstrap/cache

# Clear caches
cd /var/www/trexzactyl
php artisan config:clear
php artisan cache:clear
php artisan view:clear
```

## SSL/Certificate Issues

### Error: "SSL certificate problem"

**Problem**: SSL certificate is invalid or expired.

**Solution**:
```bash
# Renew certificate
certbot renew

# Or reconfigure for your domain
certbot --nginx -d panel.example.com
```

### Error: "Challenge failed"

**Problem**: Let's Encrypt cannot verify domain ownership.

**Solution**:
1. Verify domain DNS points to server IP
2. Ensure port 80 is open and accessible
3. Check firewall rules:
   ```bash
   ufw status
   ufw allow 80/tcp
   ufw allow 443/tcp
   ```

### Error: "Rate limit exceeded"

**Problem**: Too many certificate requests.

**Solution**: Wait one week before requesting again, or use staging environment for testing.

## Queue Worker Issues

### Queue Worker Not Processing Jobs

**Problem**: Service is not running or crashed.

**Solution**:
```bash
# Check service status
systemctl status trexzactyl

# View logs
journalctl -u trexzactyl -f

# Restart service
systemctl restart trexzactyl

# If it keeps crashing, check Laravel logs
tail -f /var/www/trexzactyl/storage/logs/laravel.log
```

### High Memory Usage

**Problem**: Queue worker consuming too much memory.

**Solution**:
```bash
# Edit service file
nano /etc/systemd/system/trexzactyl.service

# Add memory limit to ExecStart:
ExecStart=/usr/bin/php /var/www/trexzactyl/artisan queue:work --memory=512 --sleep=3 --tries=3

# Reload and restart
systemctl daemon-reload
systemctl restart trexzactyl
```

## Performance Issues

### Slow Page Load Times

**Solutions**:

1. **Enable OPcache**:
```bash
# Edit PHP config
nano /etc/php/8.1/fpm/php.ini

# Enable OPcache
opcache.enable=1
opcache.memory_consumption=128
opcache.max_accelerated_files=10000

# Restart PHP-FPM
systemctl restart php8.1-fpm
```

2. **Optimize Redis**:
```bash
# Edit Redis config
nano /etc/redis/redis.conf

# Adjust settings
maxmemory 256mb
maxmemory-policy allkeys-lru

# Restart Redis
systemctl restart redis-server
```

3. **Enable Gzip in Nginx**:
```bash
# Edit Nginx config
nano /etc/nginx/nginx.conf

# Add in http block:
gzip on;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

# Restart Nginx
systemctl restart nginx
```

### High Server Load

**Solutions**:

1. Check for runaway processes:
```bash
top
htop
```

2. Optimize database queries:
```bash
# Enable slow query log
nano /etc/mysql/mariadb.conf.d/50-server.cnf

# Add:
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

systemctl restart mariadb
```

## Permission Issues

### Error: "Permission denied"

**Solution**:
```bash
# Fix ownership
chown -R www-data:www-data /var/www/trexzactyl

# Fix permissions
find /var/www/trexzactyl -type f -exec chmod 644 {} \;
find /var/www/trexzactyl -type d -exec chmod 755 {} \;

# Special permissions for storage and cache
chmod -R 755 /var/www/trexzactyl/storage
chmod -R 755 /var/www/trexzactyl/bootstrap/cache
```

## Migration Issues

### Error: "Migration table not found"

**Solution**:
```bash
cd /var/www/trexzactyl
php artisan migrate:install
php artisan migrate --seed --force
```

### Error: "Duplicate column"

**Problem**: Migration already ran or database is not clean.

**Solution**:
```bash
# Check migration status
php artisan migrate:status

# Rollback last migration
php artisan migrate:rollback

# Or reset all migrations (DANGER: Deletes all data)
php artisan migrate:fresh --seed --force
```

## Asset Compilation Issues

### Error: "npm ERR! peer dependency"

**Solution**:
```bash
cd /var/www/trexzactyl
rm -rf node_modules package-lock.json
npm install --legacy-peer-deps
npm run build
```

### Error: "JavaScript heap out of memory"

**Solution**:
```bash
# Increase Node.js memory limit
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build
```

## Email Issues

### Emails Not Sending

**Solutions**:

1. Check mail configuration in `.env`:
```bash
cat /var/www/trexzactyl/.env | grep MAIL_
```

2. Test email:
```bash
cd /var/www/trexzactyl
php artisan tinker
Mail::raw('Test email', function($msg) {
    $msg->to('test@example.com')->subject('Test');
});
```

3. Check logs:
```bash
tail -f /var/www/trexzactyl/storage/logs/laravel.log
```

## Login Issues

### Cannot Login as Admin

**Solution**:
```bash
# Reset password
cd /var/www/trexzactyl
php artisan p:user:make

# Or reset existing user's password
php artisan tinker
$user = User::where('email', 'admin@example.com')->first();
$user->password = Hash::make('newpassword');
$user->save();
```

### "Too Many Login Attempts"

**Solution**: Wait 60 minutes or clear rate limit:
```bash
cd /var/www/trexzactyl
php artisan cache:clear
```

## Getting More Help

### Enable Debug Mode (Development Only)

**WARNING**: Never enable debug mode in production!

```bash
nano /var/www/trexzactyl/.env

# Change:
APP_DEBUG=false
# To:
APP_DEBUG=true

# Don't forget to disable it after debugging!
```

### View Logs

```bash
# Laravel logs
tail -f /var/www/trexzactyl/storage/logs/laravel.log

# Nginx access logs
tail -f /var/log/nginx/trexzactyl.access.log

# Nginx error logs
tail -f /var/log/nginx/trexzactyl.error.log

# Queue worker logs
journalctl -u trexzactyl -f

# System logs
journalctl -xe
```

### Check Service Status

```bash
systemctl status nginx
systemctl status php8.1-fpm
systemctl status mariadb
systemctl status redis-server
systemctl status trexzactyl
```

### Check System Resources

```bash
# Disk space
df -h

# Memory usage
free -h

# CPU usage
top

# Process list
ps aux | grep -E 'nginx|php|mysql'
```

## Still Need Help?

If you're still experiencing issues:

1. Check [GitHub Issues](https://github.com/trexzactyl/trexzactyl/issues)
2. Search for your error message
3. Create a new issue with:
   - Detailed description
   - Error messages
   - Log outputs
   - OS and version info
   - Steps to reproduce
