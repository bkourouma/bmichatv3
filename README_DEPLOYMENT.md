# 🚀 Guide de Déploiement BMI Chat

## 📋 Vue d'ensemble

Ce guide vous accompagne pour déployer l'application BMI Chat sur votre VPS Hostinger avec toutes les optimisations RAG implémentées.

## 🎯 Options de Déploiement

### 1. **Déploiement Automatique (Recommandé)**
```bash
# Télécharger le projet sur votre VPS
cd /opt/bmichat

# Installation automatique
chmod +x deploy-vps.sh
./deploy-vps.sh install

# Configuration
nano .env  # Configurez votre clé OpenAI

# Déploiement
./deploy-vps.sh deploy
```

### 2. **Déploiement Manuel**
```bash
# Installation des dépendances
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose

# Configuration du projet
mkdir -p /opt/bmichat
cd /opt/bmichat
# Uploadez vos fichiers ici

# Démarrage
docker-compose -f deployment/docker/docker-compose.yml up -d
```

### 3. **Déploiement avec SSL**
```bash
# Après le déploiement de base
DOMAIN=votre-domaine.com EMAIL=admin@votre-domaine.com ./deploy-vps.sh ssl
```

## 🔧 Configuration Requise

### Fichier `.env` Minimal
```env
ENVIRONMENT=production
DEBUG=false
OPENAI_API_KEY=your_openai_api_key_here
SECRET_KEY=votre-clé-secrète
DOMAIN=votre-domaine.com
```

### Prérequis Système
- **OS** : Ubuntu 20.04+ ou CentOS 8+
- **RAM** : 2GB minimum (4GB recommandé)
- **Stockage** : 20GB minimum
- **Ports** : 80, 443, 3003, 3006

## 📚 Documentation Complète

### Guides Détaillés
- **[DEPLOYMENT_VPS.md](DEPLOYMENT_VPS.md)** - Guide complet de déploiement
- **[QUICK_DEPLOY.md](QUICK_DEPLOY.md)** - Démarrage rapide
- **[HOSTINGER_SETUP.md](HOSTINGER_SETUP.md)** - Configuration spécifique Hostinger

### Scripts Disponibles
- **`deploy-vps.sh`** - Script de déploiement automatisé
- **`deploy.sh`** - Script de déploiement local
- **`deploy.bat`** - Script Windows

## 🎯 Fonctionnalités Déployées

### ✅ Pipeline RAG Optimisé
- **Cross-encoder re-ranking** pour une meilleure pertinence
- **Embeddings français optimisés** avec `text-embedding-3-small`
- **Seuils adaptatifs** pour la génération conditionnelle
- **Chunking intelligent** avec overlap sémantique

### ✅ Services Inclus
- **Backend FastAPI** avec optimisations RAG
- **Frontend React** avec interface moderne
- **Nginx** pour le reverse proxy (optionnel)
- **SSL/HTTPS** avec Let's Encrypt
- **Monitoring** et métriques en temps réel

### ✅ Commandes de Gestion
```bash
# Statut des services
./deploy-vps.sh status

# Logs en temps réel
./deploy-vps.sh logs

# Sauvegarde des données
./deploy-vps.sh backup

# Mise à jour
./deploy-vps.sh update
```

## 🌐 Accès à l'Application

### URLs par Défaut
- **Frontend** : http://votre-ip:3003
- **Backend API** : http://votre-ip:3006
- **Health Check** : http://votre-ip:3006/health
- **Métriques** : http://votre-ip:3006/api/metrics/comprehensive

### Avec Domaine et SSL
- **Application** : https://votre-domaine.com
- **API** : https://votre-domaine.com/api/
- **Health** : https://votre-domaine.com/health

## 🔒 Sécurité

### Configuration Recommandée
- **Pare-feu** : UFW configuré
- **SSL** : Let's Encrypt automatique
- **Headers** : Sécurité renforcée
- **Rate Limiting** : Protection contre les abus

### Variables d'Environnement Sécurisées
```env
SECRET_KEY=clé-très-longue-et-complexe
OPENAI_API_KEY=your_openai_api_key_here
ENVIRONMENT=production
DEBUG=false
```

## 📊 Monitoring et Maintenance

### Métriques Disponibles
- **Performance** : Temps de réponse, taux de succès
- **Qualité** : Scores de confiance, pertinence
- **Ressources** : CPU, mémoire, stockage
- **Erreurs** : Logs détaillés, alertes

### Maintenance Automatique
```bash
# Sauvegarde quotidienne
0 2 * * * /opt/bmichat/backup.sh

# Mise à jour hebdomadaire
0 2 * * 0 /opt/bmichat/update.sh

# Nettoyage mensuel
0 2 1 * * docker system prune -a
```

## 🚨 Dépannage

### Problèmes Courants

1. **Ports déjà utilisés**
   ```bash
   sudo netstat -tulpn | grep :3006
   sudo kill -9 <PID>
   ```

2. **Permissions Docker**
   ```bash
   sudo usermod -aG docker $USER
   newgrp docker
   ```

3. **Espace disque**
   ```bash
   docker system prune -a
   df -h
   ```

4. **Logs d'erreur**
   ```bash
   ./deploy-vps.sh logs backend
   docker logs bmi-chat-backend --tail 100
   ```

### Diagnostic Complet
```bash
# Vérification système
./deploy-vps.sh status
curl http://localhost:3006/health
curl http://localhost:3006/api/metrics/comprehensive

# Logs détaillés
./deploy-vps.sh logs
docker stats
```

## 🎯 Tests Post-Déploiement

### 1. **Test de Base**
```bash
# Health check
curl http://localhost:3006/health

# Test API
curl -X POST http://localhost:3006/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'
```

### 2. **Test du Pipeline RAG**
1. Upload d'un document via l'interface
2. Test d'une question spécifique
3. Vérification de la réponse complète
4. Contrôle des métriques de performance

### 3. **Test de Performance**
```bash
# Métriques complètes
curl http://localhost:3006/api/metrics/comprehensive

# Monitoring en temps réel
docker stats
```

## 📞 Support

### Ressources Disponibles
- **Documentation** : Fichiers README dans le projet
- **Scripts** : `deploy-vps.sh` avec commandes intégrées
- **Logs** : Système de logging détaillé
- **Métriques** : Monitoring en temps réel

### Commandes de Support
```bash
# Aide du script
./deploy-vps.sh help

# Statut complet
./deploy-vps.sh status

# Logs détaillés
./deploy-vps.sh logs

# Diagnostic système
docker ps
docker stats
curl http://localhost:3006/health
```

## ✅ Checklist Finale

- [ ] VPS configuré et accessible
- [ ] Dépendances installées (Docker, Docker Compose)
- [ ] Fichier `.env` configuré avec vos clés
- [ ] Application déployée et fonctionnelle
- [ ] SSL configuré (si domaine)
- [ ] Pare-feu configuré
- [ ] Sauvegarde configurée
- [ ] Monitoring en place
- [ ] Tests de fonctionnalité effectués
- [ ] Documentation consultée

## 🎉 Félicitations !

Votre application BMI Chat est maintenant déployée avec :
- ✅ **Pipeline RAG optimisé** pour des réponses précises
- ✅ **Interface moderne** et responsive
- ✅ **Sécurité renforcée** avec SSL et pare-feu
- ✅ **Monitoring complet** pour le suivi des performances
- ✅ **Maintenance automatisée** pour la pérennité

**Votre chatbot intelligent est prêt à servir vos utilisateurs !** 🚀 