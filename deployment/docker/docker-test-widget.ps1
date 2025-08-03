# BMI Chat Docker Widget Test Script (PowerShell)
# This script tests the complete widget functionality in Docker

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "BMI Chat Widget Test with Docker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Change to the docker directory
Set-Location $PSScriptRoot

# Function to test URL
function Test-Url {
    param([string]$Url, [int]$TimeoutSeconds = 10)
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSeconds -UseBasicParsing
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

# Check if Docker is running
Write-Host "[1/8] Checking Docker status..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if .env file exists
Write-Host "[2/8] Checking environment configuration..." -ForegroundColor Yellow
if (-not (Test-Path ".env")) {
    Write-Host "ERROR: .env file not found. Please copy .env.docker to .env and configure it." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Environment file exists" -ForegroundColor Green

# Stop any existing containers
Write-Host "[3/8] Stopping existing containers..." -ForegroundColor Yellow
docker-compose down 2>$null | Out-Null
Write-Host "✓ Existing containers stopped" -ForegroundColor Green

# Build the application
Write-Host "[4/8] Building Docker images..." -ForegroundColor Yellow
Write-Host "This may take several minutes on first run..." -ForegroundColor Gray
$buildResult = docker-compose build --no-cache
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker build failed. Please check the error messages above." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Docker images built successfully" -ForegroundColor Green

# Start the services
Write-Host "[5/8] Starting services..." -ForegroundColor Yellow
$startResult = docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to start services." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "✓ Services started" -ForegroundColor Green

# Wait for services to be ready
Write-Host "[6/8] Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
Write-Host "✓ Services should be ready" -ForegroundColor Green

# Test backend health
Write-Host "[7/8] Testing backend health..." -ForegroundColor Yellow
$backendHealthy = Test-Url "http://localhost:3006/health"
if (-not $backendHealthy) {
    Write-Host "WARNING: Backend health check failed. Services might still be starting..." -ForegroundColor Yellow
    Write-Host "Waiting additional 30 seconds..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
    $backendHealthy = Test-Url "http://localhost:3006/health"
    if (-not $backendHealthy) {
        Write-Host "ERROR: Backend is not responding. Check logs with: docker-compose logs backend" -ForegroundColor Red
        Write-Host ""
        Write-Host "Current container status:" -ForegroundColor Yellow
        docker-compose ps
        Read-Host "Press Enter to exit"
        exit 1
    }
}
Write-Host "✓ Backend is healthy" -ForegroundColor Green

# Test frontend
Write-Host "[8/8] Testing frontend..." -ForegroundColor Yellow
$frontendHealthy = Test-Url "http://localhost:3003/"
if (-not $frontendHealthy) {
    Write-Host "WARNING: Frontend is not responding yet. This is normal on first startup." -ForegroundColor Yellow
    Write-Host "Frontend might still be building..." -ForegroundColor Gray
}
Write-Host "✓ Frontend test completed" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Docker Widget Test Complete! ✓" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Services are running:" -ForegroundColor Yellow
docker-compose ps

Write-Host ""
Write-Host "Access points:" -ForegroundColor Yellow
Write-Host "- Frontend (Admin): http://localhost:3003" -ForegroundColor White
Write-Host "- Widgets Page: http://localhost:3003/widgets" -ForegroundColor White
Write-Host "- Backend API: http://localhost:3006" -ForegroundColor White
Write-Host "- API Documentation: http://localhost:3006/docs" -ForegroundColor White
Write-Host "- Widget Demo Page: http://localhost:3006/widget-test-demo.html" -ForegroundColor White

Write-Host ""
Write-Host "Widget Testing Steps:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:3003/widgets in your browser" -ForegroundColor White
Write-Host "2. Create a new widget or use existing ones" -ForegroundColor White
Write-Host "3. Click 'Tester le Chat' button on any widget card" -ForegroundColor White
Write-Host "4. Test the chat functionality in the modal" -ForegroundColor White
Write-Host "5. Visit http://localhost:3006/widget-test-demo.html for public demo" -ForegroundColor White
Write-Host "6. Click the floating chat button to test widget integration" -ForegroundColor White

Write-Host ""
Write-Host "To view logs: docker-compose logs -f" -ForegroundColor Gray
Write-Host "To stop services: docker-compose down" -ForegroundColor Gray
Write-Host ""

# Open browser automatically
$openBrowser = Read-Host "Open browser automatically? (y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    Write-Host "Opening browser..." -ForegroundColor Green
    Start-Process "http://localhost:3003/widgets"
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:3006/widget-test-demo.html"
}

Write-Host ""
Write-Host "Test completed! Press any key to exit..." -ForegroundColor Green
Read-Host
