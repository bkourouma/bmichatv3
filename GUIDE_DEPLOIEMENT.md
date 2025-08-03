# 🚀 Guide de Déploiement Automatisé

## 📋 **Étapes d'Exécution**

### **1. Connexion au Serveur**
```bash
ssh root@147.93.44.169
```

### **2. Exécution du Script Automatisé**
```bash
# Télécharger le script
wget https://raw.githubusercontent.com/bkourouma/bmichat/main/auto-deploy.sh

# Rendre exécutable et lancer
chmod +x auto-deploy.sh
./auto-deploy.sh
```

**⏱️ Temps d'exécution : ~15-20 minutes**

## 🔧 **Interventions Manuelles Requises**

### **1. Configuration de la Clé OpenAI** ⚠️
```bash
nano /var/www/bmichat/.env
```
**À faire :** Remplacez `sk-votre-clé-api-openai-à-configurer` par votre vraie clé OpenAI

### **2. Configuration SSL** ⚠️
```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d bmi-engage-360.net --non-interactive --agree-tos --email admin@engage-360.net
```

### **3. Pointage DNS** ⚠️
**Dans votre panneau DNS :**
- **Type :** A
- **Nom :** bmi-engage-360.net
- **Valeur :** 147.93.44.169
- **TTL :** 300

## ✅ **Tests de Vérification**

### **Tests Automatiques (après SSL)**
```bash
# Test de santé
curl https://bmi-engage-360.net/health

# Test de l'API
curl -X POST https://bmi-engage-360.net/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'
```

### **Tests Temporaires (avant SSL)**
```bash
# Test de santé
curl http://147.93.44.169:3006/health

# Test de l'API
curl -X POST http://147.93.44.169:3006/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"test"}'
```

## 🎯 **Commandes de Gestion**

```bash
cd /var/www/bmichat

# Statut des services
./deploy-vps.sh status

# Logs en temps réel
./deploy-vps.sh logs

# Sauvegarde manuelle
./deploy-vps.sh backup

# Mise à jour depuis Git
./deploy-vps.sh update
```

## 🌐 **URLs d'Accès**

### **Avant SSL (temporaire)**
- **Frontend :** http://147.93.44.169:3003
- **Backend :** http://147.93.44.169:3006
- **Health :** http://147.93.44.169:3006/health

### **Après SSL (final)**
- **Application :** https://bmi-engage-360.net
- **API :** https://bmi-engage-360.net/api/
- **Health :** https://bmi-engage-360.net/health

## 🚨 **En Cas de Problème**

### **Logs de Diagnostic**
```bash
# Logs du backend
docker logs bmi-chat-backend

# Logs du frontend
docker logs bmi-chat-frontend

# Statut des conteneurs
docker ps
```

### **Redémarrage des Services**
```bash
cd /var/www/bmichat
docker-compose -f deployment/docker/docker-compose.yml restart
```

## ✅ **Checklist Finale**

- [ ] Script auto-deploy.sh exécuté
- [ ] Clé OpenAI configurée dans .env
- [ ] SSL configuré avec Certbot
- [ ] DNS pointé vers l'IP du serveur
- [ ] Tests de santé réussis
- [ ] Tests de l'API réussis
- [ ] Application accessible via HTTPS

## 🎉 **Félicitations !**

Une fois toutes les étapes terminées, votre application BMI Chat sera accessible sur :
**https://bmi-engage-360.net**

Avec toutes les optimisations RAG implémentées ! 🚀 