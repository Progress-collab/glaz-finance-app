# Auto Update Script - runs automatically on server
param(
    [string]$RepoPath = "C:\glaz-finance-app"
)

Write-Host "=== AUTO UPDATE FROM GITHUB ===" -ForegroundColor Green
Write-Host "Repository: $RepoPath" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Cyan

# Navigate to repository
Set-Location $RepoPath

# Set environment variables
$env:NODE_SKIP_PLATFORM_CHECK = "1"

Write-Host "`n1. CHECKING GIT STATUS:" -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "Local changes detected, stashing..." -ForegroundColor Yellow
    git stash
}

Write-Host "`n2. FETCHING FROM GITHUB:" -ForegroundColor Yellow
try {
    git fetch origin
    Write-Host "✓ Fetch successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Fetch failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n3. CHECKING FOR UPDATES:" -ForegroundColor Yellow
$localCommit = git rev-parse HEAD
$remoteCommit = git rev-parse origin/main

if ($localCommit -eq $remoteCommit) {
    Write-Host "✓ Repository is up to date" -ForegroundColor Green
    Write-Host "No updates needed" -ForegroundColor Cyan
} else {
    Write-Host "🔄 Updates available!" -ForegroundColor Yellow
    Write-Host "Local:  $localCommit" -ForegroundColor Cyan
    Write-Host "Remote: $remoteCommit" -ForegroundColor Cyan
    
    Write-Host "`n4. UPDATING REPOSITORY:" -ForegroundColor Yellow
    try {
        # Clean untracked files
        git clean -fd
        
        # Hard reset to remote
        git reset --hard origin/main
        
        Write-Host "✓ Repository updated successfully" -ForegroundColor Green
        
        # Check if critical files exist
        $criticalFiles = @("glaz-finance-app-v2.js", "public\index.html", "scripts\run-on-server.ps1")
        $missingFiles = @()
        
        foreach ($file in $criticalFiles) {
            if (-not (Test-Path $file)) {
                $missingFiles += $file
            }
        }
        
        if ($missingFiles.Count -gt 0) {
            Write-Host "⚠️  Warning: Missing critical files:" -ForegroundColor Yellow
            $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        } else {
            Write-Host "✓ All critical files present" -ForegroundColor Green
        }
        
        Write-Host "`n5. RESTARTING APPLICATION:" -ForegroundColor Yellow
        # Stop existing processes
        pm2 stop all 2>$null
        pm2 delete all 2>$null
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
        
        # Wait for processes to stop
        Start-Sleep -Seconds 3
        
        # Install dependencies if needed
        if (Test-Path "package-simple.json") {
            Copy-Item "package-simple.json" "package.json" -Force
            npm install --legacy-peer-deps --silent
        }
        
        # Start application
        if (Test-Path "glaz-finance-app-v2.js") {
            pm2 start glaz-finance-app-v2.js --name "glaz-finance-v2"
            pm2 save
            
            Write-Host "✓ Application restarted" -ForegroundColor Green
            
            # Test application
            Start-Sleep -Seconds 5
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
                Write-Host "✓ Application responding: $($response.StatusCode)" -ForegroundColor Green
            } catch {
                Write-Host "⚠️  Application test failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "❌ Application file not found!" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "❌ Update failed: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n=== AUTO UPDATE COMPLETE ===" -ForegroundColor Green
