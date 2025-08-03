# 🏢 Configuration Spécifique pour Hostinger VPS

## 📋 Prérequis Hostinger

### VPS Hostinger Recommandé
- **CPU** : 2 vCPU minimum
- **RAM** : 4GB minimum (2GB pour test)
- **Stockage** : 40GB minimum
- **OS** : Ubuntu 20.04 LTS ou CentOS 8
- **Bande passante** : Illimitée

## 🔧 Configuration Initiale Hostinger

### 1. **Accès au VPS**
```bash
# Via le panneau Hostinger
# 1. Allez dans votre panneau Hostinger
# 2. VPS → Votre VPS → Terminal
# 3. Ou utilisez SSH externe
ssh root@votre-ip-hostinger
```

### 2. **Mise à jour du système**
```bash
# Ubuntu
sudo apt update && sudo apt upgrade -y

# CentOS
sudo yum update -y
```

### 3. **Configuration du pare-feu Hostinger**
```bash
# Ouvrir les ports nécessaires
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3003/tcp  # Frontend
sudo ufw allow 3006/tcp  # Backend API

# Activer le pare-feu
sudo ufw enable
```

## 🐳 Installation Docker sur Hostinger

### Ubuntu 20.04
```bash
# Supprimer les anciennes versions
sudo apt remove docker docker-engine docker.io containerd runc

# Installation des dépendances
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Ajouter la clé GPG Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Ajouter le repository Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installer Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configurer Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

### CentOS 8
```bash
# Installation des dépendances
sudo yum install -y yum-utils

# Ajouter le repository Docker
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Installer Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configurer Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

## 📁 Déploiement sur Hostinger

### 1. **Préparation du projet**
```bash
# Créer le répertoire de travail
mkdir -p /opt/bmichat
cd /opt/bmichat

# Télécharger le projet
# Option 1: Git (si vous avez un repository)
git clone https://github.com/votre-username/bmichat.git .

# Option 2: Upload via SFTP
# Utilisez FileZilla ou WinSCP pour uploader les fichiers
```

### 2. **Configuration pour Hostinger**
```bash
# Rendre le script exécutable
chmod +x deploy-vps.sh

# Installation automatique
./deploy-vps.sh install
```

### 3. **Configuration de l'environnement**
```bash
# Éditer le fichier .env
nano .env
```

**Configuration `.env` optimisée pour Hostinger :**
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
API_WORKERS=2
CORS_ORIGINS=["https://votre-domaine.com","http://votre-domaine.com","http://votre-ip-hostinger:3003"]

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
# Performance (Optimisé pour Hostinger)
# =============================================================================
MAX_UPLOAD_SIZE=25MB
RATE_LIMIT_PER_MINUTE=30
CACHE_TTL_SECONDS=300
```

### 4. **Déploiement**
```bash
# Déployer l'application
./deploy-vps.sh deploy

# Vérifier le statut
./deploy-vps.sh status
```

## 🌐 Configuration DNS Hostinger

### 1. **Via le panneau Hostinger**
1. Allez dans votre panneau Hostinger
2. **Domaines** → Votre domaine → **Gestion DNS**
3. Ajoutez un enregistrement A :
   - **Nom** : `@` ou `votre-sous-domaine`
   - **Valeur** : `votre-ip-vps`
   - **TTL** : `300`

### 2. **Configuration SSL automatique**
```bash
# Configurer SSL avec Let's Encrypt
DOMAIN=votre-domaine.com EMAIL=admin@votre-domaine.com ./deploy-vps.sh ssl
```

## 🔧 Optimisations Spécifiques Hostinger

### 1. **Optimisation mémoire**
```bash
# Créer un fichier de swap si nécessaire
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 2. **Optimisation Docker**
```bash
# Créer le fichier de configuration Docker
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Redémarrer Docker
sudo systemctl restart docker
```

### 3. **Monitoring des ressources**
```bash
# Installer htop pour le monitoring
sudo apt install htop -y

# Vérifier l'utilisation des ressources
htop
```

## 📊 Monitoring Hostinger

### 1. **Vérification des services**
```bash
# Statut des conteneurs
docker ps

# Utilisation des ressources
docker stats

# Logs en temps réel
./deploy-vps.sh logs
```

### 2. **Métriques de performance**
```bash
# Health check
curl http://localhost:3006/health

# Métriques complètes
curl http://localhost:3006/api/metrics/comprehensive
```

## 🔒 Sécurité Hostinger

### 1. **Configuration du pare-feu**
```bash
# Vérifier le statut UFW
sudo ufw status

# Règles recommandées
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3003/tcp
sudo ufw allow 3006/tcp
```

### 2. **Mise à jour automatique**
```bash
# Créer un script de mise à jour automatique
cat > /opt/bmichat/auto-update.sh << 'EOF'
#!/bin/bash
cd /opt/bmichat
./deploy-vps.sh backup
git pull origin main
./deploy-vps.sh update
EOF

chmod +x /opt/bmichat/auto-update.sh

# Ajouter au cron (mise à jour hebdomadaire)
echo "0 2 * * 0 /opt/bmichat/auto-update.sh" | sudo crontab -
```

## 🚨 Dépannage Hostinger

### Problèmes courants

1. **Ports bloqués par Hostinger**
   ```bash
   # Vérifier les ports ouverts
   sudo netstat -tulpn
   
   # Contacter le support Hostinger si nécessaire
   ```

2. **Espace disque insuffisant**
   ```bash
   # Nettoyer Docker
   docker system prune -a
   docker volume prune
   
   # Vérifier l'espace
   df -h
   ```

3. **Mémoire insuffisante**
   ```bash
   # Vérifier l'utilisation mémoire
   free -h
   
   # Optimiser les services
   # Réduire API_WORKERS dans .env
   ```

## 📞 Support Hostinger

### Ressources utiles
- **Documentation Hostinger** : https://www.hostinger.com/help
- **Support technique** : Via le panneau Hostinger
- **Community** : https://www.hostinger.com/community

### Commandes de diagnostic
```bash
# Informations système
uname -a
cat /etc/os-release

# Ressources système
htop
df -h
free -h

# Services Docker
docker ps
docker stats

# Logs d'application
./deploy-vps.sh logs backend
```

## ✅ Checklist Hostinger

- [ ] VPS Hostinger configuré
- [ ] Accès SSH fonctionnel
- [ ] Docker installé et configuré
- [ ] Pare-feu configuré
- [ ] Projet déployé
- [ ] DNS configuré (si domaine)
- [ ] SSL configuré (si domaine)
- [ ] Monitoring en place
- [ ] Sauvegarde configurée
- [ ] Tests de fonctionnalité effectués

---

**🎉 Votre application BMI Chat est maintenant optimisée pour Hostinger !** 