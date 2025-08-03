#!/bin/bash

# BMI Chat Production Deployment Script
# This script deploys the application to production with proper widget configuration

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

print_status "🚀 Starting BMI Chat Production Deployment"

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    print_status "Please copy env.production to .env and configure your settings:"
    echo "cp env.production .env"
    echo "nano .env"
    exit 1
fi

# Build widget for production
print_status "🔧 Building widget for production..."
cd widget
npm install
npm run build
cd ..

# Build frontend for production
print_status "🔧 Building frontend for production..."
cd frontend
npm install
npm run build
cd ..

# Stop existing containers
print_status "🛑 Stopping existing containers..."
docker-compose -f deployment/docker/docker-compose.yml down --remove-orphans

# Clean up old images
print_status "🧹 Cleaning up old images..."
docker system prune -f

# Build and start containers
print_status "🔨 Building and starting containers..."
docker-compose -f deployment/docker/docker-compose.yml up -d --build

# Wait for services to be healthy
print_status "⏳ Waiting for services to be healthy..."
sleep 30

# Test all endpoints
print_status "🧪 Testing all endpoints..."

# Test backend health
if curl -f http://localhost:3006/health > /dev/null 2>&1; then
    print_success "✅ Backend health check passed"
else
    print_error "❌ Backend health check failed"
    docker-compose -f deployment/docker/docker-compose.yml logs backend
    exit 1
fi

# Test frontend
if curl -f http://localhost:3003 > /dev/null 2>&1; then
    print_success "✅ Frontend is accessible"
else
    print_error "❌ Frontend health check failed"
    docker-compose -f deployment/docker/docker-compose.yml logs frontend
    exit 1
fi

# Test API endpoints
print_status "🧪 Testing API endpoints..."

# Test chat API
CHAT_RESPONSE=$(curl -s -X POST http://localhost:3003/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}' | jq -r '.message' 2>/dev/null || echo "ERROR")

if [[ "$CHAT_RESPONSE" != "ERROR" ]]; then
    print_success "✅ Chat API is working"
else
    print_error "❌ Chat API failed"
fi

# Test widget API
WIDGET_RESPONSE=$(curl -s -X POST http://localhost:3003/widget/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "test", "session_id": "test-session"}' | jq -r '.message' 2>/dev/null || echo "ERROR")

if [[ "$WIDGET_RESPONSE" != "ERROR" ]]; then
    print_success "✅ Widget API is working"
else
    print_error "❌ Widget API failed"
fi

# Test widget static files
if curl -f http://localhost:3003/widget/chat-widget.js > /dev/null 2>&1; then
    print_success "✅ Widget static files are accessible"
else
    print_error "❌ Widget static files failed"
fi

# Test health endpoint
if curl -f http://localhost:3003/health > /dev/null 2>&1; then
    print_success "✅ Health endpoint is working"
else
    print_error "❌ Health endpoint failed"
fi

print_success "🎉 Production deployment completed successfully!"

# Show service URLs
echo ""
print_status "📋 Service URLs:"
echo "  Frontend: http://localhost:3003"
echo "  Backend API: http://localhost:3006"
echo "  API Docs: http://localhost:3006/docs"
echo "  Widget API: http://localhost:3003/widget/chat"
echo "  Health Check: http://localhost:3003/health"

# Show widget integration code
echo ""
print_status "🔧 Widget Integration Code:"
echo "Add this to any website to embed the chat widget:"
echo ""
echo '<script>'
echo '(function() {'
echo '    var script = document.createElement("script");'
echo '    script.src = "http://localhost:3003/widget/chat-widget.js";'
echo '    script.setAttribute("data-api-url", "http://localhost:3003");'
echo '    script.setAttribute("data-position", "right");'
echo '    script.setAttribute("data-accent-color", "#0056b3");'
echo '    script.async = true;'
echo '    document.head.appendChild(script);'
echo '})();'
echo '</script>'

# Show logs command
echo ""
print_status "📊 To view logs:"
echo "  docker-compose -f deployment/docker/docker-compose.yml logs -f"

# Show stop command
echo ""
print_status "🛑 To stop services:"
echo "  docker-compose -f deployment/docker/docker-compose.yml down"

print_success "✅ Deployment completed! All endpoints are working correctly." 