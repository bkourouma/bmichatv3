# 🚀 BMI Chat Simple Deployment Script (PowerShell)
# Deploy to GitHub and VPS

# Configuration
$GIT_REPO = "https://github.com/bkourouma/bmichatv2.git"
$VPS_IP = "147.93.44.169"
$VPS_USER = "root"
$DOMAIN = "bmi.engage-360.net"

# Colors
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

function Write-Status {
    param([string]$Message)
    Write-Host "$BLUE[INFO]$NC $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "$GREEN[SUCCESS]$NC $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "$YELLOW[WARNING]$NC $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "$RED[ERROR]$NC $Message"
}

# Step 1: Clean repository for GitHub
function Clean-ForGitHub {
    Write-Status "Cleaning repository for GitHub..."
    
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
    
    Write-Success "Repository cleaned"
}

# Step 2: Create production files
function Create-ProductionFiles {
    Write-Status "Creating production files..."
    
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

    Write-Success "Production files created"
}

# Step 3: Deploy to GitHub
function Deploy-ToGitHub {
    Write-Status "Deploying to GitHub..."
    
    # Initialize git if needed
    if (-not (Test-Path ".git")) {
        git init
    }
    
    # Add all files
    git add .
    
    # Commit
    try {
        git commit -m "🚀 BMI Chat v2.0 - Production ready"
    }
    catch {
        Write-Warning "No changes to commit"
    }
    
    # Add remote if needed
    try {
        git remote get-url origin | Out-Null
    }
    catch {
        git remote add origin $GIT_REPO
    }
    
    # Force push to clean repository
    try {
        git push -f origin main
    }
    catch {
        git push -f origin master
    }
    
    Write-Success "Deployed to GitHub"
}

# Step 4: Deploy to VPS
function Deploy-ToVPS {
    Write-Status "Deploying to VPS..."
    
    # Create VPS deployment script
    $vpsScript = @"
#!/bin/bash
set -e

# Install dependencies
apt update && apt install -y docker.io docker-compose nginx git curl

# Create project directory
mkdir -p /opt/bmichat
cd /opt/bmichat

# Clone repository
git clone https://github.com/bkourouma/bmichatv2.git . || git pull

# Create directories
mkdir -p data/sqlite data/vectors data/uploads logs

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
      - "8095:80"
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
        proxy_pass http://127.0.0.1:8095;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
    }
    
    location /api/ {
        proxy_pass http://127.0.0.1:3006;
        proxy_set_header Host `$host;
        proxy_set_header X-Real-IP `$remote_addr;
        proxy_set_header X-Forwarded-For `$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto `$scheme;
    }
    
    location /health {
        proxy_pass http://127.0.0.1:3006/health;
        proxy_set_header Host `$host;
    }
}
NGINXEOF

# Enable site
ln -sf /etc/nginx/sites-available/bmi-chat /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Build and start services
docker-compose build
docker-compose up -d

echo "🎉 BMI Chat deployed successfully!"
echo "Backend: http://localhost:3006"
echo "Frontend: http://localhost:8095"
echo "Domain: http://bmi.engage-360.net"
"@

    # Save VPS script to file
    $vpsScript | Out-File -FilePath "deploy-vps.sh" -Encoding UTF8
    
    # Copy and execute on VPS
    Write-Status "Copying deployment script to VPS..."
    scp deploy-vps.sh ${VPS_USER}@${VPS_IP}:/tmp/
    
    Write-Status "Executing deployment on VPS..."
    ssh ${VPS_USER}@${VPS_IP} "bash /tmp/deploy-vps.sh"
    
    # Clean up
    Remove-Item "deploy-vps.sh" -ErrorAction SilentlyContinue
    
    Write-Success "Deployed to VPS"
}

# Main function
function Main {
    Write-Host "🚀 BMI Chat Deployment" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    
    Clean-ForGitHub
    Create-ProductionFiles
    Deploy-ToGitHub
    Deploy-ToVPS
    
    Write-Success "🎉 Deployment completed!"
    Write-Host ""
    Write-Host "📋 Summary:" -ForegroundColor Yellow
    Write-Host "  - GitHub: $GIT_REPO"
    Write-Host "  - VPS: $VPS_IP"
    Write-Host "  - Domain: $DOMAIN"
    Write-Host ""
    Write-Host "🔧 Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. SSH to VPS: ssh $VPS_USER@$VPS_IP"
    Write-Host "  2. Configure .env file with OpenAI API key"
    Write-Host "  3. Setup SSL: certbot --nginx -d $DOMAIN"
    Write-Host "  4. Test: curl http://$DOMAIN/health"
}

# Run main function
Main 