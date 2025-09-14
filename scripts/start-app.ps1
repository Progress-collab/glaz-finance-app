# Glaz Finance App - Start Script
Write-Host "=== Starting Glaz Finance App ===" -ForegroundColor Green

# Set working directory
Set-Location "C:\glaz-finance-app"

# Set environment variable
$env:NODE_SKIP_PLATFORM_CHECK = "1"

# Install dependencies if needed
Write-Host "Installing dependencies..." -ForegroundColor Yellow
npm install express cors --save

# Start application
Write-Host "Starting application on port 3000..." -ForegroundColor Green
node glaz-finance-app.js
