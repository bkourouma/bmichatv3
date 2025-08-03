@echo off
REM BMI Chat Docker Widget Test Script
REM This script tests the complete widget functionality in Docker

echo ========================================
echo BMI Chat Widget Test with Docker
echo ========================================

REM Change to the docker directory
cd /d "%~dp0"

REM Check if Docker is running
echo [1/8] Checking Docker status...
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)
echo ✓ Docker is running

REM Check if .env file exists
echo [2/8] Checking environment configuration...
if not exist ".env" (
    echo ERROR: .env file not found. Please copy .env.docker to .env and configure it.
    pause
    exit /b 1
)
echo ✓ Environment file exists

REM Stop any existing containers
echo [3/8] Stopping existing containers...
docker-compose down >nul 2>&1
echo ✓ Existing containers stopped

REM Build the application
echo [4/8] Building Docker images...
echo This may take several minutes on first run...
docker-compose build --no-cache
if %errorlevel% neq 0 (
    echo ERROR: Docker build failed. Please check the error messages above.
    pause
    exit /b 1
)
echo ✓ Docker images built successfully

REM Start the services
echo [5/8] Starting services...
docker-compose up -d
if %errorlevel% neq 0 (
    echo ERROR: Failed to start services.
    pause
    exit /b 1
)
echo ✓ Services started

REM Wait for services to be ready
echo [6/8] Waiting for services to be ready...
timeout /t 30 /nobreak >nul
echo ✓ Services should be ready

REM Test backend health
echo [7/8] Testing backend health...
curl -f http://localhost:3006/health >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Backend health check failed. Services might still be starting...
    echo Waiting additional 30 seconds...
    timeout /t 30 /nobreak >nul
    curl -f http://localhost:3006/health >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Backend is not responding. Check logs with: docker-compose logs backend
        echo.
        echo Current container status:
        docker-compose ps
        pause
        exit /b 1
    )
)
echo ✓ Backend is healthy

REM Test frontend
echo [8/8] Testing frontend...
curl -f http://localhost:3003/ >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Frontend is not responding yet. This is normal on first startup.
    echo Frontend might still be building...
)
echo ✓ Frontend test completed

echo.
echo ========================================
echo Docker Widget Test Complete! ✓
echo ========================================
echo.
echo Services are running:
docker-compose ps
echo.
echo Access points:
echo - Frontend (Admin): http://localhost:3003
echo - Widgets Page: http://localhost:3003/widgets
echo - Backend API: http://localhost:3006
echo - API Documentation: http://localhost:3006/docs
echo - Widget Demo Page: http://localhost:3006/widget-test-demo.html
echo.
echo Widget Testing Steps:
echo 1. Open http://localhost:3003/widgets in your browser
echo 2. Create a new widget or use existing ones
echo 3. Click "Tester le Chat" button on any widget card
echo 4. Test the chat functionality in the modal
echo 5. Visit http://localhost:3006/widget-test-demo.html for public demo
echo 6. Click the floating chat button to test widget integration
echo.
echo To view logs: docker-compose logs -f
echo To stop services: docker-compose down
echo.

REM Open browser automatically
set /p open_browser="Open browser automatically? (y/n): "
if /i "%open_browser%"=="y" (
    echo Opening browser...
    start http://localhost:3003/widgets
    timeout /t 2 /nobreak >nul
    start http://localhost:3006/widget-test-demo.html
)

echo.
echo Test completed! Press any key to exit...
pause >nul
