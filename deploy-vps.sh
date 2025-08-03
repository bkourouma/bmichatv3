#!/bin/bash

# 🚀 Script de Déploiement BMI Chat sur VPS Hostinger
# Usage: ./deploy-vps.sh [install|deploy|update|backup|logs]

set -e

# Configuration
PROJECT_DIR="/opt/bmichat"
BACKUP_DIR="/opt/backups/bmichat"
DOMAIN="${DOMAIN:-votre-domaine.com}"
EMAIL="${EMAIL:-admin@votre-domaine.com}"

# Couleurs pour l'affichage
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

# Vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier si on est root ou sudo
    if [[ $EUID -eq 0 ]]; then
        log_error "Ce script ne doit pas être exécuté en tant que root"
        exit 1
    fi
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé. Exécutez d'abord l'installation."
        exit 1
    fi
    
    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose n'est pas installé. Exécutez d'abord l'installation."
        exit 1
    fi
    
    log_success "Prérequis vérifiés"
}

# Installation des dépendances système
install_dependencies() {
    log_info "Installation des dépendances système..."
    
    # Détecter le système d'exploitation
    if [[ -f /etc/debian_version ]]; then
        # Ubuntu/Debian
        log_info "Système Ubuntu/Debian détecté"
        
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
        
        # Installation de Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Installation de Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS/RHEL
        log_info "Système CentOS/RHEL détecté"
        
        sudo yum update -y
        sudo yum install -y curl wget git unzip
        
        # Installation de Docker
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Démarrage de Docker
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Installation de Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        log_error "Système d'exploitation non supporté"
        exit 1
    fi
    
    # Ajouter l'utilisateur au groupe docker
    sudo usermod -aG docker $USER
    
    log_success "Dépendances installées"
    log_warning "Redémarrez votre session SSH pour que les changements prennent effet"
}

# Préparation du projet
prepare_project() {
    log_info "Préparation du projet..."
    
    # Créer le répertoire de travail
    sudo mkdir -p $PROJECT_DIR
    sudo chown $USER:$USER $PROJECT_DIR
    cd $PROJECT_DIR
    
    # Créer le fichier .env s'il n'existe pas
    if [[ ! -f .env ]]; then
        log_info "Création du fichier .env..."
        cat > .env << EOF
# =============================================================================
# Application Configuration
# =============================================================================
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO

# =============================================================================
# API Configuration
# =============================================================================
API_HOST=0.0.0.0
API_PORT=3006
API_WORKERS=4
CORS_ORIGINS=["https://$DOMAIN","http://$DOMAIN"]

# =============================================================================
# OpenAI Configuration
# =============================================================================
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4o
OPENAI_TEMPERATURE=0.0
OPENAI_MAX_TOKENS=4000

# =============================================================================
# Database Configuration
# =============================================================================
DATABASE_URL=sqlite:///data/sqlite/bmi_chat.db
VECTOR_DB_PATH=data/vectors
UPLOAD_DIR=data/uploads

# =============================================================================
# Security
# =============================================================================
SECRET_KEY=$(openssl rand -hex 32)

# =============================================================================
# Document Processing
# =============================================================================
CHUNK_SIZE=4000
CHUNK_OVERLAP=800
MAX_CHUNKS_PER_DOCUMENT=100

# =============================================================================
# Chat Configuration
# =============================================================================
MAX_CHAT_HISTORY=10
DEFAULT_RETRIEVAL_K=5
MAX_RETRIEVAL_K=10
CHAT_TIMEOUT_SECONDS=30

# =============================================================================
# Logging
# =============================================================================
LOG_FILE=logs/app.log
LOG_MAX_SIZE=10MB
LOG_BACKUP_COUNT=5

# =============================================================================
# Performance
# =============================================================================
MAX_UPLOAD_SIZE=50MB
RATE_LIMIT_PER_MINUTE=60
CACHE_TTL_SECONDS=300
EOF
        
        log_warning "Veuillez éditer le fichier .env et configurer votre clé OpenAI"
        log_info "Commande: nano $PROJECT_DIR/.env"
    fi
    
    log_success "Projet préparé"
}

# Déploiement de l'application
deploy_application() {
    log_info "Déploiement de l'application..."
    
    cd $PROJECT_DIR
    
    # Vérifier que le fichier .env existe
    if [[ ! -f .env ]]; then
        log_error "Fichier .env manquant. Exécutez d'abord: ./deploy-vps.sh install"
        exit 1
    fi
    
    # Créer les répertoires nécessaires
    mkdir -p data/sqlite data/uploads data/vectors logs
    
    # Démarrer les services
    log_info "Démarrage des services..."
    docker-compose -f deployment/docker/docker-compose.yml down || true
    docker-compose -f deployment/docker/docker-compose.yml build --no-cache
    docker-compose -f deployment/docker/docker-compose.yml up -d
    
    # Attendre que les services soient prêts
    log_info "Attente du démarrage des services..."
    sleep 30
    
    # Vérifier la santé des services
    if curl -f http://localhost:3006/health > /dev/null 2>&1; then
        log_success "Application déployée avec succès"
        log_info "Frontend: http://localhost:3003"
        log_info "Backend API: http://localhost:3006"
        log_info "Health Check: http://localhost:3006/health"
    else
        log_error "Erreur lors du déploiement. Vérifiez les logs:"
        docker-compose -f deployment/docker/docker-compose.yml logs
        exit 1
    fi
}

