#!/bin/bash

# 🔧 Fix Nginx Configuration for BMI Chat
# This script configures Nginx to properly proxy to your Docker containers

set -e

echo "🔧 Fixing Nginx Configuration for BMI Chat"
echo "=========================================="

# Check if services are running
echo "📊 Checking Docker services..."
if curl -f http://localhost:3006/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy"
else
    echo "❌ Backend is not responding"
    exit 1
fi

if curl -f http://localhost:8095 > /dev/null 2>&1; then
    echo "✅ Frontend is healthy"
else
    echo "❌ Frontend is not responding"
    exit 1
fi

# Create Nginx configuration
echo "📝 Creating Nginx configuration..."
sudo tee /etc/nginx/sites-available/bmi.engage-360.net > /dev/null << 'EOF'
server {
    listen 80;
    server_name bmi.engage-360.net www.bmi.engage-360.net;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name bmi.engage-360.net www.bmi.engage-360.net;

    # SSL Configuration (if you have certificates)
    # ssl_certificate /etc/letsencrypt/live/bmi.engage-360.net/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/bmi.engage-360.net/privkey.pem;
    
    # For now, we'll use HTTP (you can add SSL later)
    # Remove the SSL lines above and change listen 443 to listen 80 for HTTP only

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

# Enable the site
echo "🔗 Enabling Nginx site..."
sudo ln -sf /etc/nginx/sites-available/bmi.engage-360.net /etc/nginx/sites-enabled/

# Remove default site if it exists
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Reload Nginx
echo "🔄 Reloading Nginx..."
sudo systemctl reload nginx

# Test the configuration
echo "🧪 Testing the site..."
sleep 5

if curl -f https://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ Site is accessible via HTTPS"
elif curl -f http://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ Site is accessible via HTTP"
else
    echo "❌ Site is not accessible"
    echo "Testing local access..."
    curl -f http://localhost:8095
fi

echo ""
echo "🎉 Nginx configuration fixed!"
echo ""
echo "Your BMI Chat application should now be accessible at:"
echo "  https://bmi.engage-360.net"
echo "  http://bmi.engage-360.net (if HTTPS not configured)"
echo ""
echo "If you still get 502 errors, try:"
echo "1. Check DNS: nslookup bmi.engage-360.net"
echo "2. Check firewall: sudo ufw status"
echo "3. Check Nginx logs: sudo tail -f /var/log/nginx/error.log" 