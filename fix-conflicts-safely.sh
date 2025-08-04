#!/bin/bash

# 🔧 Fix Nginx Conflicts Safely - Preserve Working Apps
# This script identifies and fixes conflicts without breaking working applications

set -e

echo "🔧 Fixing Nginx Conflicts Safely"
echo "================================"

# Check all configurations
echo "📊 Step 1: Checking all Nginx configurations..."
echo "Sites available:"
ls -la /etc/nginx/sites-available/

echo ""
echo "Sites enabled:"
ls -la /etc/nginx/sites-enabled/

# Check for conflicting configurations
echo ""
echo "📊 Step 2: Checking for conflicting configurations..."
sudo grep -r "bmi.engage-360.net" /etc/nginx/sites-available/
sudo grep -r "imhotepformation.engage-360.net" /etc/nginx/sites-available/

# Check what's currently working
echo ""
echo "📊 Step 3: Testing current applications..."
echo "Testing imhotepformation.engage-360.net..."
curl -f https://imhotepformation.engage-360.net > /dev/null 2>&1 && echo "✅ imhotepformation.engage-360.net OK" || echo "❌ imhotepformation.engage-360.net FAILED"

echo "Testing bmi.engage-360.net..."
curl -f http://bmi.engage-360.net > /dev/null 2>&1 && echo "✅ bmi.engage-360.net OK" || echo "❌ bmi.engage-360.net FAILED"

# Check our Docker services
echo ""
echo "📊 Step 4: Testing our Docker services..."
docker-compose ps
curl -f http://localhost:3006/health && echo "✅ Backend OK" || echo "❌ Backend FAILED"
curl -f http://localhost:8095 && echo "✅ Frontend OK" || echo "❌ Frontend FAILED"

# Check the conflicting bmichat.conf
echo ""
echo "📊 Step 5: Checking conflicting bmichat.conf..."
if [ -f "/etc/nginx/sites-available/bmichat.conf" ]; then
    echo "Found conflicting bmichat.conf:"
    sudo cat /etc/nginx/sites-available/bmichat.conf
else
    echo "No bmichat.conf found"
fi

# Disable the conflicting configuration
echo ""
echo "📊 Step 6: Disabling conflicting configuration..."
if [ -L "/etc/nginx/sites-enabled/bmichat.conf" ]; then
    sudo rm /etc/nginx/sites-enabled/bmichat.conf
    echo "✅ Disabled bmichat.conf"
fi

# Update our BMI Chat configuration to be more specific
echo ""
echo "📊 Step 7: Updating BMI Chat configuration..."
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

# Ensure our configuration is enabled
echo ""
echo "📊 Step 8: Ensuring BMI Chat configuration is enabled..."
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

# Reload Nginx (not restart to preserve other apps)
echo ""
echo "🔄 Step 10: Reloading Nginx configuration..."
sudo systemctl reload nginx

# Test all applications
echo ""
echo "📊 Step 11: Testing all applications..."
echo "Testing imhotepformation.engage-360.net..."
curl -f https://imhotepformation.engage-360.net > /dev/null 2>&1 && echo "✅ imhotepformation.engage-360.net OK" || echo "❌ imhotepformation.engage-360.net FAILED"

echo "Testing bmi.engage-360.net..."
curl -f http://bmi.engage-360.net > /dev/null 2>&1 && echo "✅ bmi.engage-360.net OK" || echo "❌ bmi.engage-360.net FAILED"

# Check what's listening on different ports
echo ""
echo "📊 Step 12: Checking port usage..."
sudo netstat -tulpn | grep -E ':(80|443|3001|3006|8095)' | head -10

echo ""
echo "🎉 Nginx conflicts fixed safely!"
echo ""
echo "Your applications should now be working:"
echo "  - BMI Chat: http://bmi.engage-360.net"
echo "  - Formations: https://imhotepformation.engage-360.net"
echo ""
echo "If any app is still broken, check:"
echo "1. PM2 status: pm2 status"
echo "2. Docker status: docker-compose ps"
echo "3. Nginx logs: sudo tail -f /var/log/nginx/error.log" 