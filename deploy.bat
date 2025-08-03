@echo off
REM BMI Chat Deployment Script for Windows
REM Usage: deploy.bat [dev|prod]

setlocal enabledelayedexpansion

REM Colors for output (Windows doesn't support ANSI colors in batch)
echo [INFO] BMI Chat Deployment Script

REM Check if .env file exists
if not exist .env (
    echo [ERROR] .env file not found!
    echo [INFO] Please copy env.example to .env and configure your settings:
    echo cp env.example .env
    echo notepad .env
    pause
    exit /b 1
)

REM Determine environment
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" set ENVIRONMENT=prod
set COMPOSE_FILE=docker-compose.yml

if "%ENVIRONMENT%"=="dev" (
    set COMPOSE_FILE=docker-compose.dev.yml
    echo [INFO] Deploying in DEVELOPMENT mode
) else (
    echo [INFO] Deploying in PRODUCTION mode
)

echo [INFO] Using compose file: %COMPOSE_FILE%

REM Stop existing containers
echo [INFO] Stopping existing containers...
docker-compose -f %COMPOSE_FILE% down --remove-orphans

REM Pull latest changes (if using git)
if exist .git (
    echo [INFO] Pulling latest changes...
    git pull origin main
)

REM Build and start containers
echo [INFO] Building and starting containers...
docker-compose -f %COMPOSE_FILE% up -d --build

REM Wait for services to be healthy
echo [INFO] Waiting for services to be healthy...
timeout /t 30 /nobreak > nul

REM Check service health
echo [INFO] Checking service health...

REM Check backend
curl -f http://localhost:3006/health > nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Backend is healthy
) else (
    echo [ERROR] Backend health check failed
    docker-compose -f %COMPOSE_FILE% logs backend
    pause
    exit /b 1
)

REM Check frontend (only in production)
if not "%ENVIRONMENT%"=="dev" (
    curl -f http://localhost:8095 > nul 2>&1
    if %errorlevel% equ 0 (
        echo [SUCCESS] Frontend is healthy
    ) else (
        echo [ERROR] Frontend health check failed
        docker-compose -f %COMPOSE_FILE% logs frontend
        pause
        exit /b 1
    )
)

echo [SUCCESS] Deployment completed successfully!

REM Show service URLs
echo.
echo [INFO] Service URLs:
echo   Backend API: http://localhost:3006
if not "%ENVIRONMENT%"=="dev" (
    echo   Frontend: http://localhost:8095
    echo   API Docs: http://localhost:3006/docs
) else (
    echo   Frontend: http://localhost:3003
    echo   API Docs: http://localhost:3006/docs
)

REM Show logs command
echo.
echo [INFO] To view logs:
echo   docker-compose -f %COMPOSE_FILE% logs -f

REM Show stop command
echo.
echo [INFO] To stop services:
echo   docker-compose -f %COMPOSE_FILE% down

pause 