#!/bin/bash

# 🔧 Fix Port Conflict for BMI Chat
# This script checks and fixes port conflicts

set -e

echo "🔧 Fixing Port Conflict for BMI Chat"
echo "===================================="

# Check what's running on port 8095
echo "📊 Step 1: Checking what's running on port 8095..."
netstat -tlnp | grep :8095 || echo "No process found on port 8095"

echo ""
echo "📊 Step 2: Checking all listening ports..."
netstat -tlnp | grep LISTEN

# Check Docker containers and their ports
echo ""
echo "📊 Step 3: Checking Docker containers..."
docker-compose ps

# Check if frontend is actually accessible
echo ""
echo "📊 Step 4: Testing frontend accessibility..."
curl -f http://localhost:8095 && echo "✅ Frontend on 8095 OK" || echo "❌ Frontend on 8095 FAILED"

# Check if there are any other containers using port 8095
echo ""
echo "📊 Step 5: Checking for other containers using port 8095..."
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 8095 || echo "No other containers using port 8095"

# Check the docker-compose.yml file
echo ""
echo "📊 Step 6: Checking docker-compose.yml configuration..."
if [ -f "docker-compose.yml" ]; then
    echo "Frontend port configuration:"
    grep -A 5 -B 5 "8095" docker-compose.yml || echo "No 8095 found in docker-compose.yml"
else
    echo "❌ docker-compose.yml not found"
fi

# Check if there are any conflicting Nginx configurations
echo ""
echo "📊 Step 7: Checking for conflicting Nginx configurations..."
grep -r "8095" /etc/nginx/sites-available/ || echo "No 8095 found in Nginx configs"

# Test the current setup
echo ""
echo "📊 Step 8: Testing current setup..."
echo "Testing backend:"
curl -f http://localhost:3006/health && echo "✅ Backend OK" || echo "❌ Backend FAILED"

echo ""
echo "Testing frontend:"
curl -f http://localhost:8095 && echo "✅ Frontend OK" || echo "❌ Frontend FAILED"

echo ""
echo "Testing through Nginx:"
curl -f https://bmi.engage-360.net && echo "✅ Site through Nginx OK" || echo "❌ Site through Nginx FAILED"

# Check if we need to change the frontend port
echo ""
echo "📊 Step 9: Checking if we need to change frontend port..."
if ! curl -f http://localhost:8095 > /dev/null 2>&1; then
    echo "❌ Frontend not accessible on 8095, let's change it to 8096"
    
    # Update docker-compose.yml to use port 8096
    sed -i 's/8095:80/8096:80/g' docker-compose.yml
    
    # Update Nginx configuration to use port 8096
    sudo sed -i 's/localhost:8095/localhost:8096/g' /etc/nginx/sites-available/bmi.engage-360.net
    
    echo "✅ Updated docker-compose.yml and Nginx config to use port 8096"
    
    # Restart containers
    echo ""
    echo "🔄 Restarting containers with new port..."
    docker-compose down
    docker-compose up -d --build
    
    # Wait for services to be ready
    sleep 10
    
    # Test the new setup
    echo ""
    echo "📊 Step 10: Testing new setup..."
    echo "Testing frontend on new port:"
    curl -f http://localhost:8096 && echo "✅ Frontend on 8096 OK" || echo "❌ Frontend on 8096 FAILED"
    
    echo ""
    echo "Testing through Nginx with new port:"
    curl -f https://bmi.engage-360.net && echo "✅ Site through Nginx OK" || echo "❌ Site through Nginx FAILED"
    
    # Reload Nginx
    sudo systemctl reload nginx
    
else
    echo "✅ Frontend is accessible on 8095"
fi

# Final test of API endpoints
echo ""
echo "📊 Step 11: Final API endpoint tests..."
curl -f https://bmi.engage-360.net/health && echo "✅ Health OK" || echo "❌ Health FAILED"
curl -f https://bmi.engage-360.net/api/search/stats && echo "✅ API stats OK" || echo "❌ API stats FAILED"
curl -f "https://bmi.engage-360.net/api/documents?skip=0&limit=10" && echo "✅ API documents OK" || echo "❌ API documents FAILED"

echo ""
echo "🎉 Port conflict should be resolved!"
echo ""
echo "Your BMI Chat application should now work correctly at:"
echo "  https://bmi.engage-360.net"
echo ""
echo "If you still have issues, check:"
echo "1. Docker logs: docker-compose logs -f"
echo "2. Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "3. Port usage: netstat -tlnp | grep LISTEN" 