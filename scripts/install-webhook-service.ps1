# Install Webhook as Windows Service - makes it run automatically on server startup
Write-Host "=== INSTALLING WEBHOOK AS WINDOWS SERVICE ===" -ForegroundColor Green

$RepoPath = "C:\glaz-finance-app"
$ServiceName = "GlazFinanceWebhook"
$ServiceDisplayName = "Glaz Finance Webhook Server"
$ServiceDescription = "GitHub webhook server for automatic deployment"

Write-Host "Repository: $RepoPath" -ForegroundColor Cyan
Write-Host "Service Name: $ServiceName" -ForegroundColor Cyan

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Running as Administrator" -ForegroundColor Green

# Stop and remove existing service if it exists
Write-Host "`n1. Checking for existing service..." -ForegroundColor Yellow
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($existingService) {
    Write-Host "Found existing service, stopping it..." -ForegroundColor Yellow
    
    if ($existingService.Status -eq "Running") {
        Stop-Service -Name $ServiceName -Force
        Write-Host "✓ Service stopped" -ForegroundColor Green
    }
    
    # Remove service using sc.exe (more reliable than Remove-Service on Windows Server 2012)
    $result = & sc.exe delete $ServiceName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Existing service removed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Warning removing service: $result" -ForegroundColor Yellow
    }
    
    Start-Sleep -Seconds 2
}

# Create service wrapper script
Write-Host "`n2. Creating service wrapper script..." -ForegroundColor Yellow

$wrapperScript = @"
# Webhook Service Wrapper
param([string]`$Action)

`$RepoPath = "$RepoPath"
`$WebhookScript = "`$RepoPath\scripts\webhook-server.ps1"
`$LogFile = "`$RepoPath\logs\webhook-service.log"

# Create logs directory
if (-not (Test-Path "`$RepoPath\logs")) {
    New-Item -ItemType Directory -Path "`$RepoPath\logs" -Force | Out-Null
}

function Write-Log {
    param([string]`$Message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMessage = "[`$timestamp] `$Message"
    Add-Content -Path `$LogFile -Value `$logMessage
    Write-Host `$logMessage
}

try {
    Set-Location `$RepoPath
    
    if (`$Action -eq "start") {
        Write-Log "Starting webhook server service..."
        
        # Set environment variables
        `$env:NODE_SKIP_PLATFORM_CHECK = "1"
        
        # Start webhook server
        powershell -ExecutionPolicy Bypass -File `$WebhookScript -Port 9000
        
    } elseif (`$Action -eq "stop") {
        Write-Log "Stopping webhook server service..."
        
        # Stop any running webhook processes
        Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
            Where-Object { `$_.CommandLine -like "*webhook-server.ps1*" } | 
            Stop-Process -Force -ErrorAction SilentlyContinue
            
        Write-Log "Webhook server service stopped"
    }
    
} catch {
    Write-Log "Error in webhook service: `$(`$_.Exception.Message)"
    exit 1
}
"@

$wrapperPath = "$RepoPath\scripts\webhook-service-wrapper.ps1"
$wrapperScript | Out-File -FilePath $wrapperPath -Encoding UTF8

Write-Host "✓ Service wrapper script created" -ForegroundColor Green

# Create service using sc.exe
Write-Host "`n3. Creating Windows service..." -ForegroundColor Yellow

$serviceCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$wrapperPath`" start"
$result = & sc.exe create $ServiceName binPath= $serviceCommand DisplayName= $ServiceDisplayName start= auto 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Windows service created successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to create service: $result" -ForegroundColor Red
    exit 1
}

# Set service description
& sc.exe description $ServiceName $ServiceDescription | Out-Null

# Start the service
Write-Host "`n4. Starting service..." -ForegroundColor Yellow

try {
    Start-Service -Name $ServiceName
    Write-Host "✓ Service started successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to start service: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Wait and check service status
Start-Sleep -Seconds 5

$service = Get-Service -Name $ServiceName
Write-Host "`n5. Service status:" -ForegroundColor Yellow
Write-Host "   Name: $($service.Name)" -ForegroundColor Cyan
Write-Host "   Display Name: $($service.DisplayName)" -ForegroundColor Cyan
Write-Host "   Status: $($service.Status)" -ForegroundColor Cyan
Write-Host "   Start Type: $($service.StartType)" -ForegroundColor Cyan

# Test webhook endpoint
Write-Host "`n6. Testing webhook endpoint..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri "http://localhost:9000/" -TimeoutSec 10
    Write-Host "✓ Webhook server responding: $($response.Content)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Webhook server not responding yet (might still be starting)" -ForegroundColor Yellow
    Write-Host "Wait a few more seconds and try: http://localhost:9000/" -ForegroundColor Cyan
}

Write-Host "`n=== WEBHOOK SERVICE INSTALLED ===" -ForegroundColor Green
Write-Host "Service Name: $ServiceName" -ForegroundColor Cyan
Write-Host "Webhook URL: http://195.133.47.134:9000/webhook" -ForegroundColor Cyan
Write-Host "Health Check: http://195.133.47.134:9000/" -ForegroundColor Cyan
Write-Host "Log File: $RepoPath\logs\webhook-service.log" -ForegroundColor Cyan

Write-Host "`n=== SERVICE MANAGEMENT COMMANDS ===" -ForegroundColor Green
Write-Host "Start service:   Start-Service -Name $ServiceName" -ForegroundColor White
Write-Host "Stop service:    Stop-Service -Name $ServiceName" -ForegroundColor White
Write-Host "Restart service: Restart-Service -Name $ServiceName" -ForegroundColor White
Write-Host "Service status:  Get-Service -Name $ServiceName" -ForegroundColor White
Write-Host "View logs:       Get-Content $RepoPath\logs\webhook-service.log -Tail 20" -ForegroundColor White

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Green
Write-Host "1. Configure GitHub webhook in repository settings:" -ForegroundColor Yellow
Write-Host "   URL: http://195.133.47.134:9000/webhook" -ForegroundColor White
Write-Host "   Content type: application/json" -ForegroundColor White
Write-Host "   Events: Just the push event" -ForegroundColor White

Write-Host "`n2. Test by making a commit and push to main branch" -ForegroundColor Yellow

Write-Host "`n✓ Webhook service is now running automatically!" -ForegroundColor Green
