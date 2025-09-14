# Start Webhook Server - starts the GitHub webhook listener
Write-Host "=== STARTING GITHUB WEBHOOK SERVER ===" -ForegroundColor Green

$RepoPath = "C:\glaz-finance-app"
$WebhookScript = "$RepoPath\scripts\webhook-server.ps1"
$Port = 9000

Write-Host "Repository: $RepoPath" -ForegroundColor Cyan
Write-Host "Webhook Script: $WebhookScript" -ForegroundColor Cyan
Write-Host "Port: $Port" -ForegroundColor Cyan

# Check if webhook server script exists
if (-not (Test-Path $WebhookScript)) {
    Write-Host "❌ Webhook server script not found!" -ForegroundColor Red
    Write-Host "Make sure you've pulled the latest changes from GitHub" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Webhook server script found" -ForegroundColor Green

# Check if port is available
try {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
    $listener.Start()
    $listener.Stop()
    Write-Host "✓ Port $Port is available" -ForegroundColor Green
} catch {
    Write-Host "❌ Port $Port is already in use!" -ForegroundColor Red
    Write-Host "Try a different port or stop the existing webhook server" -ForegroundColor Yellow
    exit 1
}

# Start webhook server in background
Write-Host "`nStarting webhook server..." -ForegroundColor Yellow
Write-Host "The server will run in the background" -ForegroundColor Cyan
Write-Host "Webhook URL: http://195.133.47.134:$Port/webhook" -ForegroundColor Cyan
Write-Host "Health check: http://195.133.47.134:$Port/" -ForegroundColor Cyan

try {
    # Start webhook server as background job
    $job = Start-Job -ScriptBlock {
        param($scriptPath, $port)
        Set-Location "C:\glaz-finance-app"
        powershell -ExecutionPolicy Bypass -File $scriptPath -Port $port
    } -ArgumentList $WebhookScript, $Port
    
    Write-Host "✓ Webhook server started as background job (ID: $($job.Id))" -ForegroundColor Green
    
    # Wait a moment and check if it's running
    Start-Sleep -Seconds 3
    
    if ($job.State -eq "Running") {
        Write-Host "✓ Webhook server is running successfully" -ForegroundColor Green
        
        # Test health check
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port/" -TimeoutSec 5
            Write-Host "✓ Health check successful: $($response.Content)" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Health check failed, but server might still be starting" -ForegroundColor Yellow
        }
        
        Write-Host "`n=== WEBHOOK SERVER RUNNING ===" -ForegroundColor Green
        Write-Host "Job ID: $($job.Id)" -ForegroundColor Cyan
        Write-Host "Webhook URL: http://195.133.47.134:$Port/webhook" -ForegroundColor Cyan
        Write-Host "Health check: http://195.133.47.134:$Port/" -ForegroundColor Cyan
        
        Write-Host "`nTo stop the webhook server:" -ForegroundColor Yellow
        Write-Host "  Stop-Job -Id $($job.Id)" -ForegroundColor White
        Write-Host "  Remove-Job -Id $($job.Id)" -ForegroundColor White
        
        Write-Host "`nTo check server status:" -ForegroundColor Yellow
        Write-Host "  Get-Job -Id $($job.Id)" -ForegroundColor White
        Write-Host "  Receive-Job -Id $($job.Id)" -ForegroundColor White
        
    } else {
        Write-Host "❌ Failed to start webhook server" -ForegroundColor Red
        Write-Host "Job state: $($job.State)" -ForegroundColor Yellow
        $job | Remove-Job
        exit 1
    }
    
} catch {
    Write-Host "❌ Error starting webhook server: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Green
Write-Host "1. Configure GitHub webhook:" -ForegroundColor Yellow
Write-Host "   - Go to GitHub repository settings" -ForegroundColor White
Write-Host "   - Add webhook: http://195.133.47.134:$Port/webhook" -ForegroundColor White
Write-Host "   - Content type: application/json" -ForegroundColor White
Write-Host "   - Events: Just the push event" -ForegroundColor White

Write-Host "`n2. Test the webhook:" -ForegroundColor Yellow
Write-Host "   - Make a commit and push to main branch" -ForegroundColor White
Write-Host "   - Check if server updates automatically" -ForegroundColor White

Write-Host "`n=== WEBHOOK SERVER STARTED ===" -ForegroundColor Green
