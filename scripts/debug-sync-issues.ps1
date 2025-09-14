# Debug Sync Issues Script
Write-Host "=== DEBUGGING SYNC ISSUES ===" -ForegroundColor Red

Set-Location "C:\glaz-finance-app"

Write-Host "`n1. CHECKING GIT STATUS:" -ForegroundColor Yellow
Write-Host "Current directory:" -ForegroundColor Cyan
Get-Location
Write-Host "`nGit status:" -ForegroundColor Cyan
git status
Write-Host "`nGit remote:" -ForegroundColor Cyan
git remote -v
Write-Host "`nCurrent branch:" -ForegroundColor Cyan
git branch

Write-Host "`n2. CHECKING FILE TIMESTAMPS:" -ForegroundColor Yellow
Write-Host "Application files:" -ForegroundColor Cyan
Get-ChildItem "glaz-finance-app*.js" | ForEach-Object { 
    Write-Host "  $($_.Name) - $($_.LastWriteTime) - $($_.Length) bytes" 
}

Write-Host "`nPublic directory:" -ForegroundColor Cyan
if (Test-Path "public") {
    Get-ChildItem "public" | ForEach-Object { 
        Write-Host "  $($_.Name) - $($_.LastWriteTime) - $($_.Length) bytes" 
    }
} else {
    Write-Host "  ❌ public directory NOT FOUND!" -ForegroundColor Red
}

Write-Host "`n3. FORCE GIT PULL:" -ForegroundColor Yellow
Write-Host "Stashing local changes..." -ForegroundColor Cyan
git stash
Write-Host "Fetching from remote..." -ForegroundColor Cyan
git fetch origin
Write-Host "Hard reset to origin/main..." -ForegroundColor Cyan
git reset --hard origin/main
Write-Host "Pulling latest changes..." -ForegroundColor Cyan
git pull origin main

Write-Host "`n4. VERIFYING FILES AFTER SYNC:" -ForegroundColor Yellow
Write-Host "Application files:" -ForegroundColor Cyan
Get-ChildItem "glaz-finance-app*.js" | ForEach-Object { 
    Write-Host "  $($_.Name) - $($_.LastWriteTime) - $($_.Length) bytes" 
}

Write-Host "`nPublic directory:" -ForegroundColor Cyan
if (Test-Path "public") {
    Get-ChildItem "public" | ForEach-Object { 
        Write-Host "  $($_.Name) - $($_.LastWriteTime) - $($_.Length) bytes" 
    }
} else {
    Write-Host "  ❌ public directory STILL NOT FOUND!" -ForegroundColor Red
}

Write-Host "`n5. CHECKING PORT CONFLICTS:" -ForegroundColor Yellow
Write-Host "Processes using port 3000:" -ForegroundColor Cyan
$portProcesses = netstat -ano | Select-String ":3000"
if ($portProcesses) {
    $portProcesses | ForEach-Object { Write-Host "  $_" }
    
    Write-Host "`nKilling processes on port 3000..." -ForegroundColor Yellow
    $portProcesses | ForEach-Object {
        $line = $_.Line
        if ($line -match "LISTENING\s+(\d+)") {
            $pid = $matches[1]
            Write-Host "Killing process $pid..." -ForegroundColor Cyan
            try {
                Stop-Process -Id $pid -Force
                Write-Host "  ✓ Process $pid killed" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Failed to kill process $pid" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "  ✓ Port 3000 is free" -ForegroundColor Green
}

Write-Host "`n6. MANUAL FILE CREATION TEST:" -ForegroundColor Yellow
if (-not (Test-Path "public")) {
    Write-Host "Creating public directory manually..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path "public" -Force
}

if (-not (Test-Path "public\index.html")) {
    Write-Host "Creating index.html manually..." -ForegroundColor Cyan
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head><title>Test</title></head>
<body><h1>Test Page</h1></body>
</html>
"@
    $htmlContent | Out-File -FilePath "public\index.html" -Encoding UTF8
    Write-Host "  ✓ index.html created" -ForegroundColor Green
}

Write-Host "`n7. STARTING APPLICATION:" -ForegroundColor Yellow
Write-Host "Using simple package.json..." -ForegroundColor Cyan
if (Test-Path "package-simple.json") {
    Copy-Item "package-simple.json" "package.json" -Force
    Write-Host "  ✓ package.json updated" -ForegroundColor Green
}

Write-Host "Installing dependencies..." -ForegroundColor Cyan
npm install --legacy-peer-deps --silent

Write-Host "Starting application..." -ForegroundColor Cyan
if (Test-Path "glaz-finance-app-v2.js") {
    pm2 start glaz-finance-app-v2.js --name "glaz-finance-v2" --force
    Start-Sleep -Seconds 3
    
    Write-Host "`n8. FINAL TEST:" -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
        Write-Host "✅ SUCCESS: Server responding!" -ForegroundColor Green
        Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Content-Type: $($response.Headers.'Content-Type')" -ForegroundColor Green
        Write-Host "Content Length: $($response.Content.Length)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Server still not responding: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ glaz-finance-app-v2.js NOT FOUND!" -ForegroundColor Red
}

Write-Host "`n=== SYNC DEBUG COMPLETE ===" -ForegroundColor Red
