#!/bin/bash
# BMI Chat Docker Widget Test Script (Linux/macOS)
# This script tests the complete widget functionality in Docker

set -e

echo "========================================"
echo "BMI Chat Widget Test with Docker"
echo "========================================"

# Change to the docker directory
cd "$(dirname "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to test URL
test_url() {
    local url=$1
    local timeout=${2:-10}
    if curl -f -s --max-time $timeout "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check if Docker is running
echo -e "${YELLOW}[1/8] Checking Docker status...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker is not running. Please start Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"

# Check if .env file exists
echo -e "${YELLOW}[2/8] Checking environment configuration...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${RED}ERROR: .env file not found. Please copy .env.docker to .env and configure it.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Environment file exists${NC}"

# Stop any existing containers
echo -e "${YELLOW}[3/8] Stopping existing containers...${NC}"
docker-compose down > /dev/null 2>&1 || true
echo -e "${GREEN}✓ Existing containers stopped${NC}"

# Build the application
echo -e "${YELLOW}[4/8] Building Docker images...${NC}"
echo "This may take several minutes on first run..."
if ! docker-compose build --no-cache; then
    echo -e "${RED}ERROR: Docker build failed. Please check the error messages above.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker images built successfully${NC}"

# Start the services
echo -e "${YELLOW}[5/8] Starting services...${NC}"
if ! docker-compose up -d; then
    echo -e "${RED}ERROR: Failed to start services.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Services started${NC}"

# Wait for services to be ready
echo -e "${YELLOW}[6/8] Waiting for services to be ready...${NC}"
sleep 30
echo -e "${GREEN}✓ Services should be ready${NC}"

# Test backend health
echo -e "${YELLOW}[7/8] Testing backend health...${NC}"
if ! test_url "http://localhost:3006/health"; then
    echo -e "${YELLOW}WARNING: Backend health check failed. Services might still be starting...${NC}"
    echo "Waiting additional 30 seconds..."
    sleep 30
    if ! test_url "http://localhost:3006/health"; then
        echo -e "${RED}ERROR: Backend is not responding. Check logs with: docker-compose logs backend${NC}"
        echo ""
        echo "Current container status:"
        docker-compose ps
        exit 1
    fi
fi
echo -e "${GREEN}✓ Backend is healthy${NC}"

# Test frontend
echo -e "${YELLOW}[8/8] Testing frontend...${NC}"
if ! test_url "http://localhost:3003/"; then
    echo -e "${YELLOW}WARNING: Frontend is not responding yet. This is normal on first startup.${NC}"
    echo "Frontend might still be building..."
fi
echo -e "${GREEN}✓ Frontend test completed${NC}"

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Docker Widget Test Complete! ✓${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

echo -e "${YELLOW}Services are running:${NC}"
docker-compose ps

echo ""
echo -e "${YELLOW}Access points:${NC}"
echo "- Frontend (Admin): http://localhost:3003"
echo "- Widgets Page: http://localhost:3003/widgets"
echo "- Backend API: http://localhost:3006"
echo "- API Documentation: http://localhost:3006/docs"
echo "- Widget Demo Page: http://localhost:3006/widget-test-demo.html"

echo ""
echo -e "${YELLOW}Widget Testing Steps:${NC}"
echo "1. Open http://localhost:3003/widgets in your browser"
echo "2. Create a new widget or use existing ones"
echo "3. Click 'Tester le Chat' button on any widget card"
echo "4. Test the chat functionality in the modal"
echo "5. Visit http://localhost:3006/widget-test-demo.html for public demo"
echo "6. Click the floating chat button to test widget integration"

echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop services: docker-compose down"
echo ""

# Open browser automatically (if available)
if command -v xdg-open > /dev/null 2>&1; then
    read -p "Open browser automatically? (y/n): " open_browser
    if [[ $open_browser == "y" || $open_browser == "Y" ]]; then
        echo "Opening browser..."
        xdg-open "http://localhost:3003/widgets" 2>/dev/null &
        sleep 2
        xdg-open "http://localhost:3006/widget-test-demo.html" 2>/dev/null &
    fi
elif command -v open > /dev/null 2>&1; then
    read -p "Open browser automatically? (y/n): " open_browser
    if [[ $open_browser == "y" || $open_browser == "Y" ]]; then
        echo "Opening browser..."
        open "http://localhost:3003/widgets"
        sleep 2
        open "http://localhost:3006/widget-test-demo.html"
    fi
fi

echo ""
echo -e "${GREEN}Test completed!${NC}"
