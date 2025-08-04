#!/bin/bash

# 🔧 Fix CORS Issue for BMI Chat
# This script fixes the CORS issue by updating environment variables and rebuilding

set -e

echo "🔧 Fixing CORS Issue for BMI Chat"
echo "=================================="

# Check current environment
echo "📊 Step 1: Checking current environment..."
if [ -f ".env" ]; then
    echo "✅ .env file exists"
    grep -E "(VITE_API_URL|CORS_ORIGINS)" .env || echo "❌ Missing VITE_API_URL or CORS_ORIGINS"
else
    echo "❌ .env file not found"
fi

# Update environment variables
echo ""
echo "📊 Step 2: Updating environment variables..."
cat >> .env << 'EOF'

# =============================================================================
# Frontend Configuration (Production)
# =============================================================================
VITE_API_URL=https://bmi.engage-360.net
VITE_WS_URL=wss://bmi.engage-360.net/ws

# =============================================================================
# CORS Settings (Production)
# =============================================================================
CORS_ORIGINS=["https://bmi.engage-360.net","https://www.bmi.engage-360.net"]
EOF

echo "✅ Added production environment variables"

# Check backend CORS configuration
echo ""
echo "📊 Step 3: Checking backend CORS configuration..."
if grep -q "CORS_ORIGINS" .env; then
    echo "✅ CORS_ORIGINS found in .env"
    grep "CORS_ORIGINS" .env
else
    echo "❌ CORS_ORIGINS not found"
fi

# Rebuild frontend with correct API URL
echo ""
echo "📊 Step 4: Rebuilding frontend with correct API URL..."
cd frontend

# Create production environment file
cat > .env.production << 'EOF'
VITE_API_URL=https://bmi.engage-360.net
VITE_WS_URL=wss://bmi.engage-360.net/ws
EOF

echo "✅ Created .env.production with correct API URL"

# Build frontend
echo ""
echo "🔄 Building frontend..."
npm run build

echo "✅ Frontend built successfully"

# Go back to root
cd ..

# Restart Docker containers
echo ""
echo "📊 Step 5: Restarting Docker containers..."
docker-compose down
docker-compose up -d --build

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Test the services
echo ""
echo "📊 Step 6: Testing services..."
docker-compose ps

# Test backend health
echo ""
echo "Testing backend health..."
curl -f http://localhost:3006/health && echo "✅ Backend OK" || echo "❌ Backend FAILED"

# Test frontend
echo ""
echo "Testing frontend..."
curl -f http://localhost:8095 && echo "✅ Frontend OK" || echo "❌ Frontend FAILED"

# Test through Nginx
echo ""
echo "📊 Step 7: Testing through Nginx..."
echo "Testing https://bmi.engage-360.net..."
if curl -f https://bmi.engage-360.net > /dev/null 2>&1; then
    echo "✅ BMI Chat site accessible via HTTPS"
else
    echo "❌ BMI Chat site not accessible"
    echo "Testing with verbose output:"
    curl -v https://bmi.engage-360.net
fi

# Test API endpoints through Nginx
echo ""
echo "Testing API endpoints through Nginx..."
curl -f https://bmi.engage-360.net/api/search/stats && echo "✅ API stats OK" || echo "❌ API stats FAILED"
curl -f https://bmi.engage-360.net/health && echo "✅ Health check OK" || echo "❌ Health check FAILED"

echo ""
echo "🎉 CORS issue should be fixed!"
echo ""
echo "Your BMI Chat application should now work correctly at:"
echo "  https://bmi.engage-360.net"
echo ""
echo "If you still see CORS errors, check:"
echo "1. Browser console for specific errors"
echo "2. Nginx logs: sudo tail -f /var/log/nginx/error.log"
echo "3. Backend logs: docker-compose logs -f backend" 