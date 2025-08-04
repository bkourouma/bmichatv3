#!/bin/bash

# 🚀 Quick BMI Chat v2 Deployment Script
# Run this script on your Linux VPS to deploy the application

set -e

# Configuration
GIT_REPO="https://github.com/bkourouma/bmichatv2.git"
GIT_TOKEN="${GIT_TOKEN:-your_github_token_here}"
PROJECT_DIR="/opt/bmichat"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🚀 Quick BMI Chat v2 Deployment"
echo "================================"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    exit 1
fi

# Install dependencies if not present
print_status "Checking and installing dependencies..."

if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    print_warning "Please log out and back in for Docker group changes"
fi

if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create project directory
print_status "Setting up project directory..."
sudo mkdir -p $PROJECT_DIR
sudo chown $USER:$USER $PROJECT_DIR
cd $PROJECT_DIR

# Configure Git with token
print_status "Configuring Git authentication..."
git config --global credential.helper store
echo "https://$USER:$GIT_TOKEN@github.com" > ~/.git-credentials

# Clone or update repository
if [ -d ".git" ]; then
    print_status "Updating existing repository..."
    git pull origin main
else
    print_status "Cloning repository..."
    git clone $GIT_REPO .
fi

# Setup environment
print_status "Setting up environment..."
if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        cp env.example .env
        print_warning "Please edit .env file and configure your OpenAI API key:"
        echo "nano $PROJECT_DIR/.env"
        print_warning "Required: OPENAI_API_KEY and SECRET_KEY"
    else
        print_error "env.example file not found"
        exit 1
    fi
fi

# Create necessary directories
mkdir -p data/sqlite data/uploads data/vectors logs

# Deploy application
print_status "Deploying application..."
docker-compose down --remove-orphans 2>/dev/null || true
docker-compose up -d --build

# Wait for services
print_status "Waiting for services to start..."
sleep 30

# Health checks
print_status "Running health checks..."

if curl -f http://localhost:3006/health > /dev/null 2>&1; then
    print_success "Backend is healthy"
else
    print_error "Backend health check failed"
    docker-compose logs backend
    exit 1
fi

if curl -f http://localhost:8095 > /dev/null 2>&1; then
    print_success "Frontend is healthy"
else
    print_error "Frontend health check failed"
    docker-compose logs frontend
    exit 1
fi

# Show results
echo ""
print_success "🎉 Deployment completed successfully!"
echo ""
print_status "Your BMI Chat application is now running:"
echo "  Frontend: http://$(hostname -I | awk '{print $1}'):8095"
echo "  Backend API: http://$(hostname -I | awk '{print $1}'):3006"
echo "  API Docs: http://$(hostname -I | awk '{print $1}'):3006/docs"
echo "  Health Check: http://$(hostname -I | awk '{print $1}'):3006/health"
echo ""
print_status "Useful commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Restart services: docker-compose restart"
echo "  Check status: docker-compose ps"
echo ""
print_warning "Don't forget to configure your OpenAI API key in the .env file!" 