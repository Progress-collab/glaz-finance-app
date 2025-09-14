# Glaz Finance App v2.0 - Start Script
Write-Host "=== Starting Glaz Finance App v2.0 ===" -ForegroundColor Green

# Set working directory
Set-Location "C:\glaz-finance-app"

# Set environment variable
$env:NODE_SKIP_PLATFORM_CHECK = "1"

# Install dependencies if needed
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm install express cors --save

# Start application v2.0
Write-Host "Starting application v2.0 on port 3000..." -ForegroundColor Green
Write-Host "Features: HTML Interface + CRUD Operations" -ForegroundColor Cyan
node glaz-finance-app-v2.js
