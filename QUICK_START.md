# Quick Start Guide

Get Trexzactyl Panel up and running in minutes!

## Prerequisites

✅ Fresh Ubuntu 20.04/22.04/24.04 or Debian 11/12 server  
✅ Root access  
✅ Domain name pointing to your server IP  
✅ Minimum 2GB RAM, 10GB disk space  

## Installation (One Command)

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/install.sh)
```

## What You'll Be Asked

1. **Domain name**: `panel.example.com`
2. **SSL setup**: `y` (yes, recommended)
3. **Email**: `admin@example.com` (optional, for SSL notifications)
4. **Database name**: `panel` (default, press Enter)
5. **Database user**: `trexzactyl` (default, press Enter)
6. **Database password**: Leave empty to auto-generate or enter your own
7. **Create admin user**: `y` (recommended)
8. **Admin details**: Email, username, first/last name, password

## Installation Time

⏱️ **15-20 minutes** depending on server speed and internet connection

## What Gets Installed

- ✅ PHP 8.1 with extensions
- ✅ MariaDB database
- ✅ Nginx web server
- ✅ Redis cache
- ✅ Node.js and NPM
- ✅ SSL certificate (Let's Encrypt)
- ✅ Trexzactyl Panel
- ✅ Queue worker service
- ✅ Cron jobs

## After Installation

1. **Access your panel**: `https://panel.example.com`
2. **Login** with admin credentials
3. **Configure settings** in Admin Panel
4. **Add locations and nodes**
5. **Start creating servers!**

## Common Commands

### View Queue Worker Logs
```bash
journalctl -u trexzactyl -f
```

### Restart Services
```bash
systemctl restart trexzactyl
systemctl restart nginx
```

### Clear Cache
```bash
cd /var/www/trexzactyl
php artisan cache:clear
```

### Create Additional Admin User
```bash
cd /var/www/trexzactyl
php artisan p:user:make
```

### View Panel Logs
```bash
tail -f /var/www/trexzactyl/storage/logs/laravel.log
```

## Update Panel

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/update.sh)
```

## Test Installation

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/test.sh)
```

## Uninstall

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/uninstall.sh)
```

## Troubleshooting

### Installation Failed
- Check error message
- Ensure OS is supported
- Verify root access
- Check internet connection
- Try again

### Cannot Access Panel (502 Error)
```bash
systemctl restart php8.1-fpm nginx
```

### Cannot Access Panel (500 Error)
```bash
cd /var/www/trexzactyl
chown -R www-data:www-data .
chmod -R 755 storage bootstrap/cache
php artisan cache:clear
```

### SSL Certificate Failed
```bash
# Verify domain points to server
dig +short panel.example.com

# Ensure ports are open
ufw allow 80/tcp
ufw allow 443/tcp

# Try again
certbot --nginx -d panel.example.com
```

## Need Help?

📖 [Full Documentation](docs/INSTALLATION.md)  
🐛 [Troubleshooting Guide](docs/TROUBLESHOOTING.md)  
💬 [GitHub Issues](https://github.com/YOUR-USERNAME/trexzactyl-installer/issues)  

## Pro Tips

💡 **Use a subdomain**: `panel.yourdomain.com` instead of main domain  
💡 **Enable firewall**: Only allow ports 80, 443, and SSH  
💡 **Regular backups**: Set up automated backups  
💡 **Monitor resources**: Keep an eye on CPU/RAM usage  
💡 **Keep updated**: Run updates regularly for security  

---

🎉 **Happy Gaming!** Enjoy your Trexzactyl Panel!
