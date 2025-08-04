#!/bin/bash

# 🚀 BMI Chat Deployment Script - GitHub + VPS
# This script handles deployment to GitHub repository and VPS server
# Following the "GUIDE DE DÉPLOIEMENT BMI CHAT" structure

set -e

# Configuration
GIT_REPO="https://github.com/bkourouma/bmichatv2.git"
VPS_IP="147.93.44.169"
VPS_USER="root"
DOMAIN="bmi.engage-360.net"
PROJECT_DIR="/opt/bmichat"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
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

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed"
        exit 1
    fi
    
    # Check SSH
    if ! command -v ssh &> /dev/null; then
        print_error "SSH is not installed"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "app/main.py" ]; then
        print_error "Please run this script from the BMI Chat project root directory"
        exit 1
    fi
    
    print_success "Prerequisites checked"
}

# Function to clean and prepare for GitHub
prepare_for_github() {
    print_status "Preparing for GitHub deployment..."
    
    # Remove sensitive files and directories
    print_status "Cleaning sensitive files..."
    
    # Remove .env files (they contain sensitive data)
    find . -name ".env*" -type f -delete 2>/dev/null || true
    
    # Remove data directory (contains database and vectors)
    rm -rf data/ 2>/dev/null || true
    
    # Remove logs directory
    rm -rf logs/ 2>/dev/null || true
    
    # Remove node_modules and build directories
    rm -rf frontend/node_modules/ 2>/dev/null || true
    rm -rf frontend/dist/ 2>/dev/null || true
    rm -rf widget/node_modules/ 2>/dev/null || true
    rm -rf widget/dist/ 2>/dev/null || true
    
    # Remove Python cache
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    
    # Remove backup files
    rm -rf backup_* 2>/dev/null || true
    
    print_success "Repository cleaned for GitHub"
}

# Function to create production environment files
create_production_env() {
    print_status "Creating production environment files..."
    
    # Create .env.production from .env.example
    if [ -f "env.example" ]; then
        cp env.example .env.production
        print_success "Created .env.production from env.example"
    fi
    
    # Create .env.production.example
    cat > .env.production.example << 'EOF'
# =============================================================================
# BMI Chat Production Environment Configuration
# =============================================================================

# =============================================================================
# Environment Settings
# =============================================================================
ENVIRONMENT=production
DEBUG=false

# =============================================================================
# API Configuration
# =============================================================================
API_HOST=0.0.0.0
API_PORT=3006
API_WORKERS=2

# =============================================================================
# CORS Settings
# =============================================================================
CORS_ORIGINS=["https://bmi.engage-360.net","https://www.bmi.engage-360.net","http://bmi.engage-360.net","http://www.bmi.engage-360.net"]

# =============================================================================
# OpenAI Configuration
# =============================================================================
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4o
OPENAI_TEMPERATURE=0.0
OPENAI_MAX_TOKENS=2000

# =============================================================================
# Database Configuration
# =============================================================================
DB_SQLITE_PATH=data/sqlite/bmi.db
VECTOR_DB_PATH=data/vectors
UPLOAD_DIR=data/uploads

# =============================================================================
# Security
# =============================================================================
SECRET_KEY=your_secret_key_here_make_it_long_and_random
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# =============================================================================
# Document Processing
# =============================================================================
CHUNK_SIZE=2000
CHUNK_OVERLAP=400
MAX_CHUNKS_PER_DOCUMENT=100
SUPPORTED_FILE_TYPES=["pdf","txt","docx","md"]

# =============================================================================
# Chat Configuration
# =============================================================================
MAX_CHAT_HISTORY=10
DEFAULT_RETRIEVAL_K=3
MAX_RETRIEVAL_K=5
CHAT_TIMEOUT_SECONDS=30

# =============================================================================
# Logging
# =============================================================================
LOG_LEVEL=INFO
LOG_FILE=logs/app.log
LOG_MAX_SIZE=10MB
LOG_BACKUP_COUNT=5

# =============================================================================
# Widget Configuration
# =============================================================================
WIDGET_DEFAULT_POSITION=right
WIDGET_DEFAULT_ACCENT_COLOR=#0056b3
WIDGET_DEFAULT_COMPANY_NAME=BMI
WIDGET_DEFAULT_ASSISTANT_NAME=Akissi
WIDGET_DEFAULT_WELCOME_MESSAGE=Bonjour! Comment puis-je vous aider?

# =============================================================================
# Performance
# =============================================================================
MAX_UPLOAD_SIZE=50MB
RATE_LIMIT_PER_MINUTE=60
CACHE_TTL_SECONDS=300
EOF

    print_success "Created .env.production.example"
}

