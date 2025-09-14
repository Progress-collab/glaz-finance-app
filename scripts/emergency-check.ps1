# Emergency Check Script
Write-Host "=== EMERGENCY STATUS CHECK ===" -ForegroundColor Red

Set-Location "C:\glaz-finance-app"

Write-Host "`n1. CHECKING IF SERVER IS ALIVE:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 3
    Write-Host "✅ Server responding: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Server NOT responding: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n2. CHECKING PM2 STATUS:" -ForegroundColor Yellow
try {
    $pm2Status = pm2 list
    Write-Host "PM2 Status:" -ForegroundColor Cyan
    Write-Host $pm2Status -ForegroundColor White
} catch {
    Write-Host "❌ PM2 not responding" -ForegroundColor Red
}

Write-Host "`n3. CHECKING NODE PROCESSES:" -ForegroundColor Yellow
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "Node.js processes:" -ForegroundColor Cyan
    $nodeProcesses | Format-Table -AutoSize
} else {
    Write-Host "❌ No Node.js processes running" -ForegroundColor Red
}

Write-Host "`n4. CHECKING PORT 3000:" -ForegroundColor Yellow
$portCheck = netstat -an | Select-String ":3000"
if ($portCheck) {
    Write-Host "Port 3000 status:" -ForegroundColor Cyan
    $portCheck | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "❌ Port 3000 is NOT listening" -ForegroundColor Red
}

Write-Host "`n5. CHECKING FILES:" -ForegroundColor Yellow
Write-Host "Application files:" -ForegroundColor Cyan
Get-ChildItem -Name "glaz-finance-app*.js" | ForEach-Object { 
    $file = $_
    $size = (Get-Item $_).Length
    Write-Host "  $file ($size bytes)" 
}

Write-Host "`n6. EMERGENCY RESTART:" -ForegroundColor Yellow
Write-Host "Killing all processes..." -ForegroundColor Cyan
pm2 stop all 2>$null
pm2 delete all 2>$null
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

Write-Host "Starting simple server..." -ForegroundColor Cyan
if (Test-Path "glaz-finance-app-v2.js") {
    Write-Host "Starting glaz-finance-app-v2.js..." -ForegroundColor Green
    pm2 start glaz-finance-app-v2.js --name "glaz-finance-v2"
    Start-Sleep -Seconds 3
    
    Write-Host "`n7. FINAL CHECK:" -ForegroundColor Yellow
    try {
        $finalResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
        Write-Host "✅ SUCCESS: Server responding!" -ForegroundColor Green
        Write-Host "Status: $($finalResponse.StatusCode)" -ForegroundColor Green
        Write-Host "Content-Type: $($finalResponse.Headers.'Content-Type')" -ForegroundColor Green
    } catch {
        Write-Host "❌ Server still not responding" -ForegroundColor Red
        
        Write-Host "`nTrying manual start..." -ForegroundColor Yellow
        Start-Process -FilePath "node" -ArgumentList "glaz-finance-app-v2.js" -WindowStyle Hidden
        Start-Sleep -Seconds 3
        
        try {
            $manualResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
            Write-Host "✅ Manual start successful!" -ForegroundColor Green
        } catch {
            Write-Host "❌ Manual start also failed" -ForegroundColor Red
        }
    }
} else {
    Write-Host "❌ glaz-finance-app-v2.js NOT FOUND!" -ForegroundColor Red
}

Write-Host "`n=== EMERGENCY CHECK COMPLETE ===" -ForegroundColor Red
