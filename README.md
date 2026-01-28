# Trexzactyl Installer

[![ShellCheck](https://github.com/Trexzactyl/trexzactyl-installer/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/Trexzactyl/trexzactyl-installer/actions/workflows/shellcheck.yml)
[![License](https://img.shields.io/github/license/Trexzactyl/trexzactyl-installer)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/Trexzactyl/trexzactyl-installer?include_prereleases)](https://github.com/Trexzactyl/trexzactyl-installer/releases)

Automated installation scripts for the Trexzactyl Panel ecosystem.

## Installation

**Interactive Menu:**
```bash
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/installer.sh)
```

**Direct Install:**
```bash
# Panel
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/install.sh)

# Wings Daemon
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/wings.sh)

# phpMyAdmin
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/phpmyadmin.sh)

# Database Host
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/database.sh)
```

## Features

- Panel installation with full automation
- Wings daemon with Docker support
- Database host setup for game servers
- phpMyAdmin for database management
- Modern terminal UI with progress indicators
- SSL/TLS certificate automation
- Update and uninstall scripts
- Comprehensive testing suite

## Supported Systems

| OS | Version |
|---|---|
| Ubuntu | 20.04, 22.04, 24.04 |
| Debian | 11, 12 |

## Requirements

- Fresh server installation recommended
- Root or sudo access
- Domain name (for SSL)
- Minimum 2GB RAM
- Minimum 10GB disk space

## Usage

The installer will guide you through the installation process with prompts for:

- Domain name
- SSL certificate setup (Let's Encrypt)
- Database credentials
- Admin user creation
- Email configuration (optional)

## Components

**Panel Installation:**
- PHP 8.1, MariaDB, Nginx, Redis
- Composer, Node.js, Certbot
- Queue worker service

**Wings Installation:**
- Docker and Docker Compose
- Wings daemon binary
- Systemd service
- Kernel configuration

**Database Host:**
- MariaDB with remote access
- Management tools

**phpMyAdmin:**
- Latest version with Nginx
- Optional HTTP authentication

## Scripts

| Script | Description |
|--------|-------------|
| `installer.sh` | Interactive menu |
| `install.sh` | Panel installation |
| `wings.sh` | Wings daemon |
| `phpmyadmin.sh` | Database management UI |
| `database.sh` | Database host setup |
| `update.sh` | Panel updates |
| `uninstall.sh` | Complete removal |
| `test.sh` | Installation tests |

## Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Wings Setup](docs/WINGS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Update Guide](docs/UPDATE.md)

## Support

- [Issues](https://github.com/Trexzactyl/trexzactyl-installer/issues)
- [Trexzactyl Panel](https://github.com/trexzactyl/trexzactyl)

## License

[MIT License](LICENSE)
