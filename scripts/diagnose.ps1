# Glaz Finance App Diagnostic Script
Write-Host "=== Glaz Finance App Diagnostic ===" -ForegroundColor Green

Write-Host "1. Checking PM2 processes..." -ForegroundColor Yellow
pm2 list

Write-Host "2. Checking port status..." -ForegroundColor Yellow
netstat -an | findstr :3001
netstat -an | findstr :3002

Write-Host "3. Checking directories..." -ForegroundColor Yellow
if (Test-Path "C:\glaz-finance-app") {
    Write-Host "✅ Main directory exists" -ForegroundColor Green
    Get-ChildItem "C:\glaz-finance-app" | Select-Object Name, Mode
} else {
    Write-Host "❌ Main directory not found" -ForegroundColor Red
}

Write-Host "4. Checking backend..." -ForegroundColor Yellow
if (Test-Path "C:\glaz-finance-app\backend\index.js") {
    Write-Host "✅ Backend index.js exists" -ForegroundColor Green
} else {
    Write-Host "❌ Backend index.js not found" -ForegroundColor Red
}

Write-Host "5. Checking PM2 config..." -ForegroundColor Yellow
if (Test-Path "C:\glaz-finance-app\ecosystem-js.config.js") {
    Write-Host "✅ PM2 config exists" -ForegroundColor Green
} else {
    Write-Host "❌ PM2 config not found" -ForegroundColor Red
}

Write-Host "6. Testing local connections..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3002/health" -TimeoutSec 5
    Write-Host "✅ Backend responding: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend not responding: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001" -TimeoutSec 5
    Write-Host "✅ Frontend responding: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend not responding: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "7. Checking Windows Firewall..." -ForegroundColor Yellow
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*3001*" -or $_.DisplayName -like "*3002*"} | Select-Object DisplayName, Enabled, Direction

Write-Host "=== Diagnostic Complete ===" -ForegroundColor Green
