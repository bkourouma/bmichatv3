# 🚀 BMI Chat v2 Deployment Guide

## 📋 Prerequisites

### Server Requirements
- Linux VPS (Ubuntu 20.04+ recommended)
- SSH access to the server
- At least 2GB RAM
- At least 10GB free disk space
- Domain name (optional but recommended)

### Required Software
- Docker
- Docker Compose
- Git

## 🔧 Step-by-Step Deployment

### Step 1: Connect to Your Server

```bash
ssh root@your-server-ip
```

### Step 2: Install Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git unzip software-properties-common

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Log out and back in for Docker group changes
exit
ssh root@your-server-ip
```

### Step 3: Create Project Directory

```bash
# Create project directory
sudo mkdir -p /opt/bmichat
sudo chown $USER:$USER /opt/bmichat
cd /opt/bmichat
```

### Step 4: Download and Run Deployment Script

```bash
# Download the deployment script
wget https://raw.githubusercontent.com/bkourouma/bmichatv2/main/auto-deploy.sh

# Make it executable
chmod +x auto-deploy.sh

# Run the deployment
./auto-deploy.sh
```

### Step 5: Configure Environment Variables

```bash
# Edit the environment file
nano .env
```

**Required Configuration:**
```bash
# OpenAI Configuration (REQUIRED)
OPENAI_API_KEY=your_actual_openai_api_key_here

# Security (REQUIRED)
SECRET_KEY=your_long_random_secret_key_here

# Environment
ENVIRONMENT=production
DEBUG=false

# CORS Settings (update with your domain)
CORS_ORIGINS=["https://yourdomain.com","http://yourdomain.com"]
```

### Step 6: Deploy Application

```bash
# Deploy the application
docker-compose up -d --build
```

### Step 7: Verify Deployment

```bash
# Check if services are running
docker-compose ps

# Test health endpoint
curl http://localhost:3006/health

# Test frontend
curl http://localhost:8095
```

## 🌐 Domain Configuration (Optional)

### Step 8: Configure Domain

1. **Point your domain** to your server's IP address
2. **Update CORS settings** in `.env` file with your domain
3. **Restart services**:
   ```bash
   docker-compose restart
   ```

### Step 9: Setup SSL (Optional)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d yourdomain.com --non-interactive --agree-tos --email your-email@domain.com
```

## 📊 Monitoring and Maintenance

### Check Service Status
```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f

# Check specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Update Application
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Backup Data
```bash
# Create backup
mkdir -p /opt/backups
tar -czf /opt/backups/bmichat_$(date +%Y%m%d_%H%M%S).tar.gz data/
```

## 🔧 Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   sudo netstat -tulpn | grep :3006
   sudo kill -9 <PID>
   ```

2. **Docker permission issues**
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

3. **Build failures**
   ```bash
   docker system prune -a
   docker-compose build --no-cache
   ```

4. **Environment variables not loaded**
   ```bash
   # Check .env file
   cat .env
   
   # Restart services
   docker-compose restart
   ```

### Health Checks

```bash
# Backend health
curl http://localhost:3006/health

# Frontend health
curl http://localhost:8095

# API documentation
curl http://localhost:3006/docs
```

## 📈 Performance Optimization

### Production Settings
```bash
# In .env file
API_WORKERS=4
LOG_LEVEL=INFO
DEBUG=false
ENVIRONMENT=production
```

### Resource Monitoring
```bash
# Monitor container resources
docker stats

# Check disk usage
df -h

# Monitor memory usage
free -h
```

## 🔒 Security Checklist

- [ ] Change default passwords
- [ ] Use strong SECRET_KEY
- [ ] Configure firewall
- [ ] Enable SSL/TLS
- [ ] Regular security updates
- [ ] Monitor logs for suspicious activity
- [ ] Backup data regularly

## 📞 Support

If you encounter issues:

1. Check the logs: `docker-compose logs -f`
2. Verify environment variables: `cat .env`
3. Test endpoints: `curl http://localhost:3006/health`
4. Check Docker status: `docker-compose ps`

## 🎉 Success!

Your BMI Chat application should now be running at:
- **Frontend**: http://your-server-ip:8095
- **Backend API**: http://your-server-ip:3006
- **API Documentation**: http://your-server-ip:3006/docs
- **Health Check**: http://your-server-ip:3006/health

---

**🎉 Your BMI Chat application is now deployed and ready to use!** 