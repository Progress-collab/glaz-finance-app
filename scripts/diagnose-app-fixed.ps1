# Diagnose Glaz Finance App Issues (Fixed)
# Run as Administrator

Write-Host "Diagnosing Glaz Finance App issues..." -ForegroundColor Green

$appDir = "C:\glaz-finance-app"

# Set environment variable for Node.js
$env:NODE_SKIP_PLATFORM_CHECK = "1"

Write-Host "`n=== PM2 Status ===" -ForegroundColor Yellow
try {
    pm2 list
} catch {
    Write-Host "PM2 list failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== PM2 Logs ===" -ForegroundColor Yellow
try {
    pm2 logs --lines 10
} catch {
    Write-Host "PM2 logs failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Port Status ===" -ForegroundColor Yellow
$ports = @(3001, 3002)
foreach ($port in $ports) {
    $result = netstat -an | findstr ":$port"
    if ($result) {
        Write-Host "Port ${port}: OCCUPIED" -ForegroundColor Green
        Write-Host $result -ForegroundColor White
    } else {
        Write-Host "Port ${port}: FREE" -ForegroundColor Red
    }
}

Write-Host "`n=== File Structure ===" -ForegroundColor Yellow
if (Test-Path "$appDir\backend\dist") {
    Write-Host "Backend dist: EXISTS" -ForegroundColor Green
    Get-ChildItem "$appDir\backend\dist" | Select-Object Name, Length
} else {
    Write-Host "Backend dist: MISSING" -ForegroundColor Red
}

if (Test-Path "$appDir\frontend\build") {
    Write-Host "Frontend build: EXISTS" -ForegroundColor Green
    Get-ChildItem "$appDir\frontend\build" | Select-Object Name, Length
} else {
    Write-Host "Frontend build: MISSING" -ForegroundColor Red
}

Write-Host "`n=== Package.json ===" -ForegroundColor Yellow
if (Test-Path "$appDir\package.json") {
    Write-Host "Root package.json: EXISTS" -ForegroundColor Green
} else {
    Write-Host "Root package.json: MISSING" -ForegroundColor Red
}

if (Test-Path "$appDir\backend\package.json") {
    Write-Host "Backend package.json: EXISTS" -ForegroundColor Green
} else {
    Write-Host "Backend package.json: MISSING" -ForegroundColor Red
}

if (Test-Path "$appDir\frontend\package.json") {
    Write-Host "Frontend package.json: EXISTS" -ForegroundColor Green
} else {
    Write-Host "Frontend package.json: MISSING" -ForegroundColor Red
}

Write-Host "`n=== Node.js Version ===" -ForegroundColor Yellow
try {
    node --version
} catch {
    Write-Host "Node.js not found or not working" -ForegroundColor Red
}

Write-Host "`n=== NPM Version ===" -ForegroundColor Yellow
try {
    npm --version
} catch {
    Write-Host "NPM not found or not working" -ForegroundColor Red
}

Write-Host "`n=== Redis Service ===" -ForegroundColor Yellow
$redisService = Get-Service | Where-Object {$_.Name -like "*redis*" -or $_.Name -like "*memurai*"}
if ($redisService) {
    Write-Host "Redis service: $($redisService.Name) - $($redisService.Status)" -ForegroundColor Green
} else {
    Write-Host "Redis service: NOT FOUND" -ForegroundColor Red
}

Write-Host "`n=== Quick Fix Commands ===" -ForegroundColor Cyan
Write-Host "1. pm2 stop all" -ForegroundColor White
Write-Host "2. pm2 start ecosystem-sqlite.config.js" -ForegroundColor White
Write-Host "3. pm2 save" -ForegroundColor White
Write-Host "4. pm2 list" -ForegroundColor White