# Configuration SSL avec Let's Encrypt
setup_ssl() {
    log_info "Configuration SSL avec Let's Encrypt..."
    
    cd $PROJECT_DIR
    
    # Créer les répertoires pour Certbot
    mkdir -p certbot/conf certbot/www
    
    # Créer le fichier docker-compose.prod.yml
    cat > docker-compose.prod.yml << EOF
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: bmi-chat-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./deployment/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./deployment/nginx/conf.d:/etc/nginx/conf.d
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      - backend
      - frontend
    networks:
      - bmi-chat-network

  certbot:
    image: certbot/certbot
    container_name: bmi-chat-certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    command: certonly --webroot --webroot-path=/var/www/certbot --email $EMAIL --agree-tos --no-eff-email -d $DOMAIN

  backend:
    build:
      context: .
      dockerfile: deployment/docker/Dockerfile.backend
    container_name: bmi-chat-backend
    restart: unless-stopped
    environment:
      - ENVIRONMENT=production
      - DEBUG=false
    env_file:
      - .env
    volumes:
      - backend_data:/app/data
      - backend_logs:/app/logs
    networks:
      - bmi-chat-network

  frontend:
    build:
      context: .
      dockerfile: deployment/docker/Dockerfile.frontend
    container_name: bmi-chat-frontend
    restart: unless-stopped
    networks:
      - bmi-chat-network

volumes:
  backend_data:
  backend_logs:

networks:
  bmi-chat-network:
    driver: bridge
EOF
    
    # Démarrer avec SSL
    docker-compose -f docker-compose.prod.yml up -d
    
    log_success "SSL configuré"
    log_info "Votre application est accessible sur: https://$DOMAIN"
}

# Sauvegarde des données
backup_data() {
    log_info "Sauvegarde des données..."
    
    mkdir -p $BACKUP_DIR
    DATE=$(date +%Y%m%d_%H%M%S)
    
    # Sauvegarder les données
    docker run --rm -v bmichat_backend_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/data_$DATE.tar.gz -C /data .
    
    # Sauvegarder les logs
    docker run --rm -v bmichat_backend_logs:/logs -v $BACKUP_DIR:/backup alpine tar czf /backup/logs_$DATE.tar.gz -C /logs .
    
    log_success "Sauvegarde terminée: $BACKUP_DIR/data_$DATE.tar.gz"
}

# Mise à jour de l'application
update_application() {
    log_info "Mise à jour de l'application..."
    
    cd $PROJECT_DIR
    
    # Sauvegarde avant mise à jour
    backup_data
    
    # Pull des dernières modifications (si git)
    if [[ -d .git ]]; then
        git pull origin main
    fi
    
    # Rebuild et redémarrage
    docker-compose -f deployment/docker/docker-compose.yml down
    docker-compose -f deployment/docker/docker-compose.yml build --no-cache
    docker-compose -f deployment/docker/docker-compose.yml up -d
    
    log_success "Mise à jour terminée"
}

# Affichage des logs
show_logs() {
    log_info "Affichage des logs..."
    
    cd $PROJECT_DIR
    
    if [[ "$1" == "backend" ]]; then
        docker logs bmi-chat-backend -f
    elif [[ "$1" == "frontend" ]]; then
        docker logs bmi-chat-frontend -f
    else
        docker-compose -f deployment/docker/docker-compose.yml logs -f
    fi
}

# Affichage du statut
show_status() {
    log_info "Statut des services..."
    
    echo "=== Conteneurs Docker ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n=== Services BMI Chat ==="
    if curl -f http://localhost:3006/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Backend API: Opérationnel${NC}"
    else
        echo -e "${RED}✗ Backend API: Hors service${NC}"
    fi
    
    if curl -f http://localhost:3003 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Frontend: Opérationnel${NC}"
    else
        echo -e "${RED}✗ Frontend: Hors service${NC}"
    fi
    
    echo -e "\n=== URLs ==="
    echo "Frontend: http://localhost:3003"
    echo "Backend API: http://localhost:3006"
    echo "Health Check: http://localhost:3006/health"
    echo "Métriques: http://localhost:3006/api/metrics/comprehensive"
}

# Menu d'aide
show_help() {
    echo "🚀 Script de Déploiement BMI Chat sur VPS Hostinger"
    echo ""
    echo "Usage: $0 [COMMANDE]"
    echo ""
    echo "Commandes disponibles:"
    echo "  install     - Installation des dépendances système"
    echo "  deploy      - Déploiement de l'application"
    echo "  ssl         - Configuration SSL avec Let's Encrypt"
    echo "  update      - Mise à jour de l'application"
    echo "  backup      - Sauvegarde des données"
    echo "  logs        - Affichage des logs (backend|frontend)"
    echo "  status      - Statut des services"
    echo "  help        - Affichage de cette aide"
    echo ""
    echo "Variables d'environnement:"
    echo "  DOMAIN      - Votre domaine (défaut: votre-domaine.com)"
    echo "  EMAIL       - Votre email pour Let's Encrypt (défaut: admin@votre-domaine.com)"
    echo ""
    echo "Exemples:"
    echo "  DOMAIN=mon-site.com EMAIL=admin@mon-site.com $0 install"
    echo "  $0 deploy"
    echo "  $0 ssl"
    echo "  $0 logs backend"
}

# Script principal
case "${1:-help}" in
    install)
        check_prerequisites
        install_dependencies
        prepare_project
        log_success "Installation terminée. Configurez votre fichier .env puis exécutez: $0 deploy"
        ;;
    deploy)
        check_prerequisites
        deploy_application
        ;;
    ssl)
        check_prerequisites
        setup_ssl
        ;;
    update)
        check_prerequisites
        update_application
        ;;
    backup)
        check_prerequisites
        backup_data
        ;;
    logs)
        check_prerequisites
        show_logs $2
        ;;
    status)
        check_prerequisites
        show_status
        ;;
    help|*)
        show_help
        ;;
esac 