# Function to update .gitignore
update_gitignore() {
    print_status "Updating .gitignore..."
    
    # Create comprehensive .gitignore
    cat > .gitignore << 'EOF'
# =============================================================================
# BMI Chat .gitignore
# =============================================================================

# Environment files
.env
.env.local
.env.production
.env.staging

# Data and logs
data/
logs/
*.db
*.sqlite
*.sqlite3

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual environments
venv/
env/
ENV/
env.bak/
venv.bak/

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.npm
.yarn-integrity

# Build outputs
frontend/dist/
frontend/build/
widget/dist/
widget/build/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Docker
.dockerignore

# Backup files
backup_*
*.backup
*.bak

# Temporary files
*.tmp
*.temp
temp/
tmp/

# SSL certificates
*.pem
*.key
*.crt

# Nginx
nginx.conf.backup
EOF

    print_success "Updated .gitignore"
}

# Function to create deployment scripts
create_deployment_scripts() {
    print_status "Creating deployment scripts..."
    
    # Create quick-deploy.sh
    cat > quick-deploy.sh << 'EOF'
#!/bin/bash

# Script de Déploiement Rapide - BMI Chat
# Usage: ./quick-deploy.sh [update|fresh|backup]

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose n'est pas installé"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        log_error "curl n'est pas installé"
        exit 1
    fi
    
    log_success "Tous les prérequis sont satisfaits"
}

# Sauvegarder les données
backup_data() {
    log_info "Sauvegarde des données..."
    
    BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Sauvegarder la base de données
    if [ -f "data/bmi_chat.db" ]; then
        cp data/bmi_chat.db "$BACKUP_DIR/"
        log_success "Base de données sauvegardée"
    fi
    
    # Sauvegarder les vecteurs
    if [ -d "data/vectors" ]; then
        tar -czf "$BACKUP_DIR/vectors.tar.gz" data/vectors/
        log_success "Vecteurs sauvegardés"
    fi
    
    # Sauvegarder les logs
    if [ -d "logs" ]; then
        tar -czf "$BACKUP_DIR/logs.tar.gz" logs/
        log_success "Logs sauvegardés"
    fi
    
    log_success "Sauvegarde terminée dans $BACKUP_DIR"
}

# Arrêter les services
stop_services() {
    log_info "Arrêt des services..."
    docker-compose down
    log_success "Services arrêtés"
}

# Reconstruire les images
build_images() {
    log_info "Reconstruction des images Docker..."
    docker-compose build --no-cache
    log_success "Images reconstruites"
}

# Démarrer les services
start_services() {
    log_info "Démarrage des services..."
    docker-compose up -d
    log_success "Services démarrés"
}

# Attendre que les services soient prêts
wait_for_services() {
    log_info "Attente du démarrage des services..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:3006/health > /dev/null 2>&1; then
            log_success "Backend en ligne"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Backend ne répond pas après $max_attempts tentatives"
            return 1
        fi
        
        log_info "Tentative $attempt/$max_attempts - Attente..."
        sleep 10
        ((attempt++))
    done
    
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:8095 > /dev/null 2>&1; then
            log_success "Frontend en ligne"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Frontend ne répond pas après $max_attempts tentatives"
            return 1
        fi
        
        log_info "Tentative $attempt/$max_attempts - Attente..."
        sleep 10
        ((attempt++))
    done
}

# Vérifier la santé des services
check_health() {
    log_info "Vérification de la santé des services..."
    
    # Vérifier le backend
    if curl -f http://localhost:3006/health > /dev/null 2>&1; then
        log_success "✅ Backend en ligne"
    else
        log_error "❌ Backend hors ligne"
        return 1
    fi
    
    # Vérifier le frontend
    if curl -f http://localhost:8095 > /dev/null 2>&1; then
        log_success "✅ Frontend en ligne"
    else
        log_error "❌ Frontend hors ligne"
        return 1
    fi
    
    # Vérifier l'API publique
    if curl -f https://bmi.engage-360.net/health > /dev/null 2>&1; then
        log_success "✅ API publique accessible"
    else
        log_warning "⚠️ API publique non accessible (peut être normal pendant le démarrage)"
    fi
}

# Tester la recherche
test_search() {
    log_info "Test de la recherche..."
    
    local response=$(curl -s -X POST "https://bmi.engage-360.net/api/search/semantic" \
        -H "Content-Type: application/json" \
        -d '{"query": "BMI", "k": 5, "min_score": 0.0}' 2>/dev/null || echo '{"error": "request failed"}')
    
    if echo "$response" | grep -q "results"; then
        log_success "✅ Recherche fonctionnelle"
        echo "Réponse: $response" | jq '.' 2>/dev/null || echo "$response"
    else
        log_warning "⚠️ Recherche non fonctionnelle: $response"
    fi
}

