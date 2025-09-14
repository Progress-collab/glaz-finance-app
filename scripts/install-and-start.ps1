# Glaz Finance App - Install and Start Script
Write-Host "=== Glaz Finance App Installation ===" -ForegroundColor Green

# Set working directory
Set-Location "C:\glaz-finance-app"

# Install Node.js if not installed
Write-Host "Checking Node.js installation..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "Node.js version: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Node.js not found. Please install Node.js first." -ForegroundColor Red
    Write-Host "Download from: https://nodejs.org/en/download/" -ForegroundColor Yellow
    exit 1
}

# Install PM2 globally if not installed
Write-Host "Installing PM2 globally..." -ForegroundColor Yellow
npm install -g pm2

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm install
npm install -g typescript

# Install backend dependencies
Write-Host "Installing backend dependencies..." -ForegroundColor Yellow
Set-Location "backend"
npm install
Set-Location ".."

# Install frontend dependencies
Write-Host "Installing frontend dependencies..." -ForegroundColor Yellow
Set-Location "frontend"
npm install --legacy-peer-deps
Set-Location ".."

# Create PM2 ecosystem file
Write-Host "Creating PM2 configuration..." -ForegroundColor Yellow
@"
module.exports = {
  apps : [{
    name: 'glaz-finance-backend',
    script: './backend/index.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3002,
      NODE_SKIP_PLATFORM_CHECK: '1'
    }
  }]
};
"@ | Out-File -FilePath "ecosystem.config.js" -Encoding UTF8

# Stop existing PM2 processes
Write-Host "Stopping existing PM2 processes..." -ForegroundColor Yellow
pm2 stop all
pm2 delete all

# Start with PM2
Write-Host "Starting application with PM2..." -ForegroundColor Yellow
pm2 start ecosystem.config.js
pm2 save

# Show status
Write-Host "PM2 Status:" -ForegroundColor Green
pm2 list

Write-Host "Port Status:" -ForegroundColor Green
netstat -an | findstr :3002

Write-Host "=== Installation Complete ===" -ForegroundColor Green
Write-Host "Application should be available at: http://localhost:3002" -ForegroundColor Cyan
Write-Host "External access: http://195.133.47.134:3002" -ForegroundColor Cyan
