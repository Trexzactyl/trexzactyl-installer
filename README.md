# Trexzactyl Installer Suite

Complete automated installation suite for Trexzactyl Panel ecosystem - A modern game server management platform.

## 🎯 Features

### Core Installations
- 🖥️ **Panel Installation** - Full web panel with admin interface
- 🚀 **Wings Daemon** - Game server management daemon
- 💾 **Database Host** - Dedicated database server for game servers
- 🔧 **phpMyAdmin** - Database management interface

### Additional Features
- ✨ **Modern UI** - Beautiful, interactive menu system
- 🔄 **Update System** - Automated panel updates with backups
- 🧪 **Testing Suite** - Comprehensive installation verification
- 🗑️ **Uninstaller** - Complete removal with cleanup
- 📊 **Status Monitoring** - Real-time service status checks
- 🔐 **SSL/TLS** - Automatic Let's Encrypt certificate generation

## 🎨 Modern UI

This installer features a beautiful, modern terminal UI with:
- Color-coded status indicators
- Progress bars and loading animations
- Interactive menus
- Box-drawing characters
- Intuitive navigation

## 📋 Supported OS

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Debian 11 (Bullseye)
- Debian 12 (Bookworm)

## 🚀 Quick Start

### Interactive Menu (Recommended)

```bash
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/installer.sh)
```

### Individual Installations

**Install Panel:**
```bash
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/install.sh)
```

**Install Wings:**
```bash
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/wings.sh)
```

**Install phpMyAdmin:**
```bash
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/phpmyadmin.sh)
```

**Setup Database Host:**
```bash
bash <(curl -s https://raw.githubusercontent.com/Trexzactyl/trexzactyl-installer/master/database.sh)
```

## Usage

The installer will guide you through the installation process with prompts for:

- Domain name
- SSL certificate setup (Let's Encrypt)
- Database credentials
- Admin user creation
- Email configuration (optional)

## 📦 What Gets Installed

### Panel Installation
- PHP 8.1 with required extensions
- MariaDB/MySQL database server
- Nginx web server
- Redis cache server
- Composer
- Node.js 20.x and NPM
- Certbot for SSL certificates
- Trexzactyl Panel with queue worker

### Wings Installation
- Docker and Docker Compose
- Wings daemon binary
- Systemd service configuration
- Kernel module configuration
- Firewall rules

### Database Host
- MariaDB server
- Remote access configuration
- Database management user
- Integration scripts

### phpMyAdmin
- Latest phpMyAdmin
- Nginx configuration
- HTTP authentication (optional)
- SSL support

## 📊 Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `installer.sh` | Interactive menu (recommended) | Main installer with UI |
| `install.sh` | Panel installation | Automated panel setup |
| `wings.sh` | Wings daemon | Install game server daemon |
| `phpmyadmin.sh` | Database UI | Install phpMyAdmin |
| `database.sh` | Database host | Setup dedicated DB server |
| `update.sh` | Panel updates | Update to latest version |
| `uninstall.sh` | Removal | Complete uninstallation |
| `test.sh` | Verification | Test installation |

## 🖥️ Requirements

- Fresh server installation (recommended)
- Root/sudo access
- Domain name pointing to server IP
- Minimum 2GB RAM (4GB recommended)
- Minimum 10GB disk space (20GB recommended)
- Open ports: 80 (HTTP), 443 (HTTPS)

## 📖 Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Update Guide](docs/UPDATE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Quick Start](QUICK_START.md)

## 🎯 Post-Installation

After installation:

1. **Access Panel**: `https://your-domain.com`
2. **Configure Settings**: Admin Panel → Settings
3. **Add Locations**: Create server locations
4. **Add Nodes**: Configure Wings nodes
5. **Create Servers**: Start deploying game servers!

## 🔧 Management

**View service status:**
```bash
./installer.sh
# Select option 8: Check Services
```

**Update panel:**
```bash
./update.sh
```

**Run tests:**
```bash
./test.sh
```

## 🤝 Support

- [GitHub Issues](https://github.com/Trexzactyl/trexzactyl-installer/issues)
- [Documentation](docs/)
- [Trexzactyl Panel](https://github.com/trexzactyl/trexzactyl)

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🌟 Features Comparison

| Feature | This Installer | Others |
|---------|---------------|--------|
| Modern UI | ✅ | ❌ |
| Interactive Menu | ✅ | ❌ |
| Wings Installer | ✅ | ⚠️ |
| Database Host Setup | ✅ | ❌ |
| phpMyAdmin | ✅ | ❌ |
| Test Suite | ✅ | ❌ |
| Uninstaller | ✅ | ❌ |
| Progress Indicators | ✅ | ❌ |

## 🎉 Credits

Built with ❤️ for the Trexzactyl community
