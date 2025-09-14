# Manual deployment script for Windows Server 2012 R2
# Run this script on the server to deploy the application

Write-Host "Starting manual deployment..." -ForegroundColor Green

$appDir = "C:\glaz-finance-app"
$repoUrl = "https://github.com/Progress-collab/glaz-finance-app.git"

# Set environment variables
$env:NODE_SKIP_PLATFORM_CHECK = "1"

# Navigate to application directory
if (!(Test-Path $appDir)) {
    New-Item -ItemType Directory -Path $appDir -Force
}

cd $appDir

# Stop existing PM2 processes
Write-Host "Stopping existing PM2 processes..." -ForegroundColor Yellow
pm2 stop all

# Pull latest changes
Write-Host "Pulling latest changes from GitHub..." -ForegroundColor Yellow
if (Test-Path ".git") {
    git pull origin main
} else {
    git clone $repoUrl .
}

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm install

# Build application
Write-Host "Building application..." -ForegroundColor Yellow
npm run build

# Start with PM2
Write-Host "Starting application with PM2..." -ForegroundColor Yellow
pm2 start ecosystem-sqlite.config.js
pm2 save

# Show status
Write-Host "`n=== PM2 Status ===" -ForegroundColor Cyan
pm2 list

# Show port status
Write-Host "`n=== Port Status ===" -ForegroundColor Cyan
Write-Host "Port 3001 (Frontend):" -ForegroundColor White
netstat -an | findstr :3001
Write-Host "Port 3002 (Backend):" -ForegroundColor White
netstat -an | findstr :3002

Write-Host "`nDeployment completed!" -ForegroundColor Green
Write-Host "Application should be available at: http://195.133.47.134:3001" -ForegroundColor Yellow

Write-Host "`nUseful commands:" -ForegroundColor Cyan
Write-Host "pm2 status          - Check application status" -ForegroundColor White
Write-Host "pm2 logs            - View application logs" -ForegroundColor White
Write-Host "pm2 restart all     - Restart all applications" -ForegroundColor White
Write-Host "pm2 stop all        - Stop all applications" -ForegroundColor White
