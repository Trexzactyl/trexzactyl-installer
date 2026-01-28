# Project Structure

This document describes the structure of the Trexzactyl Panel Installer project.

## Directory Layout

```
trexzactyl-installer/
├── .github/
│   └── workflows/
│       └── shellcheck.yml      # GitHub Actions workflow for linting
├── docs/
│   ├── INSTALLATION.md         # Detailed installation guide
│   ├── TROUBLESHOOTING.md      # Common issues and solutions
│   ├── UPDATE.md               # Update instructions
│   └── STRUCTURE.md            # This file
├── install.sh                  # Main installation script
├── update.sh                   # Panel update script
├── uninstall.sh                # Panel removal script
├── test.sh                     # Installation verification script
├── README.md                   # Project overview
├── QUICK_START.md              # Quick start guide
├── CHANGELOG.md                # Version history
├── CONTRIBUTING.md             # Contribution guidelines
├── LICENSE                     # MIT License
└── .gitignore                  # Git ignore rules
```

## Script Descriptions

### install.sh (Main Installer)
- **Purpose**: Automated installation of Trexzactyl Panel
- **Features**:
  - OS detection and validation
  - Interactive configuration prompts
  - Dependency installation
  - Database setup
  - Web server configuration
  - SSL certificate generation
  - Panel installation and configuration
  - Service setup
  - Admin user creation

### update.sh (Updater)
- **Purpose**: Update existing Trexzactyl Panel installation
- **Features**:
  - Automatic backup creation
  - Maintenance mode activation
  - Git pull latest changes
  - Dependency updates
  - Database migrations
  - Asset recompilation
  - Cache clearing
  - Service restart

### uninstall.sh (Uninstaller)
- **Purpose**: Complete removal of Trexzactyl Panel
- **Features**:
  - Service stoppage
  - File removal
  - Database cleanup
  - SSL certificate removal
  - Nginx configuration removal
  - Cron job cleanup
  - Optional dependency removal

### test.sh (Test Suite)
- **Purpose**: Verify installation integrity
- **Tests**:
  - Directory and file existence
  - Service status checks
  - Database connectivity
  - File permissions
  - Configuration validation
  - SSL configuration
  - Queue worker status
  - Cron job verification
  - System resources

## Documentation

### README.md
- Project overview
- Features list
- Installation command
- Requirements
- Support information

### QUICK_START.md
- Quick installation guide
- Common commands
- Troubleshooting tips
- Pro tips

### docs/INSTALLATION.md
- Comprehensive installation guide
- Step-by-step instructions
- Configuration options
- Post-installation steps
- Troubleshooting

### docs/UPDATE.md
- Update procedures
- Backup instructions
- Rollback steps
- Version-specific updates

### docs/TROUBLESHOOTING.md
- Common issues
- Error messages
- Solutions
- Debugging commands
- Log locations

### CONTRIBUTING.md
- Contribution guidelines
- Code standards
- Testing requirements
- Pull request process

### CHANGELOG.md
- Version history
- Feature additions
- Bug fixes
- Breaking changes

## Key Functions

### install.sh Functions
- `check_root()` - Verify root privileges
- `detect_os()` - Identify OS and version
- `get_user_input()` - Interactive configuration
- `install_dependencies()` - Install required packages
- `configure_database()` - Setup MariaDB
- `install_panel()` - Clone and setup panel
- `configure_panel()` - Configure environment
- `configure_webserver()` - Setup Nginx
- `configure_ssl()` - Generate SSL certificates
- `setup_queue_worker()` - Configure systemd service
- `setup_cron()` - Add Laravel scheduler
- `create_admin_user()` - Create admin account

### Common Patterns

#### Error Handling
```bash
set -e  # Exit on error
error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}
```

#### Service Management
```bash
systemctl enable service_name
systemctl start service_name
systemctl status service_name
```

#### File Permissions
```bash
chown -R www-data:www-data /var/www/trexzactyl
chmod -R 755 storage bootstrap/cache
```

## Configuration Files

### Panel Configuration
- `/var/www/trexzactyl/.env` - Environment configuration
- `/var/www/trexzactyl/config/` - Laravel configs

### Web Server
- `/etc/nginx/sites-available/trexzactyl.conf` - Nginx config
- `/etc/nginx/sites-enabled/trexzactyl.conf` - Enabled site

### Services
- `/etc/systemd/system/trexzactyl.service` - Queue worker

### SSL
- `/etc/letsencrypt/live/domain/` - SSL certificates

## Log Locations

- **Panel**: `/var/www/trexzactyl/storage/logs/laravel.log`
- **Nginx Access**: `/var/log/nginx/trexzactyl.access.log`
- **Nginx Error**: `/var/log/nginx/trexzactyl.error.log`
- **Queue Worker**: `journalctl -u trexzactyl`
- **PHP-FPM**: `/var/log/php8.1-fpm.log`

## Development

### Testing Changes
```bash
# Syntax check
bash -n script.sh

# Run in test environment
vagrant up
vagrant ssh
sudo bash install.sh
```

### Adding Features
1. Create feature branch
2. Implement changes
3. Test thoroughly
4. Update documentation
5. Submit pull request

## Maintenance

### Regular Updates
- Monitor GitHub for new releases
- Test updates in staging
- Apply to production
- Verify functionality

### Security
- Keep scripts updated
- Follow security best practices
- Use secure passwords
- Enable firewall
- Regular backups

## Support

For questions or issues:
- Check documentation first
- Search existing issues
- Create detailed bug reports
- Join community discussions
