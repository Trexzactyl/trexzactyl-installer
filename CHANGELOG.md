# Changelog

All notable changes to the Trexzactyl Panel Installer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-29

### Added
- Initial release of Trexzactyl Panel Installer
- Automated installation script with interactive prompts
- Support for Ubuntu 20.04, 22.04, 24.04
- Support for Debian 11, 12
- Automatic SSL certificate generation with Let's Encrypt
- Database setup and configuration
- Nginx web server configuration
- Queue worker setup with systemd service
- Redis cache server configuration
- Frontend asset compilation
- Admin user creation during installation
- Update script for seamless panel updates
- Uninstall script for complete removal
- Test script to verify installation
- Comprehensive documentation:
  - Installation guide
  - Update guide
  - Troubleshooting guide
  - Contributing guidelines
- GitHub workflow for ShellCheck linting
- MIT License

### Features
- One-line installation command
- Interactive configuration prompts
- Automatic dependency installation
- Database migrations and seeding
- Proper file permissions setup
- Service management (systemd)
- Cron job configuration
- SSL/TLS support
- Backup creation during updates
- Maintenance mode during updates
- Comprehensive error handling
- Colored output for better readability

### Security
- Secure password generation
- Proper file permissions
- SSL/TLS encryption
- Database user with limited privileges
- No hardcoded credentials

## [Unreleased]

### Planned Features
- Support for more Linux distributions
- Docker installation option
- Automatic backup scheduling
- Health check monitoring
- Multi-server support
- Custom theme installation
- Plugin management
- Rollback functionality
- Configuration validation
- Pre-flight checks

### Ideas for Future Releases
- Web-based installer UI
- Installation progress tracking
- Email notifications
- Telegram notifications
- Automated testing suite
- Performance optimization tools
- Migration from Pterodactyl
- Custom repository support

---

## Version History

- **v1.0.0** (2026-01-29) - Initial Release
