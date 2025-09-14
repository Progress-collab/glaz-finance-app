# Detailed Deployment Diagnosis Script
Write-Host "=== DETAILED DEPLOYMENT DIAGNOSIS ===" -ForegroundColor Green

# Set environment variables
$env:NODE_SKIP_PLATFORM_CHECK = "1"
Set-Location "C:\glaz-finance-app"

Write-Host "`n1. CHECKING CURRENT PROCESSES:" -ForegroundColor Yellow
Write-Host "PM2 Processes:" -ForegroundColor Cyan
pm2 list
Write-Host "`nNode.js Processes:" -ForegroundColor Cyan
Get-Process -Name "node" -ErrorAction SilentlyContinue | Format-Table

Write-Host "`n2. CHECKING FILES:" -ForegroundColor Yellow
Write-Host "Application files:" -ForegroundColor Cyan
Get-ChildItem -Name "glaz-finance-app*.js" | ForEach-Object { Write-Host "  $_" }
Write-Host "`nPublic directory:" -ForegroundColor Cyan
if (Test-Path "public") {
    Get-ChildItem "public" | ForEach-Object { Write-Host "  $($_.Name)" }
} else {
    Write-Host "  public directory NOT FOUND!" -ForegroundColor Red
}

Write-Host "`n3. CHECKING PORT 3000:" -ForegroundColor Yellow
$portCheck = netstat -an | Select-String ":3000"
if ($portCheck) {
    Write-Host "Port 3000 status:" -ForegroundColor Cyan
    $portCheck | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "Port 3000 is NOT listening!" -ForegroundColor Red
}

Write-Host "`n4. TESTING APPLICATION RESPONSE:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
    Write-Host "Response Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Content-Type: $($response.Headers.'Content-Type')" -ForegroundColor Green
    Write-Host "Content Length: $($response.Content.Length)" -ForegroundColor Green
    
    # Check content type
    if ($response.Headers.'Content-Type' -like "*text/html*") {
        Write-Host "✓ Serving HTML content (v2.0)" -ForegroundColor Green
    } elseif ($response.Headers.'Content-Type' -like "*application/json*") {
        Write-Host "❌ Serving JSON content (v1.0)" -ForegroundColor Red
    }
    
    # Show first 200 characters
    Write-Host "`nContent preview:" -ForegroundColor Cyan
    $preview = $response.Content.Substring(0, [Math]::Min(200, $response.Content.Length))
    Write-Host $preview -ForegroundColor White
    
} catch {
    Write-Host "❌ Application test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n5. CHECKING PM2 LOGS:" -ForegroundColor Yellow
try {
    pm2 logs --lines 10 --nostream
} catch {
    Write-Host "❌ Cannot get PM2 logs" -ForegroundColor Red
}

Write-Host "`n6. FORCE STOP AND RESTART:" -ForegroundColor Yellow
Write-Host "Stopping all processes..." -ForegroundColor Cyan
pm2 stop all 2>$null
pm2 delete all 2>$null
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3

Write-Host "Starting v2.0 application..." -ForegroundColor Cyan
if (Test-Path "glaz-finance-app-v2.js") {
    pm2 start glaz-finance-app-v2.js --name "glaz-finance-v2" --force
    pm2 save
    Start-Sleep -Seconds 5
    
    Write-Host "`n7. VERIFICATION AFTER RESTART:" -ForegroundColor Yellow
    Write-Host "PM2 Status:" -ForegroundColor Cyan
    pm2 list
    
    Write-Host "`nPort Status:" -ForegroundColor Cyan
    netstat -an | Select-String ":3000" | ForEach-Object { Write-Host "  $_" }
    
    Write-Host "`nFinal Test:" -ForegroundColor Cyan
    try {
        $finalResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
        Write-Host "Status: $($finalResponse.StatusCode)" -ForegroundColor Green
        Write-Host "Content-Type: $($finalResponse.Headers.'Content-Type')" -ForegroundColor Green
        
        if ($finalResponse.Headers.'Content-Type' -like "*text/html*") {
            Write-Host "✅ SUCCESS: Now serving HTML!" -ForegroundColor Green
        } else {
            Write-Host "❌ STILL SERVING JSON" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Final test failed" -ForegroundColor Red
    }
} else {
    Write-Host "❌ glaz-finance-app-v2.js NOT FOUND!" -ForegroundColor Red
}

Write-Host "`n=== DIAGNOSIS COMPLETE ===" -ForegroundColor Green
