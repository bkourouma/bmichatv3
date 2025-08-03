#!/bin/bash

# BMI Chat Deployment Script for Hostinger VPS
# Usage: ./deploy.sh [dev|prod]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    print_status "Please copy env.example to .env and configure your settings:"
    echo "cp env.example .env"
    echo "nano .env"
    exit 1
fi

# Determine environment
ENVIRONMENT=${1:-prod}
COMPOSE_FILE="docker-compose.yml"

if [ "$ENVIRONMENT" = "dev" ]; then
    COMPOSE_FILE="docker-compose.dev.yml"
    print_status "Deploying in DEVELOPMENT mode"
else
    print_status "Deploying in PRODUCTION mode"
fi

print_status "Using compose file: $COMPOSE_FILE"

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose -f $COMPOSE_FILE down --remove-orphans

# Pull latest changes (if using git)
if [ -d .git ]; then
    print_status "Pulling latest changes..."
    git pull origin main
fi

# Build and start containers
print_status "Building and starting containers..."
docker-compose -f $COMPOSE_FILE up -d --build

# Wait for services to be healthy
print_status "Waiting for services to be healthy..."
sleep 30

# Check service health
print_status "Checking service health..."

# Check backend
if curl -f http://localhost:3006/health > /dev/null 2>&1; then
    print_success "Backend is healthy"
else
    print_error "Backend health check failed"
    docker-compose -f $COMPOSE_FILE logs backend
    exit 1
fi

# Check frontend (only in production)
if [ "$ENVIRONMENT" != "dev" ]; then
    if curl -f http://localhost:8095 > /dev/null 2>&1; then
        print_success "Frontend is healthy"
    else
        print_error "Frontend health check failed"
        docker-compose -f $COMPOSE_FILE logs frontend
        exit 1
    fi
fi

print_success "Deployment completed successfully!"

# Show service URLs
echo ""
print_status "Service URLs:"
echo "  Backend API: http://localhost:3006"
if [ "$ENVIRONMENT" != "dev" ]; then
    echo "  Frontend: http://localhost:8095"
    echo "  API Docs: http://localhost:3006/docs"
else
    echo "  Frontend: http://localhost:3003"
    echo "  API Docs: http://localhost:3006/docs"
fi

# Show logs command
echo ""
print_status "To view logs:"
echo "  docker-compose -f $COMPOSE_FILE logs -f"

# Show stop command
echo ""
print_status "To stop services:"
echo "  docker-compose -f $COMPOSE_FILE down" 