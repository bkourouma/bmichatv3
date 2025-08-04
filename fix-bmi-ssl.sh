#!/bin/bash

# 🔧 Fix BMI Chat SSL Configuration Conflict
# This script fixes the SSL configuration conflict for bmi.engage-360.net

set -e

echo "🔧 Fixing BMI Chat SSL Configuration"
echo "==================================="

# Check current configurations
echo "📊 Step 1: Checking current configurations..."
ls -la /etc/nginx/sites-enabled/

# Check what's enabled
echo ""
echo "📊 Step 2: Checking enabled configurations..."
for config in /etc/nginx/sites-enabled/*; do
    if [ -L "$config" ]; then
        echo "=== $(basename $config) ==="
        sudo grep -E "(server_name|listen)" "$config" || echo "No server_name or listen found"
        echo ""
    fi
done

# Check the conflicting bmichat.conf
echo ""
echo "📊 Step 3: Checking conflicting bmichat.conf..."
if [ -f "/etc/nginx/sites-available/bmichat.conf" ]; then
    echo "Found bmichat.conf:"
    sudo cat /etc/nginx/sites-available/bmichat.conf
else
    echo "No bmichat.conf found"
fi

# Check SSL certificates
echo ""
echo "📊 Step 4: Checking SSL certificates..."
if [ -f "/etc/letsencrypt/live/bmi.engage-360.net/fullchain.pem" ]; then
    echo "✅ SSL certificate exists for bmi.engage-360.net"
else
    echo "❌ SSL certificate not found for bmi.engage-360.net"
fi

# Test our Docker services
echo ""
echo "📊 Step 5: Testing our Docker services..."
docker-compose ps
curl -f http://localhost:3006/health && echo "✅ Backend OK" || echo "❌ Backend FAILED"
curl -f http://localhost:8095 && echo "✅ Frontend OK" || echo "❌ Frontend FAILED"

# Disable the conflicting bmichat.conf
echo ""
echo "📊 Step 6: Disabling conflicting bmichat.conf..."
if [ -L "/etc/nginx/sites-enabled/bmichat.conf" ]; then
    sudo rm /etc/nginx/sites-enabled/bmichat.conf
    echo "✅ Disabled bmichat.conf"
else
    echo "bmichat.conf not enabled"
fi

# Create a proper SSL configuration for BMI Chat
echo ""
echo "📊 Step 7: Creating proper SSL configuration for BMI Chat..."
sudo tee /etc/nginx/sites-available/bmi.engage-360.net > /dev/null << 'EOF'
# BMI Chat Configuration with SSL
server {
    listen 80;
    server_name bmi.engage-360.net www.bmi.engage-360.net;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name bmi.engage-360.net www.bmi.engage-360.net;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/bmi.engage-360.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/bmi.engage-360.net/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

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

# Enable our configuration
echo ""
echo "📊 Step 8: Enabling BMI Chat configuration..."
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

# Reload Nginx
echo ""
echo "🔄 Step 10: Reloading Nginx configuration..."
sudo systemctl reload nginx

# Test the site
echo ""
echo "📊 Step 11: Testing BMI Chat site..."
if curl -f https://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ BMI Chat site is accessible via HTTPS"
elif curl -f http://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ BMI Chat site is accessible via HTTP"
else
    echo "❌ BMI Chat site is not accessible"
    echo "Testing with verbose output:"
    curl -v https://bmi.engage-360.net
fi

# Test other apps still work
echo ""
echo "📊 Step 12: Testing other apps..."
echo "Testing imhotepformation.engage-360.net..."
curl -f https://imhotepformation.engage-360.net > /dev/null 2>&1 && echo "✅ imhotepformation.engage-360.net OK" || echo "❌ imhotepformation.engage-360.net FAILED"

echo ""
echo "🎉 BMI Chat SSL configuration fixed!"
echo ""
echo "Your BMI Chat application should now be accessible at:"
echo "  https://bmi.engage-360.net"
echo ""
echo "If you still get 502 errors, check:"
echo "1. SSL certificate: sudo certbot certificates"
echo "2. Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "3. Docker logs: docker-compose logs -f" 