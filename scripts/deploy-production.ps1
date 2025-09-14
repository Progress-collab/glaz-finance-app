# Production Deployment Script for Windows Server 2012 R2
# This script provides reliable deployment with proper error handling

param(
    [string]$AppName = "glaz-finance-v2",
    [string]$AppFile = "glaz-finance-app-v2.js",
    [int]$Port = 3000
)

Write-Host "=== PRODUCTION DEPLOYMENT SCRIPT ===" -ForegroundColor Green
Write-Host "App: $AppName | File: $AppFile | Port: $Port" -ForegroundColor Cyan

# Set environment variables
$env:NODE_SKIP_PLATFORM_CHECK = "1"
Write-Host "✓ Environment variables set" -ForegroundColor Green

# Navigate to application directory
Set-Location "C:\glaz-finance-app"
Write-Host "✓ Navigated to application directory" -ForegroundColor Green

# Stop ALL processes completely
Write-Host "Stopping all processes..." -ForegroundColor Yellow
try {
    # Stop PM2 processes
    pm2 stop all 2>$null
    pm2 delete all 2>$null
    Write-Host "✓ PM2 processes stopped" -ForegroundColor Green
} catch {
    Write-Host "! No PM2 processes to stop" -ForegroundColor Yellow
}

try {
    # Kill Node.js processes
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "✓ Node.js processes killed" -ForegroundColor Green
} catch {
    Write-Host "! No Node.js processes to kill" -ForegroundColor Yellow
}

# Wait for processes to fully stop
Start-Sleep -Seconds 3
Write-Host "✓ Waited for processes to stop" -ForegroundColor Green

# Pull latest changes
Write-Host "Pulling latest changes from GitHub..." -ForegroundColor Yellow
try {
    git pull origin main
    Write-Host "✓ Code updated from GitHub" -ForegroundColor Green
} catch {
    Write-Host "! Git pull failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify application file exists
if (-not (Test-Path $AppFile)) {
    Write-Host "! Application file $AppFile not found!" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Application file exists: $AppFile" -ForegroundColor Green

# Setup package.json
if (Test-Path "package-simple.json") {
    Copy-Item "package-simple.json" "package.json" -Force
    Write-Host "✓ Using simple package.json" -ForegroundColor Green
}

# Install dependencies (ignore TypeScript issues)
Write-Host "Installing dependencies..." -ForegroundColor Yellow
try {
    npm install --legacy-peer-deps --silent --ignore-scripts
    Write-Host "✓ Dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "! Dependency installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Continuing with deployment anyway..." -ForegroundColor Yellow
}

# Start application with PM2
Write-Host "Starting application with PM2..." -ForegroundColor Yellow
try {
    pm2 start $AppFile --name $AppName --force
    pm2 save
    Write-Host "✓ Application started with PM2" -ForegroundColor Green
} catch {
    Write-Host "! PM2 start failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Wait for application to start
Write-Host "Waiting for application to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Verify application is running
Write-Host "Verifying application status..." -ForegroundColor Yellow

# Check PM2 status
try {
    $pm2Status = pm2 list
    Write-Host "PM2 Status:" -ForegroundColor Cyan
    Write-Host $pm2Status -ForegroundColor White
} catch {
    Write-Host "! PM2 status check failed" -ForegroundColor Red
}

# Check port
try {
    $portCheck = netstat -an | Select-String ":$Port"
    if ($portCheck) {
        Write-Host "✓ Port $Port is listening" -ForegroundColor Green
        Write-Host $portCheck -ForegroundColor White
    } else {
        Write-Host "! Port $Port is not listening" -ForegroundColor Red
    }
} catch {
    Write-Host "! Port check failed" -ForegroundColor Red
}

# Test application response
Write-Host "Testing application response..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 10
    Write-Host "✓ Application responding - Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "✓ Content-Type: $($response.Headers.'Content-Type')" -ForegroundColor Green
    
    # Check if it's HTML or JSON
    if ($response.Content -like "*<!DOCTYPE html*" -or $response.Content -like "*<html*") {
        Write-Host "✓ Serving HTML content (v2.0)" -ForegroundColor Green
    } elseif ($response.Content -like "*{*") {
        Write-Host "! Serving JSON content (v1.0) - deployment issue!" -ForegroundColor Red
    }
} catch {
    Write-Host "! Application test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== DEPLOYMENT COMPLETE ===" -ForegroundColor Green
Write-Host "Application URL: http://195.133.47.134:$Port" -ForegroundColor Cyan
Write-Host "Local URL: http://localhost:$Port" -ForegroundColor Cyan
