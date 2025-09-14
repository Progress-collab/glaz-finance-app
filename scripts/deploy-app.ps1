# Deploy Glaz Finance App Script
# Run as Administrator

Write-Host "Deploying Glaz Finance App..." -ForegroundColor Green

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit 1
}

$appDir = "C:\glaz-finance-app"

# Step 1: Clean and clone repository
Write-Host "Cleaning and cloning repository..." -ForegroundColor Yellow
try {
    # Remove existing files
    if (Test-Path $appDir) {
        Remove-Item "$appDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Clone repository
    git clone https://github.com/Progress-collab/glaz-finance-app.git $appDir
    Write-Host "Repository cloned successfully" -ForegroundColor Green
} catch {
    Write-Host "Error cloning repository: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
try {
    Set-Location $appDir
    npm install
    Write-Host "Dependencies installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing dependencies: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Build application
Write-Host "Building application..." -ForegroundColor Yellow
try {
    npm run build
    Write-Host "Application built successfully" -ForegroundColor Green
} catch {
    Write-Host "Error building application: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 4: Start with PM2
Write-Host "Starting application with PM2..." -ForegroundColor Yellow
try {
    # Stop existing processes
    pm2 stop all -s
    
    # Start with SQLite configuration
    pm2 start ecosystem-sqlite.config.js
    
    # Save PM2 configuration
    pm2 save
    
    Write-Host "Application started successfully with PM2" -ForegroundColor Green
} catch {
    Write-Host "Error starting application: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 5: Show status
Write-Host "`nApplication Status:" -ForegroundColor Cyan
pm2 status

Write-Host "`nDeployment completed!" -ForegroundColor Green
Write-Host "Application should be available at: http://YOUR_SERVER_IP:3001" -ForegroundColor Yellow

Write-Host "`nUseful commands:" -ForegroundColor Yellow
Write-Host "pm2 status          - Check application status" -ForegroundColor White
Write-Host "pm2 logs            - View application logs" -ForegroundColor White
Write-Host "pm2 restart all     - Restart all applications" -ForegroundColor White
Write-Host "pm2 stop all        - Stop all applications" -ForegroundColor White
