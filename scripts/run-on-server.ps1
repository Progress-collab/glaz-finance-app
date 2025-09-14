# PowerShell script for direct server execution
Write-Host "=== RUNNING ON SERVER DIRECTLY ===" -ForegroundColor Green
Write-Host "This script runs directly on Windows Server with full output" -ForegroundColor Cyan

Set-Location "C:\glaz-finance-app"

Write-Host "`n1. SETTING ENVIRONMENT VARIABLES:" -ForegroundColor Yellow
$env:NODE_SKIP_PLATFORM_CHECK = "1"
Write-Host "✓ NODE_SKIP_PLATFORM_CHECK = 1" -ForegroundColor Green

Write-Host "`n2. CHECKING CURRENT STATUS:" -ForegroundColor Yellow
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host "Current user: $env:USERNAME" -ForegroundColor Cyan

Write-Host "`n3. GIT STATUS:" -ForegroundColor Yellow
Write-Host "Git status:" -ForegroundColor Cyan
git status
Write-Host "`nGit remote:" -ForegroundColor Cyan
git remote -v
Write-Host "`nCurrent branch:" -ForegroundColor Cyan
git branch

Write-Host "`n4. CURRENT FILES:" -ForegroundColor Yellow
Write-Host "Application files:" -ForegroundColor Cyan
Get-ChildItem "glaz-finance-app*.js" | ForEach-Object { 
    Write-Host "  $($_.Name) - $($_.LastWriteTime) - $($_.Length) bytes" 
}

Write-Host "`n5. PUBLIC DIRECTORY:" -ForegroundColor Yellow
if (Test-Path "public") {
    Write-Host "✓ public directory exists" -ForegroundColor Green
    Write-Host "Contents:" -ForegroundColor Cyan
    Get-ChildItem "public" | ForEach-Object { 
        Write-Host "  $($_.Name) - $($_.Length) bytes" 
    }
} else {
    Write-Host "❌ public directory NOT FOUND!" -ForegroundColor Red
}

Write-Host "`n6. STOPPING ALL PROCESSES:" -ForegroundColor Yellow
Write-Host "PM2 processes:" -ForegroundColor Cyan
pm2 stop all
pm2 delete all
Write-Host "Node.js processes:" -ForegroundColor Cyan
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "✓ All processes stopped" -ForegroundColor Green

Write-Host "`n7. FORCE GIT PULL:" -ForegroundColor Yellow
Write-Host "Stashing changes..." -ForegroundColor Cyan
git stash
Write-Host "Fetching from remote..." -ForegroundColor Cyan
git fetch origin
Write-Host "Hard reset to origin/main..." -ForegroundColor Cyan
git reset --hard origin/main
Write-Host "Pulling latest changes..." -ForegroundColor Cyan
git pull origin main
Write-Host "✓ Git sync complete" -ForegroundColor Green

Write-Host "`n8. CHECKING FILES AFTER SYNC:" -ForegroundColor Yellow
Write-Host "Application files:" -ForegroundColor Cyan
Get-ChildItem "glaz-finance-app*.js" | ForEach-Object { 
    Write-Host "  $($_.Name) - $($_.LastWriteTime) - $($_.Length) bytes" 
}

if (Test-Path "public") {
    Write-Host "✓ public directory now exists" -ForegroundColor Green
    Write-Host "Contents:" -ForegroundColor Cyan
    Get-ChildItem "public" | ForEach-Object { 
        Write-Host "  $($_.Name) - $($_.Length) bytes" 
    }
} else {
    Write-Host "❌ public directory STILL NOT FOUND!" -ForegroundColor Red
}

Write-Host "`n9. INSTALLING DEPENDENCIES:" -ForegroundColor Yellow
Write-Host "Using simple package.json..." -ForegroundColor Cyan
if (Test-Path "package-simple.json") {
    Copy-Item "package-simple.json" "package.json" -Force
    Write-Host "✓ package.json updated" -ForegroundColor Green
}

Write-Host "Installing dependencies..." -ForegroundColor Cyan
npm install --legacy-peer-deps
Write-Host "✓ Dependencies installed" -ForegroundColor Green

Write-Host "`n10. STARTING APPLICATION:" -ForegroundColor Yellow
if (Test-Path "glaz-finance-app-v2.js") {
    Write-Host "✓ glaz-finance-app-v2.js found" -ForegroundColor Green
    Write-Host "Starting with PM2..." -ForegroundColor Cyan
    pm2 start glaz-finance-app-v2.js --name "glaz-finance-v2"
    pm2 save
    Write-Host "✓ Application started" -ForegroundColor Green
    
    Write-Host "`nWaiting for startup..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
    
    Write-Host "`n11. TESTING APPLICATION:" -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
        Write-Host "✅ SUCCESS: Server responding!" -ForegroundColor Green
        Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Content-Type: $($response.Headers.'Content-Type')" -ForegroundColor Green
        Write-Host "Content Length: $($response.Content.Length) bytes" -ForegroundColor Green
        
        # Check if HTML or JSON
        if ($response.Headers.'Content-Type' -like "*text/html*") {
            Write-Host "✅ Serving HTML content (v2.0 interface)" -ForegroundColor Green
        } elseif ($response.Headers.'Content-Type' -like "*application/json*") {
            Write-Host "⚠️  Serving JSON content (v1.0 API)" -ForegroundColor Yellow
        }
        
        # Show first 200 characters
        Write-Host "`nContent preview:" -ForegroundColor Cyan
        $preview = $response.Content.Substring(0, [Math]::Min(200, $response.Content.Length))
        Write-Host $preview -ForegroundColor White
        
    } catch {
        Write-Host "❌ Application test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n12. PM2 STATUS:" -ForegroundColor Yellow
    pm2 list
    
    Write-Host "`n13. PORT STATUS:" -ForegroundColor Yellow
    $portCheck = netstat -an | Select-String ":3000"
    if ($portCheck) {
        Write-Host "Port 3000 status:" -ForegroundColor Cyan
        $portCheck | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "❌ Port 3000 not listening" -ForegroundColor Red
    }
    
} else {
    Write-Host "❌ ERROR: glaz-finance-app-v2.js NOT FOUND!" -ForegroundColor Red
}

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green
Write-Host "Check http://195.133.47.134:3000 in your browser" -ForegroundColor Cyan
