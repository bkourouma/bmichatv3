#!/bin/bash

# 🔧 Debug API Endpoints for BMI Chat
# This script debugs the API endpoint routing issues

set -e

echo "🔧 Debugging API Endpoints for BMI Chat"
echo "======================================="

# Check backend logs
echo "📊 Step 1: Checking backend logs..."
docker-compose logs --tail=20 backend

# Test backend directly
echo ""
echo "📊 Step 2: Testing backend endpoints directly..."
echo "Testing health endpoint:"
curl -f http://localhost:3006/health && echo "✅ Health OK" || echo "❌ Health FAILED"

echo ""
echo "Testing API docs:"
curl -f http://localhost:3006/docs && echo "✅ API docs OK" || echo "❌ API docs FAILED"

echo ""
echo "Testing API root:"
curl -f http://localhost:3006/ && echo "✅ API root OK" || echo "❌ API root FAILED"

# Check what endpoints are available
echo ""
echo "📊 Step 3: Checking available API endpoints..."
echo "Testing common API paths:"
for endpoint in "/api/search/stats" "/api/documents" "/api/search/analytics" "/api/chat" "/search/stats" "/documents" "/search/analytics"; do
    echo "Testing: $endpoint"
    curl -s -o /dev/null -w "%{http_code}" http://localhost:3006$endpoint && echo " - OK" || echo " - FAILED"
done

# Check backend routes
echo ""
echo "📊 Step 4: Checking backend routes..."
docker exec bmi-chat-backend python -c "
from app.main import app
for route in app.routes:
    if hasattr(route, 'path'):
        print(f'{route.methods} {route.path}')
" 2>/dev/null || echo "Could not check routes directly"

# Check if the issue is with the API prefix
echo ""
echo "📊 Step 5: Testing without API prefix..."
echo "Testing /search/stats:"
curl -f http://localhost:3006/search/stats && echo "✅ /search/stats OK" || echo "❌ /search/stats FAILED"

echo ""
echo "Testing /documents:"
curl -f "http://localhost:3006/documents?skip=0&limit=10" && echo "✅ /documents OK" || echo "❌ /documents FAILED"

echo ""
echo "Testing /search/analytics:"
curl -f "http://localhost:3006/search/analytics?days=30" && echo "✅ /search/analytics OK" || echo "❌ /search/analytics FAILED"

# Check Nginx configuration for API routing
echo ""
echo "📊 Step 6: Checking Nginx API routing..."
echo "Current Nginx API configuration:"
grep -A 10 "location /api/" /etc/nginx/sites-available/bmi.engage-360.net

# Test Nginx routing
echo ""
echo "📊 Step 7: Testing Nginx API routing..."
echo "Testing through Nginx without /api prefix:"
curl -f https://bmi.engage-360.net/search/stats && echo "✅ Nginx /search/stats OK" || echo "❌ Nginx /search/stats FAILED"

echo ""
echo "Testing through Nginx with /api prefix:"
curl -f https://bmi.engage-360.net/api/search/stats && echo "✅ Nginx /api/search/stats OK" || echo "❌ Nginx /api/search/stats FAILED"

# Check if the issue is with the trailing slash in proxy_pass
echo ""
echo "📊 Step 8: Checking proxy_pass configuration..."
echo "Current proxy_pass for /api/:"
grep -A 5 "location /api/" /etc/nginx/sites-available/bmi.engage-360.net | grep proxy_pass

# Fix the Nginx configuration if needed
echo ""
echo "📊 Step 9: Fixing Nginx configuration..."
if ! curl -f https://bmi.engage-360.net/api/search/stats > /dev/null 2>&1; then
    echo "❌ API routing not working, let's fix it..."
    
    # Update Nginx configuration to handle both with and without /api prefix
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

    # Backend API - FIXED: Handle both /api/ and direct paths
    location /api/ {
        # Remove /api/ prefix and proxy to backend
        rewrite ^/api/(.*)$ /$1 break;
        proxy_pass http://localhost:3006;
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

    # Test Nginx configuration
    if sudo nginx -t; then
        echo "✅ Nginx configuration is valid"
        sudo systemctl reload nginx
        echo "✅ Nginx reloaded"
    else
        echo "❌ Nginx configuration has errors"
        exit 1
    fi
    
else
    echo "✅ API routing is working"
fi

# Final test of API endpoints
echo ""
echo "📊 Step 10: Final API endpoint tests..."
curl -f https://bmi.engage-360.net/health && echo "✅ Health OK" || echo "❌ Health FAILED"
curl -f https://bmi.engage-360.net/api/search/stats && echo "✅ API stats OK" || echo "❌ API stats FAILED"
curl -f "https://bmi.engage-360.net/api/documents?skip=0&limit=10" && echo "✅ API documents OK" || echo "❌ API documents FAILED"
curl -f "https://bmi.engage-360.net/api/search/analytics?days=30" && echo "✅ API analytics OK" || echo "❌ API analytics FAILED"

echo ""
echo "🎉 API endpoint debugging complete!"
echo ""
echo "Your BMI Chat application should now work correctly at:"
echo "  https://bmi.engage-360.net"
echo ""
echo "If you still see 404 errors, check:"
echo "1. Backend logs: docker-compose logs -f backend"
echo "2. Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "3. Test backend directly: curl http://localhost:3006/search/stats" 