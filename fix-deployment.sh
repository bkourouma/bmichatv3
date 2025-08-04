#!/bin/bash

# 🔧 Fix BMI Chat Deployment Container Conflict
# Run this script to resolve container name conflicts

set -e

echo "🔧 Fixing BMI Chat Deployment"
echo "============================="

# Stop and remove existing containers
echo "Stopping existing containers..."
docker stop bmi-chat-backend bmi-chat-frontend 2>/dev/null || true
docker rm bmi-chat-backend bmi-chat-frontend 2>/dev/null || true

# Remove all containers with bmi-chat prefix
echo "Removing all BMI Chat containers..."
docker ps -a --filter "name=bmi-chat" --format "{{.ID}}" | xargs -r docker rm -f

# Clean up any orphaned containers
echo "Cleaning up orphaned containers..."
docker container prune -f

# Navigate to project directory
cd /opt/bmichat

# Deploy application
echo "Deploying application..."
docker-compose down --remove-orphans
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
echo "🎉 Deployment fixed successfully!"
echo ""
echo "Your BMI Chat application is now running:"
echo "  Frontend: http://$(hostname -I | awk '{print $1}'):8095"
echo "  Backend API: http://$(hostname -I | awk '{print $1}'):3006"
echo "  API Docs: http://$(hostname -I | awk '{print $1}'):3006/docs"
echo "  Health Check: http://$(hostname -I | awk '{print $1}'):3006/health"
echo ""
echo "Useful commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Restart services: docker-compose restart"
echo "  Check status: docker-compose ps" 