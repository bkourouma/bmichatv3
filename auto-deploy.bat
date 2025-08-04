@echo off
REM 🚀 Automated BMI Chat Deployment Script for Windows
REM This script prepares the deployment for Linux server

echo 🚀 Automated BMI Chat Deployment Script
echo ======================================

echo.
echo [INFO] This script prepares your deployment for the Linux server
echo [INFO] You will need to run the Linux version on your VPS
echo.

REM Check if Git is installed
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed. Please install Git first.
    pause
    exit /b 1
)

REM Check if Docker is installed
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Docker is not installed. This is OK for local preparation.
)

echo [INFO] Creating deployment package...

REM Create deployment directory
if not exist "deployment-package" mkdir deployment-package

REM Copy necessary files
echo [INFO] Copying deployment files...
copy auto-deploy.sh deployment-package\
copy deploy.sh deployment-package\
copy deploy-vps.sh deployment-package\
copy docker-compose.yml deployment-package\
copy docker-compose.dev.yml deployment-package\
copy env.example deployment-package\

REM Copy deployment directory
if exist "deployment" xcopy /E /I deployment deployment-package\deployment

echo.
echo [SUCCESS] Deployment package created in 'deployment-package' folder
echo.
echo [INFO] Next steps:
echo 1. Upload the 'deployment-package' folder to your Linux VPS
echo 2. SSH into your VPS
echo 3. Navigate to the deployment-package directory
echo 4. Run: chmod +x auto-deploy.sh
echo 5. Run: ./auto-deploy.sh
echo.
echo [INFO] The script will automatically:
echo - Clone your GitHub repository with the provided token
echo - Set up the environment
echo - Deploy the application using Docker
echo - Test all endpoints
echo.
pause 