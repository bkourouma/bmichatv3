# 🐳 BMI Chat Widget Testing with Docker

This guide provides comprehensive instructions for testing the BMI Chat widget functionality using Docker.

## 🚀 Quick Start

### Windows
```bash
# Navigate to docker directory
cd deployment/docker

# Run widget test (Batch)
docker-test-widget.bat

# Or run with PowerShell
powershell -ExecutionPolicy Bypass -File docker-test-widget.ps1
```

### Linux/macOS
```bash
# Navigate to docker directory
cd deployment/docker

# Make script executable (Linux/macOS only)
chmod +x docker-test-widget.sh

# Run widget test
./docker-test-widget.sh
```

## 📋 Prerequisites

1. **Docker Desktop** installed and running
2. **Docker Compose** available
3. **OpenAI API Key** configured in `.env` file
4. **Internet connection** for downloading dependencies

## 🔧 Setup Steps

### 1. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your OpenAI API key
# OPENAI_API_KEY=sk-proj-your-actual-api-key-here
```

### 2. Run Tests
Choose your platform and run the appropriate script:

#### Windows (Batch)
```cmd
docker-test-widget.bat
```

#### Windows (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File docker-test-widget.ps1
```

#### Linux/macOS
```bash
./docker-test-widget.sh
```

## 🎯 What the Test Does

The test script performs the following steps:

1. **✅ Docker Status Check** - Verifies Docker is running
2. **✅ Environment Check** - Validates `.env` file exists
3. **✅ Container Cleanup** - Stops any existing containers
4. **✅ Image Building** - Builds fresh Docker images
5. **✅ Service Startup** - Starts all services
6. **✅ Health Checks** - Verifies backend and frontend health
7. **✅ Browser Launch** - Optionally opens test pages

## 🌐 Access Points

After successful test completion, you can access:

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend Admin** | http://localhost:3003 | Main administration interface |
| **Widgets Page** | http://localhost:3003/widgets | Widget management page |
| **Backend API** | http://localhost:3006 | REST API endpoints |
| **API Documentation** | http://localhost:3006/docs | Interactive API docs |
| **Widget Demo** | http://localhost:3006/widget-test-demo.html | Public widget demo |

## 🧪 Widget Testing Workflow

### 1. Admin Interface Testing
1. Open http://localhost:3003/widgets
2. Create a new widget or select existing one
3. Click **"Tester le Chat"** button on widget card
4. Test chat functionality in modal popup
5. Verify responses and UI behavior

### 2. Public Demo Testing
1. Open http://localhost:3006/widget-test-demo.html
2. Click floating chat button (bottom right)
3. Test widget as end-user would experience
4. Verify integration simulation

### 3. API Testing
1. Open http://localhost:3006/docs
2. Test chat endpoints directly
3. Verify RAG pipeline functionality
4. Check metrics endpoints

## 🔍 Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Check what's using the ports
netstat -ano | findstr :3003
netstat -ano | findstr :3006

# Kill processes if needed
taskkill /F /PID <process_id>
```

#### 2. Docker Build Fails
```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker-compose build --no-cache
```

#### 3. Services Not Responding
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs backend
docker-compose logs frontend

# Restart services
docker-compose restart
```

#### 4. Frontend Build Issues
```bash
# Check frontend logs
docker-compose logs frontend

# Rebuild frontend only
docker-compose build --no-cache frontend
docker-compose up -d frontend
```

### Health Check Commands

```bash
# Test backend health
curl http://localhost:3006/health

# Test frontend
curl http://localhost:3003/

# Check all containers
docker-compose ps

# View real-time logs
docker-compose logs -f
```

## 📊 Performance Testing

### Load Testing the Widget
```bash
# Install Apache Bench (if not available)
# Windows: Download from Apache website
# Linux: sudo apt-get install apache2-utils
# macOS: brew install httpie

# Test chat endpoint
ab -n 100 -c 10 -H "Content-Type: application/json" \
   -p test-payload.json \
   http://localhost:3006/api/chat
```

### Memory and CPU Monitoring
```bash
# Monitor container resources
docker stats

# Check container resource usage
docker-compose top
```

## 🛠️ Development Mode

For development with hot reload:

```bash
# Use development compose file
docker-compose -f docker-compose.dev.yml up -d

# Access points (different ports)
# Frontend: http://localhost:3003
# Backend: http://localhost:3007
```

## 🧹 Cleanup

### Stop Services
```bash
docker-compose down
```

### Complete Cleanup
```bash
# Stop and remove containers, networks, volumes
docker-compose down -v

# Remove images
docker-compose down --rmi all

# Clean Docker system
docker system prune -a
```

## 📝 Test Results

The test script will show:
- ✅ All checks passed
- ⚠️ Warnings for non-critical issues  
- ❌ Errors that need attention

### Expected Output
```
========================================
Docker Widget Test Complete! ✓
========================================

Services are running:
NAME                    COMMAND                  SERVICE             STATUS              PORTS
bmi-chat-backend        "uvicorn app.main:ap…"   backend             running             0.0.0.0:3006->3006/tcp
bmi-chat-frontend       "/docker-entrypoint.…"   frontend            running             0.0.0.0:3003->80/tcp
```

## 🆘 Support

If you encounter issues:

1. **Check logs**: `docker-compose logs -f`
2. **Verify environment**: Ensure `.env` file is properly configured
3. **Clean restart**: `docker-compose down && docker-compose up -d`
4. **System resources**: Ensure sufficient RAM and disk space

## 🎉 Success Criteria

The test is successful when:
- ✅ All containers are running
- ✅ Backend health check passes
- ✅ Frontend loads without errors
- ✅ Widget chat functionality works
- ✅ Demo page displays correctly
- ✅ API documentation is accessible
