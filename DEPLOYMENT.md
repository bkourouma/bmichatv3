# 🚀 BMI Chat Deployment Guide

This guide covers deployment for both local development and production on Hostinger VPS.

## 📋 Prerequisites

### For Local Development
- Docker and Docker Compose
- Git
- Text editor

### For Hostinger VPS
- Hostinger VPS with Docker support
- Domain name (optional but recommended)
- SSH access to VPS

## 🔧 Environment Setup

### 1. Environment Configuration

Copy the example environment file and configure it:

```bash
cp env.example .env
nano .env
```

**Required Environment Variables:**
```bash
# OpenAI API Key (Required)
OPENAI_API_KEY=your_openai_api_key_here

# Secret Key (Required - generate a random one)
SECRET_KEY=your_long_random_secret_key_here

# Environment
ENVIRONMENT=development  # or production
DEBUG=true              # false for production
```

**For Production (Hostinger VPS):**
```bash
ENVIRONMENT=production
DEBUG=false
CORS_ORIGINS=["https://yourdomain.com","https://www.yourdomain.com"]
```

## 🐳 Local Development

### Quick Start

1. **Start development environment:**
```bash
./deploy.sh dev
```

2. **Access the application:**
- Backend API: http://localhost:3006
- Frontend: http://localhost:3003
- API Documentation: http://localhost:3006/docs

3. **View logs:**
```bash
docker-compose -f docker-compose.dev.yml logs -f
```

4. **Stop services:**
```bash
docker-compose -f docker-compose.dev.yml down
```

### Development Features

- **Hot Reload**: Code changes are automatically reflected
- **Debug Mode**: Detailed logging and error messages
- **Database Viewer**: Access at http://localhost:8080 (optional)
- **Log Viewer**: Access at http://localhost:9999 (optional)

To enable optional tools:
```bash
docker-compose -f docker-compose.dev.yml --profile dev-tools up -d
```

## 🧪 Testing

### Test All Endpoints

Run the comprehensive endpoint test:

```bash
chmod +x test-endpoints.sh
./test-endpoints.sh
```

This will test:
- Health checks
- API endpoints
- Chat functionality
- Document management
- Search capabilities
- Widget endpoints
- Analytics
- Error handling

### Manual Testing

1. **Health Check:**
```bash
curl http://localhost:3006/health
```

2. **API Documentation:**
```bash
curl http://localhost:3006/docs
```

3. **Chat Test:**
```bash
curl -X POST http://localhost:3006/api/v1/chat/send \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello, how are you?"}'
```

## 🌐 Production Deployment (Hostinger VPS)

### 1. Server Preparation

**Connect to your VPS:**
```bash
ssh root@your-vps-ip
```

**Install Docker (if not already installed):**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

**Install Docker Compose:**
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Application Deployment

**Clone the repository:**
```bash
git clone https://github.com/your-username/bmichat.git
cd bmichat
```

**Configure environment:**
```bash
cp env.example .env
nano .env
```

**Update production settings:**
```bash
ENVIRONMENT=production
DEBUG=false
CORS_ORIGINS=["https://yourdomain.com"]
OPENAI_API_KEY=your_openai_api_key
SECRET_KEY=your_long_random_secret_key
```

**Deploy:**
```bash
chmod +x deploy.sh
./deploy.sh prod
```

### 3. Domain Configuration (Optional)

**Set up Nginx reverse proxy:**

Create `/etc/nginx/sites-available/bmichat`:
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:8095;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api/ {
        proxy_pass http://localhost:3006;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Enable the site:**
```bash
sudo ln -s /etc/nginx/sites-available/bmichat /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**Set up SSL (Let's Encrypt):**
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 4. Production Monitoring

**Check service status:**
```bash
docker-compose ps
```

**View logs:**
```bash
docker-compose logs -f backend
docker-compose logs -f frontend
```

**Monitor resources:**
```bash
docker stats
```

## 🔄 Updates and Maintenance

### Update Application

```bash
# Pull latest changes
git pull origin main

# Redeploy
./deploy.sh prod
```

### Backup Data

```bash
# Backup database and uploads
docker-compose exec backend tar -czf /tmp/backup-$(date +%Y%m%d).tar.gz /app/data
docker cp bmi-chat-backend:/tmp/backup-$(date +%Y%m%d).tar.gz ./backup/
```

### Restore Data

```bash
# Restore from backup
docker cp ./backup/backup-20240101.tar.gz bmi-chat-backend:/tmp/
docker-compose exec backend tar -xzf /tmp/backup-20240101.tar.gz -C /
```

## 🛠️ Troubleshooting

### Common Issues

**1. Port already in use:**
```bash
# Check what's using the port
sudo netstat -tulpn | grep :3006
# Kill the process or change port in .env
```

**2. Docker build fails:**
```bash
# Clean Docker cache
docker system prune -a
# Rebuild
docker-compose build --no-cache
```

**3. Permission issues:**
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
chmod +x deploy.sh test-endpoints.sh
```

**4. Environment variables not loaded:**
```bash
# Check .env file exists and is readable
ls -la .env
cat .env
```

### Health Checks

**Backend health:**
```bash
curl http://localhost:3006/health
```

**Frontend health:**
```bash
curl http://localhost:8095
```

**Database connectivity:**
```bash
docker-compose exec backend python -c "from app.core.database import engine; print('Database OK')"
```

## 📊 Monitoring and Logs

### Log Locations

- **Application logs:** `logs/app.log`
- **Docker logs:** `docker-compose logs -f`
- **Nginx logs:** `/var/log/nginx/`

### Performance Monitoring

```bash
# Monitor container resources
docker stats

# Check disk usage
df -h

# Monitor memory usage
free -h
```

## 🔒 Security Considerations

### Production Security Checklist

- [ ] Change default passwords
- [ ] Use strong SECRET_KEY
- [ ] Configure firewall
- [ ] Enable SSL/TLS
- [ ] Regular security updates
- [ ] Monitor logs for suspicious activity
- [ ] Backup data regularly

### Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

## 📞 Support

If you encounter issues:

1. Check the logs: `docker-compose logs -f`
2. Verify environment variables: `cat .env`
3. Test endpoints: `./test-endpoints.sh`
4. Check Docker status: `docker-compose ps`

For additional help, check the main README.md or create an issue in the repository. 