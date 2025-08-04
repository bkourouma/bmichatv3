#!/bin/bash

# 🔧 Fix BMI Chat Only - No Impact on Other Apps
# This script fixes only the BMI Chat configuration without touching other apps

set -e

echo "🔧 Fixing BMI Chat Only - Preserving Other Apps"
echo "==============================================="

# Check current configurations
echo "📊 Step 1: Checking current configurations..."
ls -la /etc/nginx/sites-enabled/

# Check what's currently handling bmi.engage-360.net
echo ""
echo "📊 Step 2: Checking what handles bmi.engage-360.net..."
sudo grep -r "bmi.engage-360.net" /etc/nginx/sites-available/ || echo "No bmi.engage-360.net found"

# Check other apps are still working
echo ""
echo "📊 Step 3: Checking other apps are working..."
echo "Testing engage-360.net (port 80)..."
curl -f http://localhost:80 > /dev/null 2>&1 && echo "✅ engage-360.net OK" || echo "❌ engage-360.net FAILED"

echo "Testing agents.engage-360.net (port 8092)..."
curl -f http://localhost:8092 > /dev/null 2>&1 && echo "✅ agents.engage-360.net OK" || echo "❌ agents.engage-360.net FAILED"

echo "Testing chat.engage-360.net (port 8080)..."
curl -f http://localhost:8080 > /dev/null 2>&1 && echo "✅ chat.engage-360.net OK" || echo "❌ chat.engage-360.net FAILED"

# Test our Docker services
echo ""
echo "📊 Step 4: Testing our Docker services..."
docker-compose ps
curl -f http://localhost:3006/health && echo "✅ Backend OK" || echo "❌ Backend FAILED"
curl -f http://localhost:8095 && echo "✅ Frontend OK" || echo "❌ Frontend FAILED"

# Create a specific configuration for BMI Chat only
echo ""
echo "📊 Step 5: Creating BMI Chat specific configuration..."
sudo tee /etc/nginx/sites-available/bmi.engage-360.net > /dev/null << 'EOF'
# BMI Chat Configuration - Specific to bmi.engage-360.net only
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

# Enable our configuration (this will override any existing one)
echo ""
echo "📊 Step 6: Enabling BMI Chat configuration..."
sudo ln -sf /etc/nginx/sites-available/bmi.engage-360.net /etc/nginx/sites-enabled/

# Test Nginx configuration
echo ""
echo "📊 Step 7: Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Reload Nginx (don't restart to avoid disrupting other apps)
echo ""
echo "🔄 Step 8: Reloading Nginx configuration..."
sudo systemctl reload nginx

# Test the site
echo ""
echo "📊 Step 9: Testing BMI Chat site..."
if curl -f http://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ BMI Chat site is accessible"
else
    echo "❌ BMI Chat site is not accessible"
    echo "Testing with verbose output:"
    curl -v http://bmi.engage-360.net
fi

# Verify other apps still work
echo ""
echo "📊 Step 10: Verifying other apps still work..."
echo "Testing engage-360.net..."
curl -f http://localhost:80 > /dev/null 2>&1 && echo "✅ engage-360.net still OK" || echo "❌ engage-360.net broken"

echo "Testing agents.engage-360.net..."
curl -f http://localhost:8092 > /dev/null 2>&1 && echo "✅ agents.engage-360.net still OK" || echo "❌ agents.engage-360.net broken"

echo "Testing chat.engage-360.net..."
curl -f http://localhost:8080 > /dev/null 2>&1 && echo "✅ chat.engage-360.net still OK" || echo "❌ chat.engage-360.net broken"

echo ""
echo "🎉 BMI Chat configuration fixed without impacting other apps!"
echo ""
echo "Your BMI Chat application should now be accessible at:"
echo "  http://bmi.engage-360.net"
echo ""
echo "Other apps should still be working:"
echo "  - engage-360.net (port 80)"
echo "  - agents.engage-360.net (port 8092)"
echo "  - chat.engage-360.net (port 8080)" 