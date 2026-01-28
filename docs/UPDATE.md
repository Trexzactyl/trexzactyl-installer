# Update Guide

This guide explains how to update your Trexzactyl Panel to the latest version.

## Automated Update

### Using the Update Script

The easiest way to update is using the automated update script:

```bash
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/main/update.sh)
```

Or download and run manually:

```bash
curl -Lo update.sh https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/main/update.sh
chmod +x update.sh
./update.sh
```

### What the Script Does

The update script will:

1. **Create a backup** of your panel files and database
2. **Enable maintenance mode** to prevent user access
3. **Stop the queue worker** service
4. **Pull latest changes** from GitHub
5. **Update dependencies** (Composer and NPM)
6. **Rebuild frontend assets**
7. **Run database migrations**
8. **Clear all caches**
9. **Set proper permissions**
10. **Restart the queue worker**
11. **Disable maintenance mode**

### Backup Location

Backups are stored in `/var/backups/trexzactyl/` with timestamps.

## Manual Update

If you prefer to update manually:

### 1. Create Backup

```bash
# Backup files
tar -czf /var/backups/trexzactyl_backup_$(date +%Y%m%d).tar.gz /var/www/trexzactyl

# Backup database
mysqldump -u trexzactyl -p panel > /var/backups/trexzactyl_db_$(date +%Y%m%d).sql
```

### 2. Enable Maintenance Mode

```bash
cd /var/www/trexzactyl
php artisan down
```

### 3. Stop Queue Worker

```bash
systemctl stop trexzactyl
```

### 4. Pull Latest Changes

```bash
cd /var/www/trexzactyl
git stash
git pull origin main
```

### 5. Update Dependencies

```bash
# Update Composer dependencies
composer install --no-dev --optimize-autoloader

# Update NPM dependencies
npm install --legacy-peer-deps
```

### 6. Rebuild Assets

```bash
npm run build
```

### 7. Run Migrations

```bash
php artisan migrate --seed --force
```

### 8. Clear Caches

```bash
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
```

### 9. Set Permissions

```bash
chown -R www-data:www-data /var/www/trexzactyl
chmod -R 755 /var/www/trexzactyl/storage
chmod -R 755 /var/www/trexzactyl/bootstrap/cache
```

### 10. Restart Services

```bash
systemctl start trexzactyl
```

### 11. Disable Maintenance Mode

```bash
php artisan up
```

## Version-Specific Updates

### Updating from v1.x to v2.x

Check the release notes for any breaking changes:
- Database schema changes
- Configuration file changes
- Deprecated features

## Troubleshooting Updates

### Update Fails

If the update fails:

1. Check error messages carefully
2. Restore from backup if needed
3. Try manual update steps
4. Check GitHub issues for known problems

### Restore from Backup

If you need to rollback:

```bash
# Stop services
systemctl stop trexzactyl nginx

# Restore files
cd /var/www
rm -rf trexzactyl
tar -xzf /var/backups/trexzactyl_backup_YYYYMMDD.tar.gz

# Restore database
mysql -u trexzactyl -p panel < /var/backups/trexzactyl_db_YYYYMMDD.sql

# Start services
systemctl start trexzactyl nginx
```

### Migration Errors

If migrations fail:

1. Check database credentials
2. Ensure database user has proper permissions
3. Review migration error message
4. Check for conflicting data

### Asset Compilation Errors

If asset building fails:

1. Clear node_modules:
   ```bash
   rm -rf node_modules
   npm install --legacy-peer-deps
   ```

2. Try building again:
   ```bash
   npm run build
   ```

### Permission Errors

If you see permission errors:

```bash
chown -R www-data:www-data /var/www/trexzactyl
chmod -R 755 /var/www/trexzactyl/storage
chmod -R 755 /var/www/trexzactyl/bootstrap/cache
```

## Update Best Practices

1. **Always backup** before updating
2. **Test updates** on a staging server first
3. **Read release notes** before updating
4. **Schedule updates** during low-traffic periods
5. **Monitor logs** after updating

## Checking Current Version

To check your current version:

```bash
cd /var/www/trexzactyl
git describe --tags
```

Or check in the admin panel interface.

## Update Frequency

- **Security updates**: Apply immediately
- **Feature updates**: Review changelog first
- **Minor updates**: Update monthly
- **Major updates**: Plan and test carefully

## Staying Informed

To stay updated on new releases:

1. Watch the GitHub repository
2. Join the Discord community
3. Subscribe to release notifications
4. Follow the project blog

## Support

If you need help with updates:

1. Check this documentation
2. Review [troubleshooting](#troubleshooting-updates)
3. Search GitHub issues
4. Create a new issue with details
