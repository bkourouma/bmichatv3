#!/bin/bash

# 🚀 BMI Chat v3 Clean Deployment Script
# Deploy to new GitHub repository and clean VPS deployment

set -e

# Configuration
GIT_REPO="https://github.com/bkourouma/bmichatv3.git"
VPS_IP="147.93.44.169"
VPS_USER="root"
DOMAIN="bmi.engage-360.net"
PROJECT_DIR="/opt/bmichat"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Clean repository for GitHub
clean_for_github() {
    print_status "Cleaning repository for GitHub..."
    
    # Remove sensitive files
    find . -name ".env*" -type f -delete 2>/dev/null || true
    rm -rf data/ logs/ 2>/dev/null || true
    rm -rf frontend/node_modules/ frontend/dist/ 2>/dev/null || true
    rm -rf widget/node_modules/ widget/dist/ 2>/dev/null || true
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    rm -rf backup_* 2>/dev/null || true
    
    print_success "Repository cleaned"
}

# Step 2: Create production files
create_production_files() {
    print_status "Creating production files..."
    
    # Create .env.production.example
    cat > .env.production.example << 'EOF'
ENVIRONMENT=production
DEBUG=false
OPENAI_API_KEY=your_openai_api_key_here
SECRET_KEY=your_secret_key_here_make_it_long_and_random
CORS_ORIGINS=["https://bmi.engage-360.net","https://www.bmi.engage-360.net"]
DB_SQLITE_PATH=data/sqlite/bmi.db
VECTOR_DB_PATH=data/vectors
UPLOAD_DIR=data/uploads
EOF

    # Update .gitignore
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

    print_success "Production files created"
}

# Step 3: Deploy to GitHub
deploy_to_github() {
    print_status "Deploying to GitHub..."
    
    # Initialize git
    git init
    git add .
    git commit -m "🚀 BMI Chat v3.0 - Clean deployment ready"
    
    # Add remote
    git remote add origin "$GIT_REPO"
    
    # Force push to clean repository
    git push -f origin main
    
    print_success "Deployed to GitHub"
}

# Step 4: Clean VPS and deploy
deploy_to_vps() {
    print_status "Deploying to VPS with complete cleanup..."
    
    # Create VPS deployment script
    cat > deploy-vps-clean.sh << 'EOF'
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

# Remove Nginx configuration
rm -f /etc/nginx/sites-enabled/bmi-chat
rm -f /etc/nginx/sites-available/bmi-chat

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
EOF

    # Copy and execute on VPS
    chmod +x deploy-vps-clean.sh
    scp deploy-vps-clean.sh $VPS_USER@$VPS_IP:/tmp/
    ssh $VPS_USER@$VPS_IP "bash /tmp/deploy-vps-clean.sh"
    
    # Clean up
    rm deploy-vps-clean.sh
    
    print_success "Deployed to VPS with complete cleanup"
}

# Main function
main() {
    echo "🚀 BMI Chat v3 Clean Deployment"
    echo "================================"
    
    clean_for_github
    create_production_files
    deploy_to_github
    deploy_to_vps
    
    print_success "🎉 Clean deployment completed!"
    echo ""
    echo "📋 Summary:"
    echo "  - GitHub: $GIT_REPO"
    echo "  - VPS: $VPS_IP"
    echo "  - Domain: $DOMAIN"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. SSH to VPS: ssh $VPS_USER@$VPS_IP"
    echo "  2. Configure .env file with OpenAI API key"
    echo "  3. Setup SSL: certbot --nginx -d $DOMAIN"
    echo "  4. Test: curl http://$DOMAIN/health"
    echo ""
    echo "📝 Useful Commands:"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Restart: docker-compose restart"
    echo "  - Update: git pull && docker-compose up -d --build"
}

main 