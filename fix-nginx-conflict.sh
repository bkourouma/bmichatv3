#!/bin/bash

# 🔧 Fix Nginx Configuration Conflict
# This script identifies and fixes conflicting Nginx configurations

set -e

echo "🔧 Fixing Nginx Configuration Conflict"
echo "====================================="

# Check all Nginx configurations
echo "📊 Step 1: Checking all Nginx configurations..."
echo "Sites available:"
ls -la /etc/nginx/sites-available/

echo ""
echo "Sites enabled:"
ls -la /etc/nginx/sites-enabled/

# Find configurations that might conflict
echo ""
echo "📊 Step 2: Searching for conflicting configurations..."
sudo grep -r "bmi.engage-360.net" /etc/nginx/
sudo grep -r "agents.engage-360.net" /etc/nginx/
sudo grep -r "engage-360.net" /etc/nginx/

# Check what's listening on port 8092
echo ""
echo "📊 Step 3: Checking what's using port 8092..."
sudo netstat -tulpn | grep :8092

# Check our Docker containers
echo ""
echo "📊 Step 4: Checking Docker containers..."
docker-compose ps

# Test our local services
echo ""
echo "📊 Step 5: Testing local services..."
curl -f http://localhost:3006/health && echo "✅ Backend OK" || echo "❌ Backend FAILED"
curl -f http://localhost:8095 && echo "✅ Frontend OK" || echo "❌ Frontend FAILED"

# Create a new, clean configuration
echo ""
echo "📊 Step 6: Creating clean Nginx configuration..."
sudo tee /etc/nginx/sites-available/bmi.engage-360.net > /dev/null << 'EOF'
server {
    listen 80;
    server_name bmi.engage-360.net www.bmi.engage-360.net;
    
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
        proxy_pass http://localhost:3006/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
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

    # API documentation
    location /docs {
        proxy_pass http://localhost:3006/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Widget static files
    location /widget/ {
        proxy_pass http://localhost:8095/widget/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;
}
EOF

# Disable conflicting configurations
echo ""
echo "📊 Step 7: Disabling conflicting configurations..."
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/agents.engage-360.net 2>/dev/null || true
sudo rm -f /etc/nginx/sites-enabled/engage-360.net 2>/dev/null || true

# Enable our configuration
echo ""
echo "📊 Step 8: Enabling our configuration..."
sudo ln -sf /etc/nginx/sites-available/bmi.engage-360.net /etc/nginx/sites-enabled/

# Test Nginx configuration
echo ""
echo "📊 Step 9: Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Restart Nginx
echo ""
echo "🔄 Step 10: Restarting Nginx..."
sudo systemctl stop nginx
sleep 2
sudo systemctl start nginx
sleep 3

# Test the site
echo ""
echo "📊 Step 11: Testing the site..."
if curl -f http://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ Site is accessible"
else
    echo "❌ Site is not accessible"
    echo "Testing with verbose output:"
    curl -v http://bmi.engage-360.net
fi

echo ""
echo "🎉 Nginx configuration conflict fixed!"
echo ""
echo "Your BMI Chat application should now be accessible at:"
echo "  http://bmi.engage-360.net" 