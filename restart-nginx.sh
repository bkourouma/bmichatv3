#!/bin/bash

# 🔧 Restart Nginx and Fix 502 Error
# This script checks Nginx status and restarts it properly

set -e

echo "🔧 Restarting Nginx and Fixing 502 Error"
echo "========================================"

# Check Nginx status
echo "📊 Step 1: Checking Nginx status..."
sudo systemctl status nginx --no-pager -l

# Check if Nginx is running
if sudo systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
else
    echo "❌ Nginx is not running"
fi

# Check Nginx configuration
echo ""
echo "📊 Step 2: Testing Nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors"
    exit 1
fi

# Check Nginx error logs
echo ""
echo "📊 Step 3: Checking Nginx error logs..."
sudo tail -20 /var/log/nginx/error.log

# Check Nginx access logs
echo ""
echo "📊 Step 4: Checking Nginx access logs..."
sudo tail -10 /var/log/nginx/access.log

# Check if Docker services are still running
echo ""
echo "📊 Step 5: Checking Docker services..."
docker-compose ps

# Test local services
echo ""
echo "📊 Step 6: Testing local services..."
if curl -f http://localhost:3006/health > /dev/null 2>&1; then
    echo "✅ Backend is responding"
else
    echo "❌ Backend is not responding"
fi

if curl -f http://localhost:8095 > /dev/null 2>&1; then
    echo "✅ Frontend is responding"
else
    echo "❌ Frontend is not responding"
fi

# Restart Nginx
echo ""
echo "🔄 Step 7: Restarting Nginx..."
sudo systemctl stop nginx
sleep 2
sudo systemctl start nginx
sleep 3

# Check Nginx status after restart
echo ""
echo "📊 Step 8: Checking Nginx after restart..."
sudo systemctl status nginx --no-pager -l

# Test the site
echo ""
echo "📊 Step 9: Testing the site..."
if curl -f http://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ Site is accessible"
else
    echo "❌ Site is not accessible"
    echo "Testing with verbose output:"
    curl -v http://bmi.engage-360.net
fi

# Check for conflicting configurations
echo ""
echo "📊 Step 10: Checking for conflicting configurations..."
ls -la /etc/nginx/sites-enabled/

echo ""
echo "🎉 Nginx restart completed!"
echo ""
echo "If you still get 502 errors, try:"
echo "1. Check DNS: nslookup bmi.engage-360.net"
echo "2. Check firewall: sudo ufw status"
echo "3. Check if domain resolves: ping bmi.engage-360.net"
echo "4. Check Nginx logs: sudo tail -f /var/log/nginx/error.log" 