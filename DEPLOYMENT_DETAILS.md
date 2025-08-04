# Guide de Déploiement Détaillé - BMI Chat

## 📋 Vue d'ensemble de l'Architecture

L'application BMI Chat utilise une architecture microservices avec :
- **Backend** : FastAPI (Python) sur port 3006
- **Frontend** : React (TypeScript) sur port 8095
- **Base de données** : SQLite + ChromaDB (vecteurs)
- **Proxy** : Nginx pour le routage et SSL
- **Conteneurisation** : Docker Compose

## 🐳 Configuration Docker

### Docker Compose (`docker-compose.yml`)

```yaml
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
```

### Dockerfile Backend (`deployment/docker/Dockerfile.backend`)

```dockerfile
FROM python:3.11-slim

# Créer l'utilisateur non-root
RUN useradd --create-home --shell /bin/bash appuser

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY pyproject.toml poetry.lock ./

# Installer Poetry et les dépendances
RUN pip install poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-dev

# Copier le code source
COPY app/ ./app/
COPY deployment/ ./deployment/

# Créer les répertoires nécessaires
RUN mkdir -p /app/data /app/logs && \
    chown -R appuser:appuser /app

# Changer vers l'utilisateur non-root
USER appuser

# Exposer le port
EXPOSE 3006

# Commande de démarrage
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "3006"]
```

### Dockerfile Frontend (`deployment/docker/Dockerfile.frontend`)

```dockerfile
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
```

## 🌐 Configuration Nginx

### Configuration Principale (`/etc/nginx/sites-available/bmi.engage-360.net`)

```nginx
# BMI Chat Configuration avec SSL
server {
    listen 80;
    server_name bmi.engage-360.net www.bmi.engage-360.net;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name bmi.engage-360.net www.bmi.engage-360.net;

    # Configuration SSL
    ssl_certificate /etc/letsencrypt/live/bmi.engage-360.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/bmi.engage-360.net/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Headers de sécurité
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Frontend (React app)
    location / {
        proxy_pass http://localhost:8095;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:3006;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Headers CORS
        add_header Access-Control-Allow-Origin "https://bmi.engage-360.net" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;

        # Gestion des requêtes preflight
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

    # Health check
    location /health {
        proxy_pass http://localhost:3006/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        access_log off;
    }

    # Documentation API
    location /docs {
        proxy_pass http://localhost:3006/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Widget statique
    location /widget/ {
        proxy_pass http://localhost:8095/widget/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Compression Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
}
```

## 🔧 Variables d'Environnement

### Fichier `.env` (Backend)

```bash
# Configuration de base
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO

# Base de données
DATABASE_URL=sqlite:///./data/bmi_chat.db

# API Keys
OPENAI_API_KEY=your_openai_api_key_here

# Configuration CORS
CORS_ORIGINS=["https://bmi.engage-360.net","https://www.bmi.engage-360.net"]

# Configuration ChromaDB
CHROMA_PERSIST_DIRECTORY=/app/data/vectors
CHROMA_COLLECTION_NAME=bmi_documents

# Configuration des embeddings
EMBEDDING_MODEL=text-embedding-3-small
EMBEDDING_DIMENSION=1536

# Configuration du chat
CHAT_MODEL=gpt-4o
MAX_TOKENS=4000
TEMPERATURE=0.7

# Configuration de recherche
MIN_RELEVANCE_SCORE=0.3
MAX_CHUNKS_PER_QUERY=5
USE_RERANKING=true

# Configuration des logs
LOG_FILE=/app/logs/bmi_chat.log
LOG_FORMAT=json
```

### Fichier `.env.production` (Frontend)

```bash
VITE_API_URL=https://bmi.engage-360.net
VITE_WS_URL=wss://bmi.engage-360.net/ws
```

## 🚀 Scripts de Déploiement

### Script Principal (`deploy.sh`)

```bash
#!/bin/bash

echo "🚀 Déploiement BMI Chat"
echo "========================"

# 1. Vérifier les prérequis
echo "📋 Vérification des prérequis..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé"
    exit 1
fi

# 2. Arrêter les conteneurs existants
echo "🛑 Arrêt des conteneurs existants..."
docker-compose down

# 3. Reconstruire les images
echo "🔨 Reconstruction des images..."
docker-compose build --no-cache

# 4. Démarrer les services
echo "▶️ Démarrage des services..."
docker-compose up -d

# 5. Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 30

# 6. Vérifier la santé des services
echo "🔍 Vérification de la santé des services..."
if curl -f http://localhost:3006/health > /dev/null 2>&1; then
    echo "✅ Backend en ligne"
else
    echo "❌ Backend hors ligne"
    exit 1
fi

if curl -f http://localhost:8095 > /dev/null 2>&1; then
    echo "✅ Frontend en ligne"
else
    echo "❌ Frontend hors ligne"
    exit 1
fi

echo "🎉 Déploiement terminé avec succès!"
```

