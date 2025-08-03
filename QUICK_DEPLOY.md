# 🚀 Déploiement Rapide sur VPS Hostinger

## 📋 Étapes Rapides

### 1. **Connexion à votre VPS**
```bash
ssh root@votre-ip-vps
```

### 2. **Téléchargement du projet**
```bash
# Créer le répertoire
mkdir -p /opt/bmichat
cd /opt/bmichat

# Télécharger les fichiers (remplacez par votre méthode)
# Option 1: Git
git clone https://github.com/votre-username/bmichat.git .

# Option 2: Upload manuel
# Uploadez les fichiers via SFTP/SCP
```

### 3. **Installation automatique**
```bash
# Rendre le script exécutable
chmod +x deploy-vps.sh

# Installation des dépendances
./deploy-vps.sh install
```

### 4. **Configuration**
```bash
# Éditer le fichier .env
nano .env

# Configurer votre clé OpenAI et domaine
OPENAI_API_KEY=your_openai_api_key_here
DOMAIN=votre-domaine.com
```

### 5. **Déploiement**
```bash
# Déployer l'application
./deploy-vps.sh deploy

# Vérifier le statut
./deploy-vps.sh status
```

### 6. **Configuration SSL (optionnel)**
```bash
# Configurer SSL avec Let's Encrypt
DOMAIN=votre-domaine.com EMAIL=admin@votre-domaine.com ./deploy-vps.sh ssl
```

## 🔧 Commandes Utiles

```bash
# Voir les logs
./deploy-vps.sh logs

# Logs du backend
./deploy-vps.sh logs backend

# Logs du frontend
./deploy-vps.sh logs frontend

# Sauvegarde
./deploy-vps.sh backup

# Mise à jour
./deploy-vps.sh update

# Statut des services
./deploy-vps.sh status
```

## 🌐 Accès à l'Application

- **Frontend**: http://votre-ip:3003
- **Backend API**: http://votre-ip:3006
- **Health Check**: http://votre-ip:3006/health
- **Métriques**: http://votre-ip:3006/api/metrics/comprehensive

## 🔒 Configuration SSL

Si vous avez un domaine :

1. **Pointage DNS** : Pointez votre domaine vers l'IP du VPS
2. **Configuration SSL** :
   ```bash
   DOMAIN=votre-domaine.com EMAIL=admin@votre-domaine.com ./deploy-vps.sh ssl
   ```
3. **Accès sécurisé** : https://votre-domaine.com

## 📊 Monitoring

### Vérification de la santé
```bash
curl http://localhost:3006/health
```

### Métriques de performance
```bash
curl http://localhost:3006/api/metrics/comprehensive
```

### Logs en temps réel
```bash
./deploy-vps.sh logs
```

## 🚨 Dépannage

### Problèmes courants

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
   ```

4. **Logs d'erreur**
   ```bash
   ./deploy-vps.sh logs backend
   ```

## 📞 Support

En cas de problème :
1. Vérifiez les logs : `./deploy-vps.sh logs`
2. Testez l'API : `curl http://localhost:3006/health`
3. Vérifiez le statut : `./deploy-vps.sh status`

## ✅ Checklist de Déploiement

- [ ] VPS accessible via SSH
- [ ] Fichiers du projet téléchargés
- [ ] Script `deploy-vps.sh` exécutable
- [ ] Installation des dépendances terminée
- [ ] Fichier `.env` configuré
- [ ] Application déployée et fonctionnelle
- [ ] SSL configuré (si domaine)
- [ ] Tests de fonctionnalité effectués
- [ ] Sauvegarde configurée

## 🎯 Prochaines Étapes

1. **Upload de documents** via l'interface web
2. **Test du chat** avec vos documents
3. **Configuration de la sauvegarde** automatique
4. **Monitoring** des performances
5. **Optimisation** selon vos besoins

---

**🎉 Votre application BMI Chat est maintenant déployée et prête à l'emploi !** 