# Nettoyer les ressources Docker
cleanup_docker() {
    log_info "Nettoyage des ressources Docker..."
    
    # Nettoyer les images non utilisées
    docker image prune -f
    
    # Nettoyer les conteneurs arrêtés
    docker container prune -f
    
    # Nettoyer les volumes non utilisés
    docker volume prune -f
    
    log_success "Nettoyage terminé"
}

# Fonction principale
main() {
    local mode=${1:-"update"}
    
    echo "🚀 Déploiement BMI Chat - Mode: $mode"
    echo "========================================"
    
    # Vérifier les prérequis
    check_prerequisites
    
    # Sauvegarder si demandé
    if [ "$mode" = "backup" ]; then
        backup_data
        exit 0
    fi
    
    # Sauvegarder avant mise à jour
    if [ "$mode" = "update" ]; then
        backup_data
    fi
    
    # Arrêter les services
    stop_services
    
    # Reconstruire les images
    build_images
    
    # Démarrer les services
    start_services
    
    # Attendre que les services soient prêts
    if ! wait_for_services; then
        log_error "Échec du démarrage des services"
        exit 1
    fi
    
    # Vérifier la santé
    if ! check_health; then
        log_error "Échec de la vérification de santé"
        exit 1
    fi
    
    # Tester la recherche
    test_search
    
    # Nettoyer (optionnel)
    if [ "$mode" = "fresh" ]; then
        cleanup_docker
    fi
    
    log_success "🎉 Déploiement terminé avec succès!"
    echo ""
    echo "📋 Résumé:"
    echo "  - Backend: http://localhost:3006"
    echo "  - Frontend: http://localhost:8095"
    echo "  - API Publique: https://bmi.engage-360.net"
    echo "  - Documentation: https://bmi.engage-360.net/docs"
    echo ""
    echo "🔍 Commandes utiles:"
    echo "  - Logs backend: docker-compose logs -f backend"
    echo "  - Logs frontend: docker-compose logs -f frontend"
    echo "  - État services: docker-compose ps"
    echo "  - Test recherche: curl -X POST https://bmi.engage-360.net/api/search/semantic -H 'Content-Type: application/json' -d '{\"query\": \"test\"}'"
}

# Gestion des arguments
case "${1:-update}" in
    "update")
        main "update"
        ;;
    "fresh")
        main "fresh"
        ;;
    "backup")
        main "backup"
        ;;
    *)
        echo "Usage: $0 [update|fresh|backup]"
        echo "  update: Mise à jour avec sauvegarde (défaut)"
        echo "  fresh: Déploiement propre avec nettoyage"
        echo "  backup: Sauvegarde uniquement"
        exit 1
        ;;
esac
EOF

    chmod +x quick-deploy.sh
    print_success "Created quick-deploy.sh"
}

