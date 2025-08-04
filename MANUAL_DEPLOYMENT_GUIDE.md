# 🚀 Manual Deployment Guide - BMI Chat

## 📋 Overview
This guide will help you manually deploy the BMI Chat application to your GitHub repository and VPS server, following the "GUIDE DE DÉPLOIEMENT BMI CHAT" structure.

## 🔧 Prerequisites
- Git installed
- SSH access to your VPS (147.93.44.169)
- Docker and Docker Compose on VPS
- Nginx on VPS

## 📁 Step 1: Clean Repository for GitHub

### Remove sensitive files:
```bash
# Remove environment files
rm -f .env .env.local .env.production

# Remove data and logs
rm -rf data/ logs/

# Remove build artifacts
rm -rf frontend/node_modules/ frontend/dist/
rm -rf widget/node_modules/ widget/dist/

# Remove Python cache
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -name "*.pyc" -delete 2>/dev/null || true
```

### Update .gitignore:
```bash
cat > .gitignore << 'EOF'
# Environment files
.env
.env.local
.env.production

# Data and logs
data/
logs/
*.db
*.sqlite

# Python
__pycache__/
*.pyc
*.pyo

# Node.js
node_modules/
npm-debug.log*

# Build outputs
frontend/dist/
widget/dist/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Backup files
backup_*
EOF
```

## 🐙 Step 2: Deploy to GitHub

### Initialize Git (if not already done):
```bash
git init
git add .
git commit -m "🚀 BMI Chat v2.0 - Production ready"
```

### Add remote and push:
```bash
git remote add origin https://github.com/bkourouma/bmichatv2.git
git push -f origin main
```

## 🖥️ Step 3: Deploy to VPS

### SSH to your VPS:
```bash
ssh root@147.93.44.169
```

### Install dependencies:
```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Nginx
apt install -y nginx git curl
```

### Create project directory:
```bash
mkdir -p /opt/bmichat
cd /opt/bmichat
```

### Clone repository:
```bash
git clone https://github.com/bkourouma/bmichatv2.git .
```

### Create necessary directories:
```bash
mkdir -p data/sqlite data/vectors data/uploads logs
chown -R 1000:1000 data logs
```

### Create environment file:
```bash
cp .env.production.example .env
nano .env
```

**Configure your .env file with:**
```bash
ENVIRONMENT=production
DEBUG=false
OPENAI_API_KEY=your_actual_openai_api_key_here
SECRET_KEY=your_actual_secret_key_here_make_it_long_and_random
CORS_ORIGINS=["https://bmi.engage-360.net","https://www.bmi.engage-360.net"]
DB_SQLITE_PATH=data/sqlite/bmi.db
VECTOR_DB_PATH=data/vectors
UPLOAD_DIR=data/uploads
```

### Create docker-compose.yml:
```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  backend:
    build:
      context: .
      dockerfile: deployment/docker/Dockerfile.backend
    container_name: bmi-chat-backend
    ports:
      - "3006:3006"
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs
    env_file:
      - .env
    restart: unless-stopped

  frontend:
    build:
      context: ./frontend
      dockerfile: ../deployment/docker/Dockerfile.frontend
    container_name: bmi-chat-frontend
    ports:
      - "8095:80"
    depends_on:
      - backend
    restart: unless-stopped
EOF
```

### Create Nginx configuration:
```bash
cat > /etc/nginx/sites-available/bmi-chat << 'EOF'
server {
    listen 80;
    server_name bmi.engage-360.net www.bmi.engage-360.net;
    
    location / {
        proxy_pass http://127.0.0.1:8095;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:3006;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /health {
        proxy_pass http://127.0.0.1:3006/health;
        proxy_set_header Host $host;
    }
}
EOF
```

### Enable Nginx site:
```bash
ln -sf /etc/nginx/sites-available/bmi-chat /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

### Build and start services:
```bash
docker-compose build
docker-compose up -d
```

## 🔍 Step 4: Verify Deployment

### Check services:
```bash
# Check if containers are running
docker-compose ps

# Check logs
docker-compose logs -f

# Test backend
curl http://localhost:3006/health

# Test frontend
curl http://localhost:8095
```

### Test the application:
```bash
# Test health endpoint
curl http://bmi.engage-360.net/health

# Test chat API
curl -X POST http://bmi.engage-360.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "BMI-WFS"}'
```

## 🔒 Step 5: Setup SSL (Optional)

### Install Certbot:
```bash
apt install -y certbot python3-certbot-nginx
```

### Get SSL certificate:
```bash
certbot --nginx -d bmi.engage-360.net --non-interactive --agree-tos --email admin@engage-360.net
```

## 📊 Step 6: Management Commands

### Useful commands:
```bash
# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Restart services
docker-compose restart

# Update from Git
cd /opt/bmichat
git pull
docker-compose up -d --build

# Backup data
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz data/ logs/

# Check Nginx status
systemctl status nginx
nginx -t
```

## 🚨 Troubleshooting

### If containers fail to start:
```bash
# Check logs
docker-compose logs

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### If Nginx fails:
```bash
# Check Nginx configuration
nginx -t

# Check Nginx logs
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log
```

### If API doesn't respond:
```bash
# Check if backend is running
docker ps | grep bmi-chat-backend

# Check backend logs
docker-compose logs backend

# Test backend directly
curl http://localhost:3006/health
```

## ✅ Success Indicators

Your deployment is successful when:
- ✅ `curl http://localhost:3006/health` returns success
- ✅ `curl http://localhost:8095` returns HTML
- ✅ `curl http://bmi.engage-360.net/health` returns success
- ✅ `curl -X POST http://bmi.engage-360.net/api/chat -H "Content-Type: application/json" -d '{"message": "test"}'` returns a response

## 🎉 Final Notes

- **GitHub Repository**: https://github.com/bkourouma/bmichatv2.git
- **VPS Server**: 147.93.44.169
- **Domain**: bmi.engage-360.net
- **Backend API**: http://localhost:3006
- **Frontend**: http://localhost:8095

The application is now deployed and ready to use! 🚀 