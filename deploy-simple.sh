#!/bin/bash

# 🚀 BMI Chat Simple Deployment Script
# Deploy to GitHub and VPS

set -e

# Configuration
GIT_REPO="https://github.com/bkourouma/bmichatv2.git"
VPS_IP="147.93.44.169"
VPS_USER="root"
DOMAIN="bmi.engage-360.net"

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
    
    # Initialize git if needed
    if [ ! -d ".git" ]; then
        git init
    fi
    
    # Add all files
    git add .
    
    # Commit
    git commit -m "🚀 BMI Chat v2.0 - Production ready" || print_warning "No changes to commit"
    
    # Add remote if needed
    if ! git remote get-url origin > /dev/null 2>&1; then
        git remote add origin "$GIT_REPO"
    fi
    
    # Force push to clean repository
    git push -f origin main || git push -f origin master
    
    print_success "Deployed to GitHub"
}

# Step 4: Deploy to VPS
deploy_to_vps() {
    print_status "Deploying to VPS..."
    
    # Create VPS deployment script
    cat > deploy-vps.sh << 'EOF'
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
docker-compose build
docker-compose up -d

echo "🎉 BMI Chat deployed successfully!"
echo "Backend: http://localhost:3006"
echo "Frontend: http://localhost:8095"
echo "Domain: http://bmi.engage-360.net"
EOF

    # Copy and execute on VPS
    chmod +x deploy-vps.sh
    scp deploy-vps.sh $VPS_USER@$VPS_IP:/tmp/
    ssh $VPS_USER@$VPS_IP "bash /tmp/deploy-vps.sh"
    
    # Clean up
    rm deploy-vps.sh
    
    print_success "Deployed to VPS"
}

# Main function
main() {
    echo "🚀 BMI Chat Deployment"
    echo "======================"
    
    clean_for_github
    create_production_files
    deploy_to_github
    deploy_to_vps
    
    print_success "🎉 Deployment completed!"
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
}

main 