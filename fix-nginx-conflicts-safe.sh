#!/bin/bash

echo "🔍 Checking current Nginx configuration..."

# Check existing configurations
echo "📋 Current Nginx sites:"
ls -la /etc/nginx/sites-enabled/

echo ""
echo "🔍 Checking for bmi.engage-360.net conflicts:"
grep -r "bmi.engage-360.net" /etc/nginx/sites-enabled/ || echo "No bmi.engage-360.net found in enabled sites"

echo ""
echo "🔍 Checking for port 80 conflicts:"
grep -r "listen 80" /etc/nginx/sites-enabled/

echo ""
echo "🔍 Checking for SSL conflicts:"
grep -r "listen 443" /etc/nginx/sites-enabled/

echo ""
echo "🛠️  Safe resolution steps:"

# 1. Backup current bmi-chat config
if [ -f "/etc/nginx/sites-available/bmi-chat" ]; then
    echo "📦 Backing up current bmi-chat config..."
    cp /etc/nginx/sites-available/bmi-chat /etc/nginx/sites-available/bmi-chat.backup.$(date +%Y%m%d_%H%M%S)
fi

# 2. Remove the conflicting bmi-chat config
echo "🗑️  Removing conflicting bmi-chat config..."
rm -f /etc/nginx/sites-enabled/bmi-chat

# 3. Check what's using the domain
echo "🔍 Checking what's using bmi.engage-360.net:"
grep -r "bmi.engage-360.net" /etc/nginx/sites-available/ || echo "No bmi.engage-360.net found in available sites"

echo ""
echo "✅ Safe cleanup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Review the output above"
echo "2. Decide if you want to replace existing bmi.engage-360.net config"
echo "3. Or use a different domain/subdomain"
echo ""
echo "🔧 To continue with deployment:"
echo "   - If you want to replace: Remove the conflicting config first"
echo "   - If you want to keep existing: Use a different domain"
echo ""
echo "💡 Recommendation: Check what's currently using bmi.engage-360.net" 