### Script de Mise à Jour (`update.sh`)

```bash
#!/bin/bash

echo "🔄 Mise à jour BMI Chat"
echo "========================"

# 1. Sauvegarder les données
echo "💾 Sauvegarde des données..."
cp -r data data_backup_$(date +%Y%m%d_%H%M%S)

# 2. Récupérer les dernières modifications
echo "📥 Récupération des dernières modifications..."
git pull origin main

# 3. Redéployer
echo "🚀 Redéploiement..."
./deploy.sh

# 4. Vérifier la migration des données
echo "🔍 Vérification de la migration..."
if [ -d "data_backup_$(date +%Y%m%d_%H%M%S)" ]; then
    echo "✅ Sauvegarde créée"
else
    echo "❌ Échec de la sauvegarde"
fi

echo "🎉 Mise à jour terminée!"
```

## 📊 API Endpoints

### Endpoints Principaux

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/health` | GET | Vérification de santé |
| `/api/search/semantic` | POST | Recherche sémantique |
| `/api/search/direct` | POST | Recherche directe |
| `/api/documents` | GET | Liste des documents |
| `/api/documents` | POST | Ajouter un document |
| `/api/chat` | POST | Chat avec l'IA |
| `/docs` | GET | Documentation API |

### Exemple de Requête de Recherche

```bash
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "BMI-WFS",
    "k": 5,
    "min_score": 0.0
  }'
```

## 🔍 Monitoring et Debugging

### Commandes Utiles

```bash
# Vérifier l'état des conteneurs
docker-compose ps

# Voir les logs du backend
docker-compose logs -f backend

# Voir les logs du frontend
docker-compose logs -f frontend

# Accéder au shell du backend
docker exec -it bmi-chat-backend bash

# Vérifier la santé des services
curl http://localhost:3006/health
curl http://localhost:8095

# Vérifier la configuration Nginx
sudo nginx -t
sudo systemctl reload nginx

# Voir les logs Nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Scripts de Debug

```bash
# Debug de la recherche
curl -X POST "https://bmi.engage-360.net/api/search/semantic" \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "k": 5, "min_score": 0.0}' | jq '.'

# Debug de ChromaDB
docker exec bmi-chat-backend python -c "
from app.services.vector_service import VectorService
vs = VectorService()
results = vs.search_similar_chunks('test', k=5)
print(f'Found {len(results.get(\"chunks\", []))} chunks')
"
```

## 🔧 Maintenance

### Sauvegarde des Données

```bash
# Sauvegarder la base de données
cp data/bmi_chat.db data/bmi_chat_backup_$(date +%Y%m%d_%H%M%S).db

# Sauvegarder les vecteurs
tar -czf data/vectors_backup_$(date +%Y%m%d_%H%M%S).tar.gz data/vectors/

# Sauvegarder les logs
tar -czf logs_backup_$(date +%Y%m%d_%H%M%S).tar.gz logs/
```

### Nettoyage

```bash
# Nettoyer les images Docker non utilisées
docker image prune -f

# Nettoyer les conteneurs arrêtés
docker container prune -f

# Nettoyer les volumes non utilisés
docker volume prune -f
```

## 🚨 Dépannage

### Problèmes Courants

1. **502 Bad Gateway**
   - Vérifier que les conteneurs sont en cours d'exécution
   - Vérifier la configuration Nginx
   - Vérifier les logs Nginx

2. **CORS Errors**
   - Vérifier la configuration CORS dans le backend
   - Vérifier les headers dans Nginx

3. **ChromaDB Errors**
   - Vérifier les permissions sur `/app/data/vectors`
   - Redémarrer le backend
   - Recréer la base de vecteurs si nécessaire

4. **Search Returns 0 Results**
   - Vérifier que les documents sont indexés
   - Vérifier les scores de similarité
   - Ajuster `min_relevance_score`

### Scripts de Réparation

```bash
# Réparer ChromaDB
docker exec bmi-chat-backend rm -rf /app/data/vectors
docker-compose restart backend

# Réparer Nginx
sudo nginx -t && sudo systemctl reload nginx

# Réparer les permissions
sudo chown -R 1000:1000 data/ logs/
```

## 📝 Notes Importantes

1. **Ports Utilisés** :
   - 3006 : Backend API
   - 8095 : Frontend React
   - 80/443 : Nginx (HTTP/HTTPS)

2. **Volumes Docker** :
   - `./data` : Base de données et vecteurs
   - `./logs` : Fichiers de logs

3. **Sécurité** :
   - Utilisateur non-root dans les conteneurs
   - SSL/TLS obligatoire
   - Headers de sécurité configurés

4. **Performance** :
   - Compression Gzip activée
   - Cache Nginx configuré
   - Health checks activés

Ce guide couvre tous les aspects techniques du déploiement pour faciliter les mises à jour futures ! 🎯 