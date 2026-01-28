# Trexzactyl Panel Installer

Automated installation script for Trexzactyl Panel - A game server management panel.

## Features

- Automated installation of all dependencies
- SSL certificate generation with Let's Encrypt
- Database setup and configuration
- Nginx web server configuration
- Queue worker and Redis setup
- User creation

## Supported OS

- Ubuntu 20.04
- Ubuntu 22.04
- Ubuntu 24.04
- Debian 11
- Debian 12

## Installation

Run the following command as root:

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/install.sh)
```

Or download and run manually:

```bash
curl -Lo install.sh https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/install.sh
chmod +x install.sh
./install.sh
```

## Usage

The installer will guide you through the installation process with prompts for:

- Domain name
- SSL certificate setup (Let's Encrypt)
- Database credentials
- Admin user creation
- Email configuration (optional)

## What Gets Installed

- PHP 8.1 with required extensions
- MariaDB/MySQL database server
- Nginx web server
- Redis server
- Composer
- Node.js and NPM
- Certbot for SSL certificates
- Trexzactyl Panel

## Post-Installation

After installation, access your panel at: `https://your-domain.com`

## Requirements

- A fresh server installation (recommended)
- Root access
- A domain name pointing to your server's IP
- At least 2GB RAM
- At least 10GB disk space

## Support

For issues and support, visit:
- [Trexzactyl GitHub](https://github.com/trexzactyl/trexzactyl)

## License

MIT License
