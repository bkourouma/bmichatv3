#!/bin/bash

# 🚀 BMI Chat v2 Server Deployment Script
# Create this file directly on your server

set -e

echo "🚀 BMI Chat v2 Deployment"
echo "========================"

# Install dependencies
echo "Installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create project directory
echo "Setting up project directory..."
sudo mkdir -p /opt/bmichat
sudo chown $USER:$USER /opt/bmichat
cd /opt/bmichat

# Clone repository
echo "Cloning repository..."
git clone https://github.com/bkourouma/bmichatv2.git .

# Setup environment
echo "Setting up environment..."
cp env.example .env
mkdir -p data/sqlite data/uploads data/vectors logs

# Deploy application
echo "Deploying application..."
docker-compose up -d --build

# Wait for services
echo "Waiting for services to start..."
sleep 30

# Test deployment
echo "Testing deployment..."
if curl -f http://localhost:3006/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend health check failed"
    docker-compose logs backend
    exit 1
fi

if curl -f http://localhost:8095 > /dev/null 2>&1; then
    echo "✅ Frontend is healthy"
else
    echo "❌ Frontend health check failed"
    docker-compose logs frontend
    exit 1
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "Your BMI Chat application is now running:"
echo "  Frontend: http://$(hostname -I | awk '{print $1}'):8095"
echo "  Backend API: http://$(hostname -I | awk '{print $1}'):3006"
echo "  API Docs: http://$(hostname -I | awk '{print $1}'):3006/docs"
echo "  Health Check: http://$(hostname -I | awk '{print $1}'):3006/health"
echo ""
echo "Next steps:"
echo "1. Configure your OpenAI API key: nano .env"
echo "2. Restart services: docker-compose restart"
echo ""
echo "Useful commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Restart services: docker-compose restart"
echo "  Check status: docker-compose ps" 