#!/bin/bash

# 🔧 Troubleshoot 502 Bad Gateway Error
# Run this script to diagnose and fix the 502 error

set -e

echo "🔧 Troubleshooting 502 Bad Gateway Error"
echo "======================================="

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Not in project directory. Navigating to /opt/bmichat..."
    cd /opt/bmichat
fi

echo ""
echo "📊 Step 1: Checking Docker containers..."
docker-compose ps

echo ""
echo "📊 Step 2: Checking container logs..."
echo "Backend logs:"
docker-compose logs backend --tail=20

echo ""
echo "Frontend logs:"
docker-compose logs frontend --tail=20

echo ""
echo "📊 Step 3: Checking if services are responding..."
echo "Testing backend health:"
if curl -f http://localhost:3006/health > /dev/null 2>&1; then
    echo "✅ Backend is responding"
else
    echo "❌ Backend is not responding"
fi

echo "Testing frontend:"
if curl -f http://localhost:8095 > /dev/null 2>&1; then
    echo "✅ Frontend is responding"
else
    echo "❌ Frontend is not responding"
fi

echo ""
echo "📊 Step 4: Checking port usage..."
netstat -tulpn | grep -E ':(3006|8095|80|443)'

echo ""
echo "📊 Step 5: Checking Nginx configuration..."
if [ -f "/etc/nginx/sites-available/bmi.engage-360.net" ]; then
    echo "Nginx config found:"
    cat /etc/nginx/sites-available/bmi.engage-360.net
else
    echo "❌ Nginx config not found"
fi

echo ""
echo "🔧 Fix Commands:"
echo "1. Restart services: docker-compose restart"
echo "2. Rebuild services: docker-compose up -d --build"
echo "3. Check logs: docker-compose logs -f"
echo "4. Test locally: curl http://localhost:3006/health"
echo "5. Check Nginx: sudo nginx -t && sudo systemctl reload nginx" 