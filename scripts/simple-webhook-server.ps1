# Simple Webhook Server for Windows Server 2012 R2
param([int]$Port = 9000)

$RepoPath = "C:\glaz-finance-app"
$LogFile = "$RepoPath\logs\webhook.log"

# Create logs directory
if (-not (Test-Path "$RepoPath\logs")) {
    New-Item -ItemType Directory -Path "$RepoPath\logs" -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $LogFile -Value $logMessage
    Write-Host $logMessage
}

Write-Log "Starting Simple Webhook Server on port $Port..."

# Set environment variable
$env:NODE_SKIP_PLATFORM_CHECK = "1"

try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://+:$Port/")
    $listener.Start()
    
    Write-Log "Webhook server started. Listening on http://+:$Port/"
    Write-Log "Webhook URL: http://195.133.47.134:$Port/webhook"
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        Write-Log "Request from $($request.RemoteEndPoint.Address) to $($request.Url.AbsolutePath)"
        
        if ($request.HttpMethod -eq "GET" -and $request.Url.AbsolutePath -eq "/") {
            # Health check endpoint
            $response.StatusCode = 200
            $response.StatusDescription = "OK"
            $response.ContentType = "text/plain"
            $responseText = "Webhook server is running on port $Port"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseText)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            
        } elseif ($request.HttpMethod -eq "POST" -and $request.Url.AbsolutePath -eq "/webhook") {
            # Webhook endpoint
            $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
            $body = $reader.ReadToEnd()
            $reader.Close()
            
            Write-Log "Received webhook payload"
            
            # Simple deployment logic
            try {
                Set-Location $RepoPath
                Write-Log "Changed to repository directory"
                
                # Stop PM2 processes
                pm2 stop all 2>$null
                Write-Log "Stopped PM2 processes"
                
                # Pull latest changes
                git pull origin main
                Write-Log "Pulled latest changes from GitHub"
                
                # Install dependencies if needed
                if (Test-Path "package-simple.json") {
                    Copy-Item "package-simple.json" "package.json" -Force
                    npm install --legacy-peer-deps
                    Write-Log "Installed dependencies"
                }
                
                # Start application
                pm2 start glaz-finance-app-v2.js --name "glaz-finance-app"
                pm2 save
                Write-Log "Started application with PM2"
                
                $response.StatusCode = 200
                $response.StatusDescription = "OK"
                $responseText = "Deployment successful"
                
            } catch {
                Write-Log "Deployment error: $($_.Exception.Message)"
                $response.StatusCode = 500
                $response.StatusDescription = "Internal Server Error"
                $responseText = "Deployment failed: $($_.Exception.Message)"
            }
            
            $response.ContentType = "text/plain"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseText)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            
        } else {
            # 404 for other paths
            $response.StatusCode = 404
            $response.StatusDescription = "Not Found"
            $responseText = "Not Found"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseText)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
        }
    }
    
} catch {
    Write-Log "Error: $($_.Exception.Message)"
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
        Write-Log "Webhook server stopped"
    }
}
