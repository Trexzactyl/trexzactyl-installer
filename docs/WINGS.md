# Wings Installation Guide

Wings is the game server daemon for Trexzactyl Panel. This guide covers installation and configuration.

## Prerequisites

- Ubuntu 20.04/22.04/24.04 or Debian 11/12
- Root access
- Domain name for the node (optional but recommended)
- Panel already installed and accessible

## Installation

### Quick Install

```bash
bash <(curl -s https://raw.githubusercontent.com/YOUR-USERNAME/trexzactyl-installer/main/wings.sh)
```

### What You'll Need

During installation, you'll be asked for:

1. **Panel URL**: Your panel's full URL (e.g., `https://panel.example.com`)
2. **Node FQDN**: This server's domain name (e.g., `node1.example.com`)
3. **SSL Configuration**: Whether to use Let's Encrypt for SSL
4. **Email**: For SSL certificate notifications (optional)
5. **Standalone Node**: Whether this is on a separate server from the panel

## What Gets Installed

- Docker and Docker runtime
- Wings daemon binary
- Systemd service for Wings
- Firewall rules
- Kernel modules and parameters
- 2GB swap file (if not present)
- SSL certificates (if configured)

## Configuration

### Automatic Configuration

After installation, you have two options:

#### Option 1: Auto-Deploy (Recommended)

1. Go to your panel: `https://panel.example.com/admin/nodes`
2. Create a new node or select existing node
3. Click on "Configuration" tab
4. Copy the auto-deploy command
5. Run it on your Wings server

#### Option 2: Manual Configuration

1. Get your node configuration from the panel
2. Edit the config file:
   ```bash
   nano /etc/trexzactyl/config.yml
   ```
3. Replace these values:
   - `YOUR_NODE_UUID_HERE`
   - `YOUR_TOKEN_ID_HERE`
   - `YOUR_TOKEN_HERE`

### Starting Wings

```bash
# Start Wings
systemctl start wings

# Enable on boot
systemctl enable wings

# Check status
systemctl status wings

# View logs
journalctl -u wings -f
```

## Firewall Configuration

Wings requires these ports to be open:

- **8080/tcp** - Wings API (panel communication)
- **2022/tcp** - Wings SFTP
- **Game Server Ports** - As configured (e.g., 25565-25600)

### UFW Example

```bash
ufw allow 22/tcp     # SSH
ufw allow 8080/tcp   # Wings API
ufw allow 2022/tcp   # Wings SFTP
ufw allow 25565:25600/tcp  # Game servers
ufw allow 25565:25600/udp  # Game servers
ufw enable
```

## SSL/TLS Configuration

### Using Let's Encrypt (Recommended)

During installation, select "yes" for SSL configuration. The installer will:
- Install Certbot
- Generate SSL certificates
- Configure Wings to use SSL
- Set up auto-renewal

### Manual SSL

If you need to configure SSL manually:

1. Obtain SSL certificates
2. Place them at:
   ```
   /etc/trexzactyl/certs/cert.pem
   /etc/trexzactyl/certs/cert.key
   ```
3. Update `/etc/trexzactyl/config.yml`:
   ```yaml
   api:
     ssl:
       enabled: true
       cert: /etc/trexzactyl/certs/cert.pem
       key: /etc/trexzactyl/certs/cert.key
   ```
4. Restart Wings: `systemctl restart wings`

## Docker Configuration

Wings uses Docker to manage game servers. The installer configures Docker automatically.

### Docker Storage

By default, Docker stores data in `/var/lib/docker`. If you need more space:

```bash
# Stop Docker
systemctl stop docker

# Move Docker data
mv /var/lib/docker /mnt/storage/docker

# Create symlink
ln -s /mnt/storage/docker /var/lib/docker

# Start Docker
systemctl start docker
```

## Troubleshooting

### Wings Won't Start

```bash
# Check logs
journalctl -u wings -f

# Common issues:
# 1. Config file errors
nano /etc/trexzactyl/config.yml

# 2. Docker not running
systemctl status docker
systemctl start docker

# 3. Port conflicts
netstat -tulpn | grep -E '8080|2022'
```

### Connection Issues

```bash
# Test Wings API
curl -k https://node.example.com:8080

# Check firewall
ufw status

# Verify config
cat /etc/trexzactyl/config.yml
```

### Docker Errors

```bash
# Check Docker status
systemctl status docker

# View Docker logs
journalctl -u docker -f

# Restart Docker
systemctl restart docker
```

### SSL Certificate Errors

```bash
# Check certificate
openssl x509 -in /etc/trexzactyl/certs/cert.pem -text -noout

# Renew Let's Encrypt certificate
certbot renew

# Update symlinks
ln -sf /etc/letsencrypt/live/node.example.com/fullchain.pem /etc/trexzactyl/certs/cert.pem
ln -sf /etc/letsencrypt/live/node.example.com/privkey.pem /etc/trexzactyl/certs/cert.key
```

## Maintenance

### Update Wings

```bash
# Stop Wings
systemctl stop wings

# Download latest
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"

# Make executable
chmod u+x /usr/local/bin/wings

# Start Wings
systemctl start wings
```

### Backup Configuration

```bash
# Backup config
cp /etc/trexzactyl/config.yml /root/wings-config-backup.yml

# Backup SSL certs
tar -czf /root/wings-ssl-backup.tar.gz /etc/trexzactyl/certs/
```

### Monitor Resources

```bash
# Check disk space
df -h

# Check Docker space
docker system df

# Clean up Docker
docker system prune -a
```

## Performance Tuning

### Increase File Limits

Edit `/etc/security/limits.conf`:
```
* soft nofile 65536
* hard nofile 65536
```

### Optimize Kernel

Already configured by installer, but verify:
```bash
sysctl -p /etc/sysctl.d/99-trexzactyl.conf
```

### Monitor Performance

```bash
# CPU and RAM
htop

# Network
iftop

# Disk I/O
iotop
```

## Advanced Configuration

### Custom Ports

Edit `/etc/trexzactyl/config.yml`:
```yaml
api:
  port: 8080  # Change if needed
system:
  sftp:
    bind_port: 2022  # Change if needed
```

### Backup Settings

Configure automatic backups:
```yaml
system:
  backups:
    write_limit: 0  # 0 = unlimited
```

### Resource Limits

Configure transfer limits:
```yaml
system:
  transfers:
    download_limit: 0  # MB/s, 0 = unlimited
```

## Security Best Practices

1. **Use SSL/TLS** - Always enable SSL for production
2. **Firewall** - Restrict access to trusted IPs
3. **Regular Updates** - Keep Wings and Docker updated
4. **Monitor Logs** - Watch for suspicious activity
5. **Backup Config** - Regular configuration backups

## Uninstalling Wings

```bash
# Stop and disable service
systemctl stop wings
systemctl disable wings

# Remove Wings binary
rm /usr/local/bin/wings

# Remove configuration
rm -rf /etc/trexzactyl

# Remove Docker (optional)
apt remove --purge docker-ce docker-ce-cli containerd.io

# Remove Docker data (WARNING: Deletes all containers)
rm -rf /var/lib/docker
```

## Support

- Check logs: `journalctl -u wings -f`
- Docker logs: `journalctl -u docker -f`
- [GitHub Issues](https://github.com/YOUR-USERNAME/trexzactyl-installer/issues)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
