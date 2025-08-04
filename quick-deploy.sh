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