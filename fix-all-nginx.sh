#!/bin/bash

# 🔧 Fix All Nginx Configuration Conflicts
# This script will identify and fix all conflicting configurations

set -e

echo "🔧 Fixing All Nginx Configuration Conflicts"
echo "=========================================="

# Check all enabled configurations
echo "📊 Step 1: Checking all enabled configurations..."
ls -la /etc/nginx/sites-enabled/

# Check what each configuration contains
echo ""
echo "📊 Step 2: Checking configuration contents..."
for config in /etc/nginx/sites-enabled/*; do
    if [ -L "$config" ]; then
        echo "=== $(basename $config) ==="
        sudo grep -E "(server_name|listen)" "$config" || echo "No server_name or listen found"
        echo ""
    fi
done

# Check for any configuration that might handle bmi.engage-360.net
echo ""
echo "📊 Step 3: Searching for bmi.engage-360.net in all configs..."
sudo grep -r "bmi.engage-360.net" /etc/nginx/sites-available/ || echo "No bmi.engage-360.net found"

# Check for any configuration that might handle engage-360.net
echo ""
echo "📊 Step 4: Searching for engage-360.net in all configs..."
sudo grep -r "engage-360.net" /etc/nginx/sites-available/ || echo "No engage-360.net found"

# Check what's listening on our ports
echo ""
echo "📊 Step 5: Checking what's using our ports..."
sudo netstat -tulpn | grep -E ':(80|443|3006|8095)'

# Test our Docker services
echo ""
echo "📊 Step 6: Testing our Docker services..."
docker-compose ps
curl -f http://localhost:3006/health && echo "✅ Backend OK" || echo "❌ Backend FAILED"
curl -f http://localhost:8095 && echo "✅ Frontend OK" || echo "❌ Frontend FAILED"

# Create a completely clean configuration with higher priority
echo ""
echo "📊 Step 7: Creating clean configuration with higher priority..."
sudo tee /etc/nginx/sites-available/bmi.engage-360.net > /dev/null << 'EOF'
# BMI Chat Configuration - Higher Priority
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

# Disable ALL other configurations temporarily
echo ""
echo "📊 Step 8: Temporarily disabling all other configurations..."
sudo mkdir -p /etc/nginx/sites-enabled-backup
sudo mv /etc/nginx/sites-enabled/* /etc/nginx/sites-enabled-backup/ 2>/dev/null || true

# Enable only our configuration
echo ""
echo "📊 Step 9: Enabling only our configuration..."
sudo ln -sf /etc/nginx/sites-available/bmi.engage-360.net /etc/nginx/sites-enabled/

# Test Nginx configuration
echo ""
echo "📊 Step 10: Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Restart Nginx completely
echo ""
echo "🔄 Step 11: Restarting Nginx completely..."
sudo systemctl stop nginx
sleep 3
sudo systemctl start nginx
sleep 5

# Test the site
echo ""
echo "📊 Step 12: Testing the site..."
if curl -f http://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ Site is accessible"
else
    echo "❌ Site is not accessible"
    echo "Testing with verbose output:"
    curl -v http://bmi.engage-360.net
fi

# If it works, re-enable other configurations one by one
echo ""
echo "📊 Step 13: Re-enabling other configurations..."
for config in /etc/nginx/sites-enabled-backup/*; do
    if [ -L "$config" ]; then
        config_name=$(basename "$config")
        echo "Re-enabling: $config_name"
        sudo mv "$config" /etc/nginx/sites-enabled/
        
        # Test configuration
        if sudo nginx -t; then
            echo "✅ $config_name is compatible"
            sudo systemctl reload nginx
        else
            echo "❌ $config_name conflicts - keeping disabled"
            sudo mv /etc/nginx/sites-enabled/"$config_name" /etc/nginx/sites-enabled-backup/
        fi
    fi
done

echo ""
echo "🎉 Nginx configuration conflicts fixed!"
echo ""
echo "Your BMI Chat application should now be accessible at:"
echo "  http://bmi.engage-360.net"
echo ""
echo "If you still get 502 errors, check:"
echo "1. DNS: nslookup bmi.engage-360.net"
echo "2. Firewall: sudo ufw status"
echo "3. Nginx logs: sudo tail -f /var/log/nginx/error.log" 