#!/bin/bash

# 🔧 Fix API Routing Issue for BMI Chat
# This script fixes the 404 errors by correcting the Nginx API routing

set -e

echo "🔧 Fixing API Routing Issue for BMI Chat"
echo "========================================="

# Check current Nginx configuration
echo "📊 Step 1: Checking current Nginx configuration..."
if [ -f "/etc/nginx/sites-available/bmi.engage-360.net" ]; then
    echo "✅ BMI Chat Nginx config exists"
    echo "Current configuration:"
    sudo cat /etc/nginx/sites-available/bmi.engage-360.net
else
    echo "❌ BMI Chat Nginx config not found"
fi

# Check what's enabled
echo ""
echo "📊 Step 2: Checking enabled configurations..."
ls -la /etc/nginx/sites-enabled/

# Test current API endpoints
echo ""
echo "📊 Step 3: Testing current API endpoints..."
echo "Testing backend directly:"
curl -f http://localhost:3006/health && echo "✅ Backend direct OK" || echo "❌ Backend direct FAILED"

echo ""
echo "Testing through Nginx:"
curl -f https://bmi.engage-360.net/health && echo "✅ Health through Nginx OK" || echo "❌ Health through Nginx FAILED"
curl -f https://bmi.engage-360.net/api/search/stats && echo "✅ API stats through Nginx OK" || echo "❌ API stats through Nginx FAILED"

# Check Nginx error logs
echo ""
echo "📊 Step 4: Checking Nginx error logs..."
sudo tail -10 /var/log/nginx/error.log

# Fix the Nginx configuration
echo ""
echo "📊 Step 5: Fixing Nginx configuration..."
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

    # Backend API - FIXED: Remove trailing slash to avoid double slashes
    location /api/ {
        proxy_pass http://localhost:3006/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # CORS headers
        add_header Access-Control-Allow-Origin "https://bmi.engage-360.net" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        add_header Access-Control-Allow-Credentials "true" always;
        
        # Handle preflight requests
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin "https://bmi.engage-360.net" always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
            add_header Access-Control-Allow-Credentials "true" always;
            add_header Content-Type "text/plain charset=UTF-8";
            add_header Content-Length 0;
            return 204;
        }
    }

    # Health check - FIXED: Remove trailing slash
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

# Test Nginx configuration
echo ""
echo "📊 Step 6: Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Reload Nginx
echo ""
echo "🔄 Step 7: Reloading Nginx configuration..."
sudo systemctl reload nginx

# Wait a moment
sleep 2

# Test the API endpoints
echo ""
echo "📊 Step 8: Testing API endpoints..."
echo "Testing health endpoint:"
curl -f https://bmi.engage-360.net/health && echo "✅ Health OK" || echo "❌ Health FAILED"

echo ""
echo "Testing API stats:"
curl -f https://bmi.engage-360.net/api/search/stats && echo "✅ API stats OK" || echo "❌ API stats FAILED"

echo ""
echo "Testing API documents:"
curl -f "https://bmi.engage-360.net/api/documents?skip=0&limit=10" && echo "✅ API documents OK" || echo "❌ API documents FAILED"

echo ""
echo "Testing API analytics:"
curl -f "https://bmi.engage-360.net/api/search/analytics?days=30" && echo "✅ API analytics OK" || echo "❌ API analytics FAILED"

# Test the main site
echo ""
echo "📊 Step 9: Testing main site..."
if curl -f https://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ BMI Chat site accessible"
else
    echo "❌ BMI Chat site not accessible"
fi

echo ""
echo "🎉 API routing should be fixed!"
echo ""
echo "Your BMI Chat application should now work correctly at:"
echo "  https://bmi.engage-360.net"
echo ""
echo "If you still see 404 errors, check:"
echo "1. Backend logs: docker-compose logs -f backend"
echo "2. Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "3. Test backend directly: curl http://localhost:3006/health" 