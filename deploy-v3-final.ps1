# BMI Chat v3 Final Deployment Script

Write-Host "🚀 BMI Chat v3 Clean Deployment" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Configuration
$GIT_REPO = "https://github.com/bkourouma/bmichatv3.git"
$VPS_IP = "147.93.44.169"
$VPS_USER = "root"

Write-Host "[INFO] Cleaning repository for GitHub..." -ForegroundColor Blue

# Remove sensitive files
Get-ChildItem -Path . -Name ".env*" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
if (Test-Path "data") { Remove-Item -Recurse -Force "data" -ErrorAction SilentlyContinue }
if (Test-Path "logs") { Remove-Item -Recurse -Force "logs" -ErrorAction SilentlyContinue }
if (Test-Path "frontend/node_modules") { Remove-Item -Recurse -Force "frontend/node_modules" -ErrorAction SilentlyContinue }
if (Test-Path "frontend/dist") { Remove-Item -Recurse -Force "frontend/dist" -ErrorAction SilentlyContinue }
if (Test-Path "widget/node_modules") { Remove-Item -Recurse -Force "widget/node_modules" -ErrorAction SilentlyContinue }
if (Test-Path "widget/dist") { Remove-Item -Recurse -Force "widget/dist" -ErrorAction SilentlyContinue }

# Remove Python cache
Get-ChildItem -Path . -Name "__pycache__" -Recurse -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path . -Name "*.pyc" -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "[SUCCESS] Repository cleaned" -ForegroundColor Green

Write-Host "[INFO] Creating production files..." -ForegroundColor Blue

# Create .env.production.example
@"
ENVIRONMENT=production
DEBUG=false
OPENAI_API_KEY=your_openai_api_key_here
SECRET_KEY=your_secret_key_here_make_it_long_and_random
CORS_ORIGINS=["https://bmi.engage-360.net","https://www.bmi.engage-360.net"]
DB_SQLITE_PATH=data/sqlite/bmi.db
VECTOR_DB_PATH=data/vectors
UPLOAD_DIR=data/uploads
"@ | Out-File -FilePath ".env.production.example" -Encoding UTF8

# Update .gitignore
@"
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
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8

Write-Host "[SUCCESS] Production files created" -ForegroundColor Green

Write-Host "[INFO] Deploying to GitHub..." -ForegroundColor Blue

# Initialize git
git init
git add .
git commit -m "🚀 BMI Chat v3.0 - Clean deployment ready"

# Add remote
git remote add origin $GIT_REPO

# Force push to clean repository
git push -f origin main

Write-Host "[SUCCESS] Deployed to GitHub" -ForegroundColor Green

Write-Host "[INFO] Deploying to VPS with complete cleanup..." -ForegroundColor Blue

# Create VPS deployment script
$vpsScript = @"
#!/bin/bash
set -e

echo "🧹 Cleaning VPS completely..."

# Stop and remove all BMI Chat containers
docker-compose down -v 2>/dev/null || true
docker stop bmi-chat-backend bmi-chat-frontend 2>/dev/null || true
docker rm bmi-chat-backend bmi-chat-frontend 2>/dev/null || true

# Remove BMI Chat images
docker rmi bmichat_backend bmichat_frontend 2>/dev/null || true

# Remove BMI Chat directory completely
rm -rf /opt/bmichat

# Remove existing BMI Chat configurations
rm -f /etc/nginx/sites-enabled/bmi-chat
rm -f /etc/nginx/sites-available/bmi-chat
rm -f /etc/nginx/sites-enabled/bmi.engage-360.net
rm -f /etc/nginx/sites-available/bmi.engage-360.net
rm -f /etc/nginx/sites-available/bmichat.conf

# Clean Docker system
docker system prune -f

echo "✅ VPS cleaned completely"

# Install dependencies
echo "📦 Installing dependencies..."
apt update && apt upgrade -y
apt install -y docker.io docker-compose nginx git curl wget

# Create project directory
mkdir -p /opt/bmichat
cd /opt/bmichat

# Clone repository
echo "📥 Cloning repository..."
git clone https://github.com/bkourouma/bmichatv3.git .

# Create directories
mkdir -p data/sqlite data/vectors data/uploads logs
chown -R 1000:1000 data logs

# Create .env file
if [ ! -f ".env" ]; then
    cp .env.production.example .env
    echo "Please configure your .env file with OpenAI API key"
fi

# Create docker-compose.yml
cat > docker-compose.yml << 'DOCKEREOF'
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
      - "8099:80"
    depends_on:
      - backend
    restart: unless-stopped
DOCKEREOF

# Create nginx configuration
cat > /etc/nginx/sites-available/bmi-chat << 'NGINXEOF'
server {
    listen 80;
    server_name bmi.engage-360.net www.bmi.engage-360.net;
    
    location / {
        proxy_pass http://127.0.0.1:8099;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:3006;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    location /health {
        proxy_pass http://127.0.0.1:3006/health;
        proxy_set_header Host \$host;
    }
}
NGINXEOF

# Enable site
ln -sf /etc/nginx/sites-available/bmi-chat /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Build and start services
echo "🔨 Building and starting services..."
docker-compose build --no-cache
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Test services
echo "🧪 Testing services..."
if curl -f http://localhost:3006/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend health check failed"
    docker-compose logs backend
    exit 1
fi

if curl -f http://localhost:8099 > /dev/null 2>&1; then
    echo "✅ Frontend is healthy"
else
    echo "❌ Frontend health check failed"
    docker-compose logs frontend
    exit 1
fi

echo "🎉 BMI Chat v3 deployed successfully!"
echo "Backend: http://localhost:3006"
echo "Frontend: http://localhost:8099"
echo "Domain: http://bmi.engage-360.net"
"@

# Save VPS script to file
$vpsScript | Out-File -FilePath "deploy-vps-clean.sh" -Encoding UTF8

# Copy and execute on VPS
Write-Host "[INFO] Copying deployment script to VPS..." -ForegroundColor Blue
scp deploy-vps-clean.sh ${VPS_USER}@${VPS_IP}:/tmp/

Write-Host "[INFO] Executing deployment on VPS..." -ForegroundColor Blue
ssh ${VPS_USER}@${VPS_IP} "bash /tmp/deploy-vps-clean.sh"

# Clean up
Remove-Item "deploy-vps-clean.sh" -ErrorAction SilentlyContinue

Write-Host "[SUCCESS] Deployed to VPS with complete cleanup" -ForegroundColor Green

Write-Host "[SUCCESS] 🎉 Clean deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary:" -ForegroundColor Yellow
Write-Host "  - GitHub: $GIT_REPO"
Write-Host "  - VPS: $VPS_IP"
Write-Host "  - Domain: bmi.engage-360.net"
Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. SSH to VPS: ssh $VPS_USER@$VPS_IP"
Write-Host "  2. Configure .env file with OpenAI API key"
Write-Host "  3. Setup SSL: certbot --nginx -d bmi.engage-360.net"
Write-Host "  4. Test: curl http://bmi.engage-360.net/health" 