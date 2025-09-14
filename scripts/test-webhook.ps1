# Test Webhook System - tests the webhook deployment system
Write-Host "=== TESTING WEBHOOK DEPLOYMENT SYSTEM ===" -ForegroundColor Green

$RepoPath = "C:\glaz-finance-app"
$WebhookUrl = "http://localhost:9000/webhook"
$HealthUrl = "http://localhost:9000/"

Write-Host "Repository: $RepoPath" -ForegroundColor Cyan
Write-Host "Webhook URL: $WebhookUrl" -ForegroundColor Cyan
Write-Host "Health URL: $HealthUrl" -ForegroundColor Cyan

# Test 1: Check if webhook server is running
Write-Host "`n1. Testing webhook server health..." -ForegroundColor Yellow

try {
    $response = Invoke-WebRequest -Uri $HealthUrl -TimeoutSec 10
    Write-Host "✓ Webhook server is responding" -ForegroundColor Green
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Cyan
    Write-Host "   Content: $($response.Content)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Webhook server not responding" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   Make sure webhook service is running:" -ForegroundColor Yellow
    Write-Host "   Get-Service -Name GlazFinanceWebhook" -ForegroundColor White
    exit 1
}

# Test 2: Check service status
Write-Host "`n2. Checking Windows service status..." -ForegroundColor Yellow

try {
    $service = Get-Service -Name "GlazFinanceWebhook" -ErrorAction Stop
    Write-Host "✓ Service found" -ForegroundColor Green
    Write-Host "   Name: $($service.Name)" -ForegroundColor Cyan
    Write-Host "   Status: $($service.Status)" -ForegroundColor Cyan
    Write-Host "   Start Type: $($service.StartType)" -ForegroundColor Cyan
    
    if ($service.Status -ne "Running") {
        Write-Host "⚠️  Service is not running, starting it..." -ForegroundColor Yellow
        Start-Service -Name "GlazFinanceWebhook"
        Start-Sleep -Seconds 3
        
        $service = Get-Service -Name "GlazFinanceWebhook"
        Write-Host "   New Status: $($service.Status)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ Webhook service not found" -ForegroundColor Red
    Write-Host "   Install it with: scripts\install-webhook-service.ps1" -ForegroundColor Yellow
    exit 1
}

# Test 3: Check repository status
Write-Host "`n3. Checking repository status..." -ForegroundColor Yellow

Set-Location $RepoPath

$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠️  Repository has uncommitted changes:" -ForegroundColor Yellow
    Write-Host $gitStatus -ForegroundColor Cyan
} else {
    Write-Host "✓ Repository is clean" -ForegroundColor Green
}

$gitBranch = git branch --show-current
Write-Host "   Current branch: $gitBranch" -ForegroundColor Cyan

$gitRemote = git remote -v
Write-Host "   Remote: $gitRemote" -ForegroundColor Cyan

# Test 4: Test webhook endpoint with sample payload
Write-Host "`n4. Testing webhook endpoint..." -ForegroundColor Yellow

$samplePayload = @{
    ref = "refs/heads/main"
    head_commit = @{
        id = "test-commit-123"
        message = "Test webhook payload"
    }
    repository = @{
        name = "glaz-finance-app"
    }
} | ConvertTo-Json -Depth 3

try {
    $response = Invoke-WebRequest -Uri $WebhookUrl -Method POST -Body $samplePayload -ContentType "application/json" -TimeoutSec 30
    Write-Host "✓ Webhook endpoint responded" -ForegroundColor Green
    Write-Host "   Status: $($response.StatusCode)" -ForegroundColor Cyan
    Write-Host "   Response: $($response.Content)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Webhook endpoint test failed" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 5: Check application status
Write-Host "`n5. Checking application status..." -ForegroundColor Yellow

try {
    $appResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
    Write-Host "✓ Application is responding" -ForegroundColor Green
    Write-Host "   Status: $($appResponse.StatusCode)" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️  Application not responding on port 3000" -ForegroundColor Yellow
    Write-Host "   This is normal if app hasn't been deployed yet" -ForegroundColor Cyan
}

# Test 6: Check PM2 status
Write-Host "`n6. Checking PM2 status..." -ForegroundColor Yellow

try {
    $pm2List = pm2 list
    if ($pm2List) {
        Write-Host "✓ PM2 is running" -ForegroundColor Green
        Write-Host "   Processes:" -ForegroundColor Cyan
        Write-Host $pm2List -ForegroundColor White
    } else {
        Write-Host "⚠️  No PM2 processes running" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  PM2 not available or no processes" -ForegroundColor Yellow
}

# Test 7: Check firewall rules
Write-Host "`n7. Checking firewall rules..." -ForegroundColor Yellow

try {
    $firewallRules = netsh advfirewall firewall show rule name="Glaz Finance App" 2>$null
    if ($firewallRules) {
        Write-Host "✓ Firewall rule for port 3000 exists" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No firewall rule for port 3000" -ForegroundColor Yellow
        Write-Host "   Add with: netsh advfirewall firewall add rule name=`"Glaz Finance App`" dir=in action=allow protocol=TCP localport=3000" -ForegroundColor White
    }
} catch {
    Write-Host "⚠️  Could not check firewall rules" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== WEBHOOK SYSTEM TEST SUMMARY ===" -ForegroundColor Green

Write-Host "✅ Webhook server: $($response.StatusCode -eq 200 ? 'OK' : 'FAILED')" -ForegroundColor $(if ($response.StatusCode -eq 200) { "Green" } else { "Red" })
Write-Host "✅ Windows service: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Yellow" })
Write-Host "✅ Repository: $(if ($gitStatus) { 'Has changes' } else { 'Clean' })" -ForegroundColor $(if ($gitStatus) { "Yellow" } else { "Green" })

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Green
Write-Host "1. Configure GitHub webhook:" -ForegroundColor Yellow
Write-Host "   URL: http://195.133.47.134:9000/webhook" -ForegroundColor White
Write-Host "   Content type: application/json" -ForegroundColor White
Write-Host "   Events: Just the push event" -ForegroundColor White

Write-Host "`n2. Test deployment:" -ForegroundColor Yellow
Write-Host "   Make a commit and push to main branch" -ForegroundColor White
Write-Host "   Watch the webhook server logs" -ForegroundColor White

Write-Host "`n3. Monitor logs:" -ForegroundColor Yellow
Write-Host "   Get-Content $RepoPath\logs\webhook-service.log -Tail 20" -ForegroundColor White

Write-Host "`n=== WEBHOOK SYSTEM READY ===" -ForegroundColor Green
