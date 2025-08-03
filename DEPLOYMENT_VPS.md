# 🚀 Guide de Déploiement BMI Chat sur VPS Hostinger

## 📋 Prérequis

- VPS Hostinger avec Ubuntu 20.04+ ou CentOS 8+
- Accès SSH root ou sudo
- Domaine configuré (optionnel mais recommandé)
- Au moins 2GB RAM et 20GB espace disque

## 🔧 Installation des Dépendances Système

### Ubuntu/Debian
```bash
# Mise à jour du système
sudo apt update && sudo apt upgrade -y

# Installation des dépendances
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Installation de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Installation de Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
```

### CentOS/RHEL
```bash
# Mise à jour du système
sudo yum update -y

# Installation des dépendances
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

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER
```

## 📁 Préparation du Projet

### 1. Cloner le projet
```bash
# Créer le répertoire de travail
mkdir -p /opt/bmichat
cd /opt/bmichat

# Cloner le repository (remplacez par votre repo)
git clone https://github.com/votre-username/bmichat.git .
# OU télécharger les fichiers manuellement
```

### 2. Configuration de l'environnement
```bash
# Copier le fichier d'environnement
cp env.example .env

# Éditer la configuration
nano .env
```

### Configuration `.env` pour Production
```env
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
CORS_ORIGINS=["https://votre-domaine.com","http://votre-domaine.com"]

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
SECRET_KEY=votre-clé-secrète-très-longue-et-complexe

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
```

## 🐳 Déploiement avec Docker

### 1. Déploiement Simple (Sans Nginx)
```bash
# Démarrer les services
docker-compose -f deployment/docker/docker-compose.yml up -d

# Vérifier les logs
docker-compose -f deployment/docker/docker-compose.yml logs -f
```

### 2. Déploiement Complet (Avec Nginx)
```bash
# Démarrer avec Nginx
docker-compose -f deployment/docker/docker-compose.yml --profile production up -d

# Vérifier les services
docker ps
```

## 🔒 Configuration SSL/HTTPS

### Option 1 : Certbot avec Nginx
```bash
# Installation de Certbot
sudo apt install -y certbot python3-certbot-nginx

# Obtenir le certificat SSL
sudo certbot --nginx -d votre-domaine.com

# Renouvellement automatique
sudo crontab -e
# Ajouter : 0 12 * * * /usr/bin/certbot renew --quiet
```

### Option 2 : Let's Encrypt avec Docker
```bash
# Créer le fichier docker-compose.prod.yml
cat > docker-compose.prod.yml << 'EOF'
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
    command: certonly --webroot --webroot-path=/var/www/certbot --email votre-email@domaine.com --agree-tos --no-eff-email -d votre-domaine.com

  backend:
    build:
      context: .
      dockerfile: deployment/docker/Dockerfile.backend
    container_name: bmi-chat-backend
    restart: unless-stopped
    environment:
      - ENVIRONMENT=production
      - DEBUG=false
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

# Créer les répertoires pour Certbot
mkdir -p certbot/conf certbot/www

# Démarrer avec SSL
docker-compose -f docker-compose.prod.yml up -d
```

## 🔧 Configuration Nginx pour Production

### Fichier `deployment/nginx/conf.d/default.conf`
```nginx
server {
    listen 80;
    server_name votre-domaine.com;
    
    # Redirection vers HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name votre-domaine.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/votre-domaine.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/votre-domaine.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Frontend
    location / {
        proxy_pass http://frontend:3003;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API Backend
    location /api/ {
        proxy_pass http://backend:3006;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health Check
    location /health {
        proxy_pass http://backend:3006/health;
        access_log off;
    }

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
}
```

## 📊 Monitoring et Logs

### 1. Vérification des Services
```bash
# Statut des conteneurs
docker ps

# Logs en temps réel
docker-compose -f deployment/docker/docker-compose.yml logs -f

# Logs spécifiques
docker logs bmi-chat-backend
docker logs bmi-chat-frontend
```

### 2. Métriques de Performance
```bash
# Accéder aux métriques
curl https://votre-domaine.com/api/metrics/comprehensive

# Vérifier la santé
curl https://votre-domaine.com/health
```

### 3. Sauvegarde des Données
```bash
# Créer un script de sauvegarde
cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/bmichat"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Sauvegarder les données
docker run --rm -v bmichat_backend_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/data_$DATE.tar.gz -C /data .

# Sauvegarder les logs
docker run --rm -v bmichat_backend_logs:/logs -v $BACKUP_DIR:/backup alpine tar czf /backup/logs_$DATE.tar.gz -C /logs .

echo "Sauvegarde terminée: $BACKUP_DIR/data_$DATE.tar.gz"
EOF

chmod +x backup.sh

# Ajouter au cron
echo "0 2 * * * /opt/bmichat/backup.sh" | sudo crontab -
```

## 🔄 Mise à Jour

### Script de Mise à Jour Automatique
```bash
cat > update.sh << 'EOF'
#!/bin/bash
cd /opt/bmichat

# Sauvegarde avant mise à jour
./backup.sh

# Pull des dernières modifications
git pull origin main

# Rebuild et redémarrage
docker-compose -f deployment/docker/docker-compose.yml down
docker-compose -f deployment/docker/docker-compose.yml build --no-cache
docker-compose -f deployment/docker/docker-compose.yml up -d

echo "Mise à jour terminée"
EOF

chmod +x update.sh
```

## 🚨 Dépannage

### Problèmes Courants

1. **Port déjà utilisé**
```bash
# Vérifier les ports utilisés
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Tuer le processus si nécessaire
sudo kill -9 <PID>
```

2. **Permissions Docker**
```bash
# Vérifier les permissions
sudo usermod -aG docker $USER
newgrp docker
```

3. **Espace disque**
```bash
# Nettoyer Docker
docker system prune -a
docker volume prune
```

4. **Logs d'erreur**
```bash
# Vérifier les logs
docker logs bmi-chat-backend --tail 100
docker logs bmi-chat-frontend --tail 100
```

## ✅ Checklist de Déploiement

- [ ] VPS configuré avec Ubuntu/CentOS
- [ ] Docker et Docker Compose installés
- [ ] Fichier `.env` configuré pour la production
- [ ] Domaine configuré (optionnel)
- [ ] SSL configuré (recommandé)
- [ ] Services démarrés et fonctionnels
- [ ] Sauvegarde configurée
- [ ] Monitoring en place
- [ ] Tests de fonctionnalité effectués

## 📞 Support

En cas de problème :
1. Vérifier les logs : `docker logs <container-name>`
2. Tester l'API : `curl https://votre-domaine.com/health`
3. Vérifier les métriques : `curl https://votre-domaine.com/api/metrics/comprehensive` 