# Function to create nginx configuration for multi-app setup
create_nginx_config() {
    print_status "Creating nginx configuration for multi-app setup..."
    
    # Create nginx configuration that won't conflict with other apps
    mkdir -p deployment/nginx/conf.d
    
    cat > deployment/nginx/conf.d/bmi-chat.conf << 'EOF'
# BMI Chat Configuration - Multi-App Safe
# This configuration is designed to work alongside other applications

# Upstream for backend
upstream bmi_backend {
    server backend:3006;
}

# Upstream for frontend
upstream bmi_frontend {
    server frontend:80;
}

# BMI Chat specific server block
server {
    listen 80;
    server_name bmi.engage-360.net www.bmi.engage-360.net;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Frontend (React app)
    location / {
        proxy_pass http://bmi_frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Handle React Router
        try_files $uri $uri/ /index.html;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://bmi_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "https://bmi.engage-360.net" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://bmi.engage-360.net" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
            add_header Access-Control-Allow-Credentials "true" always;
            add_header Content-Type "text/plain charset=UTF-8";
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # Widget API
    location /widget/ {
        # Handle widget API requests
        location ~ ^/widget/(chat|config|health) {
            proxy_pass http://bmi_backend/widget/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
        
        # Handle widget static files
        location ~ ^/widget/.*\.(js|css|html)$ {
            proxy_pass http://bmi_frontend/widget/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    
    # Health check
    location /health {
        proxy_pass http://bmi_backend/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        access_log off;
    }
    
    # Documentation API
    location /docs {
        proxy_pass http://bmi_backend/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
}
EOF

    print_success "Created nginx configuration for multi-app setup"
}

# Function to create docker-compose.yml
create_docker_compose() {
    print_status "Creating docker-compose.yml..."
    
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
    environment:
      - ENVIRONMENT=production
    env_file:
      - .env
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3006/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
    networks:
      - bmi-network

  frontend:
    build:
      context: ./frontend
      dockerfile: ../deployment/docker/Dockerfile.frontend
    container_name: bmi-chat-frontend
    ports:
      - "8095:80"
    depends_on:
      - backend
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
    networks:
      - bmi-network

networks:
  bmi-network:
    driver: bridge
EOF

    print_success "Created docker-compose.yml"
}

# Function to create Dockerfiles
create_dockerfiles() {
    print_status "Creating Dockerfiles..."
    
    mkdir -p deployment/docker
    
    # Backend Dockerfile
    cat > deployment/docker/Dockerfile.backend << 'EOF'
FROM python:3.11-slim

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Install Poetry and dependencies
RUN pip install poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-dev

# Copy source code
COPY app/ ./app/
COPY deployment/ ./deployment/

# Create necessary directories
RUN mkdir -p /app/data /app/logs && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3006

# Start command
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "3006"]
EOF

    # Frontend Dockerfile
    cat > deployment/docker/Dockerfile.frontend << 'EOF'
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY deployment/docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

    print_success "Created Dockerfiles"
}

# Function to deploy to GitHub
deploy_to_github() {
    print_status "Deploying to GitHub repository..."
    
    # Initialize git if not already done
    if [ ! -d ".git" ]; then
        git init
        print_success "Initialized git repository"
    fi
    
    # Add all files
    git add .
    
    # Commit changes
    git commit -m "🚀 BMI Chat v2.0 - Complete deployment ready" || {
        print_warning "No changes to commit"
    }
    
    # Add remote if not exists
    if ! git remote get-url origin > /dev/null 2>&1; then
        git remote add origin "$GIT_REPO"
        print_success "Added remote origin"
    fi
    
    # Force push to clean repository
    print_status "Force pushing to clean repository..."
    git push -f origin main || git push -f origin master
    
    print_success "Successfully deployed to GitHub"
}

# Function to deploy to VPS
deploy_to_vps() {
    print_status "Deploying to VPS..."
    
    # Create deployment script for VPS
    cat > deploy-vps-remote.sh << 'EOF'
#!/bin/bash

# Remote VPS deployment script
set -e

# Configuration
PROJECT_DIR="/opt/bmichat"
GIT_REPO="https://github.com/bkourouma/bmichatv2.git"
DOMAIN="bmi.engage-360.net"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Install dependencies
install_dependencies() {
    log_info "Installing system dependencies..."
    
    apt update && apt upgrade -y
    apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    
    # Install Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    log_success "Dependencies installed"
}

# Setup project directory
setup_project() {
    log_info "Setting up project directory..."
    
    # Create project directory
    mkdir -p $PROJECT_DIR
    cd $PROJECT_DIR
    
    # Clone repository
    if [ -d ".git" ]; then
        log_info "Updating existing repository..."
        git pull origin main || git pull origin master
    else
        log_info "Cloning repository..."
        git clone $GIT_REPO .
    fi
    
    # Create necessary directories
    mkdir -p data/sqlite data/vectors data/uploads logs
    
    # Set permissions
    chown -R 1000:1000 data logs
    
    log_success "Project directory setup complete"
}

# Configure environment
configure_environment() {
    log_info "Configuring environment..."
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        cp .env.production.example .env
        log_warning "Please configure your .env file with your OpenAI API key and other settings"
    fi
    
    log_success "Environment configured"
}

# Setup nginx configuration
setup_nginx() {
    log_info "Setting up nginx configuration..."
    
    # Create nginx configuration directory
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    
    # Create BMI Chat nginx configuration
    cat > /etc/nginx/sites-available/bmi-chat << 'EOF'
# BMI Chat Configuration - Multi-App Safe
upstream bmi_backend {
    server 127.0.0.1:3006;
}

upstream bmi_frontend {
    server 127.0.0.1:8095;
}

server {
    listen 80;
    server_name bmi.engage-360.net www.bmi.engage-360.net;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    # Frontend (React app)
    location / {
        proxy_pass http://bmi_frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Handle React Router
        try_files $uri $uri/ /index.html;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://bmi_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "https://bmi.engage-360.net" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://bmi.engage-360.net" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
            add_header Access-Control-Allow-Credentials "true" always;
            add_header Content-Type "text/plain charset=UTF-8";
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # Widget API
    location /widget/ {
        # Handle widget API requests
        location ~ ^/widget/(chat|config|health) {
            proxy_pass http://bmi_backend/widget/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
        
        # Handle widget static files
        location ~ ^/widget/.*\.(js|css|html)$ {
            proxy_pass http://bmi_frontend/widget/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    
    # Health check
    location /health {
        proxy_pass http://bmi_backend/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        access_log off;
    }
    
    # Documentation API
    location /docs {
        proxy_pass http://bmi_backend/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
}
EOF
    
    # Enable the site
    ln -sf /etc/nginx/sites-available/bmi-chat /etc/nginx/sites-enabled/
    
    # Test nginx configuration
    nginx -t
    
    # Reload nginx
    systemctl reload nginx
    
    log_success "Nginx configuration setup complete"
}

# Deploy application
deploy_application() {
    log_info "Deploying application..."
    
    cd $PROJECT_DIR
    
    # Stop existing services
    docker-compose down || true
    
    # Build and start services
    docker-compose build --no-cache
    docker-compose up -d
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 30
    
    # Check health
    if curl -f http://localhost:3006/health > /dev/null 2>&1; then
        log_success "Backend is healthy"
    else
        log_error "Backend health check failed"
        return 1
    fi
    
    if curl -f http://localhost:8095 > /dev/null 2>&1; then
        log_success "Frontend is healthy"
    else
        log_error "Frontend health check failed"
        return 1
    fi
    
    log_success "Application deployed successfully"
}

# Setup SSL
setup_ssl() {
    log_info "Setting up SSL certificate..."
    
    # Install certbot
    apt install -y certbot python3-certbot-nginx
    
    # Get SSL certificate
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@engage-360.net
    
    log_success "SSL certificate setup complete"
}

# Main deployment function
main() {
    log_info "Starting BMI Chat deployment on VPS..."
    
    # Install dependencies
    install_dependencies
    
    # Setup project
    setup_project
    
    # Configure environment
    configure_environment
    
    # Setup nginx
    setup_nginx
    
    # Deploy application
    deploy_application
    
    # Setup SSL (optional - can be done manually)
    # setup_ssl
    
    log_success "🎉 BMI Chat deployment completed successfully!"
    echo ""
    echo "📋 Deployment Summary:"
    echo "  - Backend: http://localhost:3006"
    echo "  - Frontend: http://localhost:8095"
    echo "  - Domain: http://$DOMAIN"
    echo "  - Health Check: http://$DOMAIN/health"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Configure your .env file with OpenAI API key"
    echo "  2. Setup SSL certificate: certbot --nginx -d $DOMAIN"
    echo "  3. Test the application: curl http://$DOMAIN/health"
    echo ""
    echo "📝 Useful Commands:"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Restart: docker-compose restart"
    echo "  - Update: git pull && docker-compose up -d --build"
}

# Run main function
main
EOF

    # Make script executable
    chmod +x deploy-vps-remote.sh
    
    # Copy script to VPS and execute
    print_status "Copying deployment script to VPS..."
    scp deploy-vps-remote.sh $VPS_USER@$VPS_IP:/tmp/
    
    print_status "Executing deployment on VPS..."
    ssh $VPS_USER@$VPS_IP "bash /tmp/deploy-vps-remote.sh"
    
    # Clean up
    rm deploy-vps-remote.sh
    
    print_success "VPS deployment completed"
}

# Main function
main() {
    echo "🚀 BMI Chat Deployment Script"
    echo "=============================="
    echo "This script will:"
    echo "1. Clean the repository for GitHub"
    echo "2. Create production-ready files"
    echo "3. Deploy to GitHub repository"
    echo "4. Deploy to VPS server"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Prepare for GitHub
    prepare_for_github
    
    # Create production files
    create_production_env
    update_gitignore
    create_deployment_scripts
    create_nginx_config
    create_docker_compose
    create_dockerfiles
    
    # Deploy to GitHub
    deploy_to_github
    
    # Deploy to VPS
    deploy_to_vps
    
    print_success "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "  - GitHub Repository: $GIT_REPO"
    echo "  - VPS Server: $VPS_IP"
    echo "  - Domain: $DOMAIN"
    echo ""
    echo "🔧 Next Steps:"
    echo "  1. Configure your .env file on the VPS with your OpenAI API key"
    echo "  2. Setup SSL certificate: certbot --nginx -d $DOMAIN"
    echo "  3. Test the application: curl https://$DOMAIN/health"
    echo ""
    echo "📝 Useful Commands:"
    echo "  - SSH to VPS: ssh $VPS_USER@$VPS_IP"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Update: git pull && docker-compose up -d --build"
}

# Run main function
main 