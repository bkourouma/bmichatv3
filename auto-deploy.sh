#!/bin/bash

# 🚀 Automated BMI Chat Deployment Script
# This script handles Git authentication and deploys the updated application

set -e

# Configuration
GIT_REPO="https://github.com/bkourouma/bmichatv2.git"
GIT_TOKEN="${GIT_TOKEN:-your_github_token_here}"
PROJECT_DIR="/opt/bmichat"
BACKUP_DIR="/opt/backups/bmichat"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi
    
    print_success "Prerequisites checked"
}

# Function to create backup
create_backup() {
    print_status "Creating backup of current data..."
    
    mkdir -p $BACKUP_DIR
    DATE=$(date +%Y%m%d_%H%M%S)
    
    if [ -d "$PROJECT_DIR" ]; then
        cd $PROJECT_DIR
        
        # Backup data directory if it exists
        if [ -d "data" ]; then
            tar -czf $BACKUP_DIR/data_backup_$DATE.tar.gz data/
            print_success "Data backup created: $BACKUP_DIR/data_backup_$DATE.tar.gz"
        fi
        
        # Backup .env file if it exists
        if [ -f ".env" ]; then
            cp .env $BACKUP_DIR/.env_backup_$DATE
            print_success "Environment backup created: $BACKUP_DIR/.env_backup_$DATE"
        fi
    else
        print_warning "No existing project directory found, skipping backup"
    fi
}

# Function to clone or update repository
update_repository() {
    print_status "Updating repository..."
    
    # Create project directory if it doesn't exist
    sudo mkdir -p $PROJECT_DIR
    sudo chown $USER:$USER $PROJECT_DIR
    cd $PROJECT_DIR
    
    # Configure Git with token authentication
    git config --global credential.helper store
    echo "https://$USER:$GIT_TOKEN@github.com" > ~/.git-credentials
    
    if [ -d ".git" ]; then
        print_status "Repository exists, pulling latest changes..."
        git pull origin main
    else
        print_status "Cloning repository..."
        git clone $GIT_REPO .
    fi
    
    print_success "Repository updated"
}

# Function to setup environment
setup_environment() {
    print_status "Setting up environment..."
    
    cd $PROJECT_DIR
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        print_status "Creating .env file from template..."
        if [ -f "env.example" ]; then
            cp env.example .env
            print_warning "Please edit .env file and configure your settings:"
            echo "nano $PROJECT_DIR/.env"
        else
            print_error "env.example file not found"
            exit 1
        fi
    else
        print_status "Using existing .env file"
    fi
    
    # Create necessary directories
    mkdir -p data/sqlite data/uploads data/vectors logs
    
    print_success "Environment setup completed"
}

# Function to deploy application
deploy_application() {
    print_status "Deploying application..."
    
    cd $PROJECT_DIR
    
    # Stop existing containers
    print_status "Stopping existing containers..."
    docker-compose down --remove-orphans 2>/dev/null || true
    
    # Build and start containers
    print_status "Building and starting containers..."
    docker-compose up -d --build
    
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
        docker-compose logs backend
        exit 1
    fi
    
    # Check frontend
    if curl -f http://localhost:8095 > /dev/null 2>&1; then
        print_success "Frontend is healthy"
    else
        print_error "Frontend health check failed"
        docker-compose logs frontend
        exit 1
    fi
    
    print_success "Deployment completed successfully!"
}

# Function to show deployment info
show_deployment_info() {
    echo ""
    print_status "Deployment Information:"
    echo "  Backend API: http://localhost:3006"
    echo "  Frontend: http://localhost:8095"
    echo "  API Docs: http://localhost:3006/docs"
    echo "  Health Check: http://localhost:3006/health"
    echo ""
    print_status "Useful commands:"
    echo "  View logs: docker-compose logs -f"
    echo "  Stop services: docker-compose down"
    echo "  Restart services: docker-compose restart"
    echo "  Check status: docker-compose ps"
}

# Function to test endpoints
test_endpoints() {
    print_status "Testing endpoints..."
    
    # Test health endpoint
    if curl -f http://localhost:3006/health > /dev/null 2>&1; then
        print_success "Health endpoint: OK"
    else
        print_error "Health endpoint: FAILED"
    fi
    
    # Test API docs
    if curl -f http://localhost:3006/docs > /dev/null 2>&1; then
        print_success "API docs: OK"
    else
        print_error "API docs: FAILED"
    fi
    
    # Test frontend
    if curl -f http://localhost:8095 > /dev/null 2>&1; then
        print_success "Frontend: OK"
    else
        print_error "Frontend: FAILED"
    fi
}

# Main deployment function
main() {
    print_status "Starting automated deployment..."
    
    # Check if not running as root
    check_root
    
    # Check prerequisites
    check_prerequisites
    
    # Create backup
    create_backup
    
    # Update repository
    update_repository
    
    # Setup environment
    setup_environment
    
    # Deploy application
    deploy_application
    
    # Test endpoints
    test_endpoints
    
    # Show deployment info
    show_deployment_info
    
    print_success "🎉 Deployment completed successfully!"
    print_status "Your BMI Chat application is now running!"
}

# Run main function
main "$@" 