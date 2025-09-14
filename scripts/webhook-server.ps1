# Webhook Server - listens for GitHub push notifications
param(
    [int]$Port = 9000,
    [string]$Secret = "your-webhook-secret-here"
)

Write-Host "=== GITHUB WEBHOOK SERVER ===" -ForegroundColor Green
Write-Host "Port: $Port" -ForegroundColor Cyan
Write-Host "Secret: $Secret" -ForegroundColor Cyan
Write-Host "Repository: C:\glaz-finance-app" -ForegroundColor Cyan

$RepoPath = "C:\glaz-finance-app"

# Function to update repository
function Update-Repository {
    Write-Host "`n=== UPDATING REPOSITORY ===" -ForegroundColor Yellow
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Cyan
    
    Set-Location $RepoPath
    
    # Set environment variables
    $env:NODE_SKIP_PLATFORM_CHECK = "1"
    
    try {
        Write-Host "1. Stashing local changes..." -ForegroundColor Cyan
        git stash 2>$null
        
        Write-Host "2. Fetching from GitHub..." -ForegroundColor Cyan
        git fetch origin
        
        Write-Host "3. Resetting to origin/main..." -ForegroundColor Cyan
        git reset --hard origin/main
        
        Write-Host "✓ Repository updated successfully" -ForegroundColor Green
        
        Write-Host "4. Restarting application..." -ForegroundColor Cyan
        
        # Stop existing processes
        pm2 stop all 2>$null
        pm2 delete all 2>$null
        Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
        
        # Wait for processes to stop
        Start-Sleep -Seconds 2
        
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
            Start-Sleep -Seconds 3
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
                Write-Host "✓ Application responding: $($response.StatusCode)" -ForegroundColor Green
            } catch {
                Write-Host "⚠️  Application test failed" -ForegroundColor Yellow
            }
        } else {
            Write-Host "❌ Application file not found!" -ForegroundColor Red
        }
        
        return $true
        
    } catch {
        Write-Host "❌ Update failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to validate webhook signature
function Test-WebhookSignature {
    param(
        [string]$Payload,
        [string]$Signature,
        [string]$Secret
    )
    
    if ([string]::IsNullOrEmpty($Secret) -or $Secret -eq "your-webhook-secret-here") {
        Write-Host "⚠️  Warning: Using default webhook secret!" -ForegroundColor Yellow
        return $true
    }
    
    $expectedSignature = "sha256=" + [System.Convert]::ToHexString(
        [System.Security.Cryptography.HMACSHA256]::new([System.Text.Encoding]::UTF8.GetBytes($Secret))
            .ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Payload))
    ).ToLower()
    
    return $Signature -eq $expectedSignature
}

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://0.0.0.0:$Port/")

try {
    $listener.Start()
    Write-Host "✓ Webhook server started on port $Port" -ForegroundColor Green
    Write-Host "Listening for GitHub webhooks..." -ForegroundColor Cyan
    Write-Host "Webhook URL: http://195.133.47.134:$Port/webhook" -ForegroundColor Cyan
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        try {
            if ($request.Url.AbsolutePath -eq "/webhook" -and $request.HttpMethod -eq "POST") {
                Write-Host "`n=== WEBHOOK RECEIVED ===" -ForegroundColor Yellow
                Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Cyan
                Write-Host "User-Agent: $($request.Headers['User-Agent'])" -ForegroundColor Cyan
                
                # Read payload
                $reader = New-Object System.IO.StreamReader($request.InputStream)
                $payload = $reader.ReadToEnd()
                $reader.Close()
                
                # Get signature
                $signature = $request.Headers["X-Hub-Signature-256"]
                
                # Validate signature
                if (Test-WebhookSignature -Payload $payload -Signature $signature -Secret $Secret) {
                    Write-Host "✓ Webhook signature validated" -ForegroundColor Green
                    
                    # Parse JSON payload
                    try {
                        $json = $payload | ConvertFrom-Json
                        
                        if ($json.ref -eq "refs/heads/main") {
                            Write-Host "✓ Push to main branch detected" -ForegroundColor Green
                            Write-Host "Commit: $($json.head_commit.id)" -ForegroundColor Cyan
                            Write-Host "Message: $($json.head_commit.message)" -ForegroundColor Cyan
                            
                            # Update repository
                            if (Update-Repository) {
                                $response.StatusCode = 200
                                $responseBody = "OK - Repository updated successfully"
                                Write-Host "✓ Webhook processed successfully" -ForegroundColor Green
                            } else {
                                $response.StatusCode = 500
                                $responseBody = "ERROR - Repository update failed"
                                Write-Host "❌ Webhook processing failed" -ForegroundColor Red
                            }
                        } else {
                            Write-Host "⚠️  Push to branch: $($json.ref) - ignoring" -ForegroundColor Yellow
                            $response.StatusCode = 200
                            $responseBody = "OK - Non-main branch, ignored"
                        }
                    } catch {
                        Write-Host "❌ Failed to parse webhook payload" -ForegroundColor Red
                        $response.StatusCode = 400
                        $responseBody = "ERROR - Invalid payload"
                    }
                } else {
                    Write-Host "❌ Invalid webhook signature" -ForegroundColor Red
                    $response.StatusCode = 401
                    $responseBody = "ERROR - Invalid signature"
                }
            } else {
                # Health check endpoint
                $response.StatusCode = 200
                $responseBody = "GitHub Webhook Server - Ready"
            }
            
            # Send response
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseBody)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            
        } catch {
            Write-Host "❌ Error processing request: $($_.Exception.Message)" -ForegroundColor Red
            $response.StatusCode = 500
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("ERROR - Internal server error")
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
        }
    }
    
} catch {
    Write-Host "❌ Failed to start webhook server: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    Write-Host "`n=== WEBHOOK SERVER STOPPED ===" -ForegroundColor Red
}
