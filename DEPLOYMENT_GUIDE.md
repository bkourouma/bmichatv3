# BMI Chat Production Deployment Guide

## 🚀 Server Deployment Instructions

### Prerequisites
- Docker and Docker Compose installed on the server
- Domain configured (e.g., `bmi.engage-360.net`)
- SSL certificate (recommended for production)

### 1. Environment Configuration

Copy the production environment file:
```bash
cp env.production .env
```

Edit the `.env` file with your production settings:
```bash
nano .env
```

**Important settings to update:**
- `OPENAI_API_KEY`: Your OpenAI API key
- `SECRET_KEY`: A long, random secret key
- `CORS_ORIGINS`: Update with your domain
- `ENVIRONMENT=production`
- `DEBUG=false`

### 2. Build Widget for Production

The widget needs to be built for production:
```bash
cd widget
npm install
npm run build
cd ..
```

### 3. Build Frontend for Production

Build the React frontend:
```bash
cd frontend
npm install
npm run build
cd ..
```

### 4. Deploy with Docker

Use the production deployment script:
```bash
chmod +x deploy-production.sh
./deploy-production.sh
```

Or manually:
```bash
# Stop existing containers
docker-compose -f deployment/docker/docker-compose.yml down

# Clean up
docker system prune -f

# Build and start
docker-compose -f deployment/docker/docker-compose.yml up -d --build
```

### 5. Verify Deployment

Test all endpoints:
```bash
# Health check
curl http://your-domain:3003/health

# API endpoints
curl -X POST http://your-domain:3003/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'

# Widget API
curl -X POST http://your-domain:3003/widget/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "test", "session_id": "test-session"}'

# Widget static files
curl http://your-domain:3003/widget/chat-widget.js
```

## 🔧 Widget Integration

### For Production Websites

Add this code to any website to embed the chat widget:

```html
<script>
(function() {
    var script = document.createElement('script');
    script.src = 'https://your-domain.com/widget/chat-widget.js';
    script.setAttribute('data-api-url', 'https://your-domain.com');
    script.setAttribute('data-position', 'right');
    script.setAttribute('data-accent-color', '#0056b3');
    script.async = true;
    document.head.appendChild(script);
})();
</script>
```

### Widget Configuration Options

The widget supports these configuration options:
- `data-api-url`: The base URL of your API (required)
- `data-position`: 'right' or 'left' (default: 'right')
- `data-accent-color`: Brand color (default: '#0056b3')
- `data-company-name`: Company name (default: 'BMI')
- `data-assistant-name`: Assistant name (default: 'Akissi')

## 📋 Service URLs

After deployment, your services will be available at:

- **Frontend Application**: `http://your-domain:3003`
- **Backend API**: `http://your-domain:3006`
- **API Documentation**: `http://your-domain:3006/docs`
- **Widget API**: `http://your-domain:3003/widget/chat`
- **Health Check**: `http://your-domain:3003/health`

## 🔍 Monitoring and Logs

### View Logs
```bash
# All services
docker-compose -f deployment/docker/docker-compose.yml logs -f

# Specific service
docker-compose -f deployment/docker/docker-compose.yml logs -f backend
docker-compose -f deployment/docker/docker-compose.yml logs -f frontend
```

### Check Service Status
```bash
docker-compose -f deployment/docker/docker-compose.yml ps
```

### Health Checks
```bash
# Backend health
curl http://your-domain:3006/health

# Frontend health
curl http://your-domain:3003/health
```

## 🛠️ Troubleshooting

### Common Issues

1. **Widget API 405 Error**
   - Check nginx configuration
   - Verify widget proxy is configured correctly
   - Check backend logs for errors

2. **CORS Errors**
   - Update CORS_ORIGINS in .env file
   - Ensure domain is included in allowed origins

3. **Database Issues**
   - Check data directory permissions
   - Verify SQLite database is accessible

4. **Memory Issues**
   - Monitor container resource usage
   - Adjust API_WORKERS if needed

### Debug Commands

```bash
# Check container status
docker ps

# View nginx configuration
docker exec bmi-chat-frontend cat /etc/nginx/nginx.conf

# Test nginx configuration
docker exec bmi-chat-frontend nginx -t

# Check backend logs
docker logs bmi-chat-backend

# Check frontend logs
docker logs bmi-chat-frontend
```

## 🔒 Security Considerations

1. **Environment Variables**
   - Never commit `.env` files to version control
   - Use strong, unique SECRET_KEY
   - Keep OpenAI API key secure

2. **Network Security**
   - Use HTTPS in production
   - Configure firewall rules
   - Limit exposed ports

3. **Data Protection**
   - Regular database backups
   - Secure file uploads
   - Monitor access logs

## 📊 Performance Optimization

1. **Docker Optimization**
   - Use multi-stage builds
   - Optimize image layers
   - Use .dockerignore files

2. **Nginx Configuration**
   - Enable gzip compression
   - Configure caching headers
   - Optimize proxy settings

3. **Application Tuning**
   - Adjust API_WORKERS based on CPU cores
   - Configure proper timeouts
   - Monitor memory usage

## 🔄 Updates and Maintenance

### Updating the Application
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose -f deployment/docker/docker-compose.yml down
docker-compose -f deployment/docker/docker-compose.yml up -d --build
```

### Database Backups
```bash
# Backup SQLite database
docker exec bmi-chat-backend cp /app/data/sqlite/bmi_chat.db /app/data/sqlite/bmi_chat_backup_$(date +%Y%m%d_%H%M%S).db
```

### Log Rotation
```bash
# Clean old logs
docker system prune -f
```

## ✅ Deployment Checklist

- [ ] Environment variables configured
- [ ] Widget built for production
- [ ] Frontend built for production
- [ ] Docker containers running
- [ ] All endpoints responding (200 status)
- [ ] Widget API working
- [ ] Health checks passing
- [ ] SSL certificate configured (if using HTTPS)
- [ ] Domain DNS configured
- [ ] Monitoring set up
- [ ] Backup strategy in place

## 🆘 Support

If you encounter issues:

1. Check the logs: `docker-compose logs -f`
2. Verify environment variables
3. Test endpoints individually
4. Check nginx configuration
5. Verify widget build process

The application is now ready for production deployment with all endpoints working correctly! 