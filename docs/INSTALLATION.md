# Installation Guide

## Prerequisites

Before installing Trexzactyl Panel, ensure you have:

- A fresh Ubuntu 20.04/22.04/24.04 or Debian 11/12 server
- Root access to the server
- A domain name pointing to your server's IP address
- At least 2GB RAM
- At least 10GB free disk space

## Quick Installation

### One-Line Install

Run the following command as root:

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/install.sh)
```

### Manual Installation

1. Download the installer:
```bash
curl -Lo install.sh https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/install.sh
```

2. Make it executable:
```bash
chmod +x install.sh
```

3. Run the installer:
```bash
./install.sh
```

## Installation Process

The installer will prompt you for the following information:

### Domain Configuration
- **Domain name**: Your panel's domain (e.g., panel.example.com)
- **SSL setup**: Whether to automatically configure Let's Encrypt SSL
- **Email** (optional): Email for Let's Encrypt notifications

### Database Configuration
- **Database name**: Name for the panel database (default: panel)
- **Database username**: Username for database access (default: trexzactyl)
- **Database password**: Password for database user (auto-generated if left empty)

### Admin User (Optional)
- **Email**: Admin email address
- **Username**: Admin username
- **First name**: Admin first name
- **Last name**: Admin last name
- **Password**: Admin password

## What Gets Installed

The installer will automatically install and configure:

1. **System Packages**
   - PHP 8.1 with all required extensions
   - MariaDB database server
   - Nginx web server
   - Redis for caching and queues
   - Node.js and NPM for asset compilation
   - Composer for PHP dependencies
   - Certbot for SSL certificates

2. **Trexzactyl Panel**
   - Latest version from GitHub
   - All PHP and JavaScript dependencies
   - Database with migrations and seeds
   - Compiled frontend assets

3. **Services**
   - Queue worker (systemd service)
   - Cron job for Laravel scheduler
   - Nginx with SSL configuration
   - Redis server

4. **Security**
   - SSL/TLS certificates (if configured)
   - Proper file permissions
   - Secure database configuration

## Post-Installation

After installation completes:

1. **Access your panel**:
   - Navigate to `https://your-domain.com`
   - Log in with your admin credentials

2. **Configure panel settings**:
   - Go to Admin Panel → Settings
   - Configure email settings (SMTP)
   - Set up any additional options

3. **Add game servers**:
   - Configure nodes (server locations)
   - Add servers for your users

## Troubleshooting

### Installation Fails

If installation fails:

1. Check the error message
2. Ensure your OS is supported
3. Verify you have root access
4. Check internet connectivity
5. Try running the installer again

### SSL Certificate Fails

If SSL certificate generation fails:

1. Verify your domain points to the server IP
2. Ensure ports 80 and 443 are open
3. Try running Certbot manually:
   ```bash
   certbot --nginx -d your-domain.com
   ```

### Service Won't Start

If the queue worker service fails:

1. Check the logs:
   ```bash
   journalctl -u trexzactyl -f
   ```

2. Verify database connection in `.env`
3. Ensure proper file permissions:
   ```bash
   chown -R www-data:www-data /var/www/trexzactyl
   ```

### Database Connection Errors

If you see database errors:

1. Verify database credentials in `/var/www/trexzactyl/.env`
2. Test database connection:
   ```bash
   mysql -u trexzactyl -p -h 127.0.0.1 panel
   ```
3. Ensure MariaDB is running:
   ```bash
   systemctl status mariadb
   ```

## Manual Steps

### Creating Additional Admin Users

```bash
cd /var/www/trexzactyl
php artisan p:user:make
```

### Updating the Panel

Use the update script:
```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/update.sh)
```

### Viewing Logs

- **Panel logs**: `/var/www/trexzactyl/storage/logs/laravel.log`
- **Nginx access**: `/var/log/nginx/trexzactyl.access.log`
- **Nginx errors**: `/var/log/nginx/trexzactyl.error.log`
- **Queue worker**: `journalctl -u trexzactyl -f`

## Firewall Configuration

If using a firewall, ensure these ports are open:

- **80/tcp**: HTTP (for Let's Encrypt validation)
- **443/tcp**: HTTPS (for panel access)
- **3306/tcp**: MySQL (only if accessing externally - not recommended)

Example with UFW:
```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

## Next Steps

- [Configure Email Settings](EMAIL.md)
- [Add Your First Node](NODES.md)
- [Security Best Practices](SECURITY.md)
- [Backup Guide](BACKUP.md)

## Support

If you encounter issues:

1. Check the [troubleshooting section](#troubleshooting)
2. Search existing [GitHub Issues](https://github.com/YOUR-USERNAME/trexzactyl-installer/issues)
3. Create a new issue with detailed information
4. Join the community Discord (if available)
