# Fix SSH Server on Windows Server 2012 R2
# Run as Administrator

Write-Host "Fixing SSH Server on Windows Server 2012 R2..." -ForegroundColor Green

# 1. Check if OpenSSH is installed
Write-Host "`n=== Checking OpenSSH Installation ===" -ForegroundColor Yellow
$sshService = Get-Service -Name "sshd" -ErrorAction SilentlyContinue

if (-not $sshService) {
    Write-Host "OpenSSH Server not found. Installing..." -ForegroundColor Red
    
    # Download and install OpenSSH for Windows Server 2012 R2
    $downloadUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v8.6.0.0p1-Beta/OpenSSH-Win64.zip"
    $tempPath = "$env:TEMP\OpenSSH-Win64.zip"
    $extractPath = "C:\Program Files\OpenSSH"
    
    try {
        # Download OpenSSH
        Write-Host "Downloading OpenSSH..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing
        
        # Extract
        Write-Host "Extracting OpenSSH..." -ForegroundColor Yellow
        Expand-Archive -Path $tempPath -DestinationPath $extractPath -Force
        
        # Install
        Write-Host "Installing OpenSSH..." -ForegroundColor Yellow
        Set-Location "$extractPath\OpenSSH-Win64"
        .\install-sshd.ps1
        
        # Clean up
        Remove-Item $tempPath -Force
        Remove-Item "$extractPath\OpenSSH-Win64" -Recurse -Force
        
        Write-Host "OpenSSH installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install OpenSSH: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please install OpenSSH manually or use alternative method." -ForegroundColor Yellow
    }
}

# 2. Check SSH service status
Write-Host "`n=== SSH Service Status ===" -ForegroundColor Yellow
$sshService = Get-Service -Name "sshd" -ErrorAction SilentlyContinue

if ($sshService) {
    Write-Host "SSH Service found: $($sshService.Status)" -ForegroundColor Green
    
    if ($sshService.Status -ne "Running") {
        Write-Host "Starting SSH service..." -ForegroundColor Yellow
        Start-Service sshd
        Set-Service sshd -StartupType Automatic
        Write-Host "SSH service started and set to auto-start!" -ForegroundColor Green
    } else {
        Write-Host "SSH service is already running!" -ForegroundColor Green
    }
} else {
    Write-Host "SSH service not found!" -ForegroundColor Red
}

# 3. Check firewall rules
Write-Host "`n=== Firewall Rules ===" -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -Name "SSH" -ErrorAction SilentlyContinue

if (-not $firewallRule) {
    Write-Host "Creating firewall rule for SSH..." -ForegroundColor Yellow
    try {
        New-NetFirewallRule -Name "SSH" -DisplayName "SSH Server" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        Write-Host "Firewall rule created successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create firewall rule: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "SSH firewall rule already exists: $($firewallRule.Enabled)" -ForegroundColor Green
}

# 4. Check port 22
Write-Host "`n=== Port 22 Status ===" -ForegroundColor Yellow
$port22 = netstat -an | findstr ":22"
if ($port22) {
    Write-Host "Port 22 is listening:" -ForegroundColor Green
    Write-Host $port22 -ForegroundColor White
} else {
    Write-Host "Port 22 is NOT listening!" -ForegroundColor Red
}

# 5. Check user glaz-deploy
Write-Host "`n=== User glaz-deploy ===" -ForegroundColor Yellow
$user = Get-LocalUser -Name "glaz-deploy" -ErrorAction SilentlyContinue
if ($user) {
    Write-Host "User glaz-deploy exists: $($user.Enabled)" -ForegroundColor Green
} else {
    Write-Host "User glaz-deploy does NOT exist!" -ForegroundColor Red
    Write-Host "Creating user glaz-deploy..." -ForegroundColor Yellow
    
    try {
        $password = ConvertTo-SecureString "GlazDeploy2024!@#$%^&*()" -AsPlainText -Force
        New-LocalUser -Name "glaz-deploy" -Password $password -FullName "Glaz Deploy User" -Description "User for deployment"
        
        # Add to Administrators group
        $adminGroup = Get-LocalGroup | Where-Object {$_.Name -like "*Admin*"}
        if ($adminGroup) {
            Add-LocalGroupMember -Group $adminGroup.Name -Member "glaz-deploy"
            Write-Host "User glaz-deploy created and added to Administrators!" -ForegroundColor Green
        } else {
            Write-Host "User glaz-deploy created but could not add to Administrators group!" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to create user: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 6. Test SSH connection
Write-Host "`n=== SSH Connection Test ===" -ForegroundColor Yellow
Write-Host "Testing SSH connection to localhost..." -ForegroundColor White

try {
    $result = ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no glaz-deploy@localhost "echo 'SSH test successful'"
    if ($result -like "*SSH test successful*") {
        Write-Host "SSH connection test: SUCCESS!" -ForegroundColor Green
    } else {
        Write-Host "SSH connection test: FAILED!" -ForegroundColor Red
    }
}
catch {
    Write-Host "SSH connection test: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# 7. Final status
Write-Host "`n=== Final Status ===" -ForegroundColor Cyan
Write-Host "SSH Service: $((Get-Service sshd).Status)" -ForegroundColor White
Write-Host "Port 22: $(if (netstat -an | findstr ':22') { 'LISTENING' } else { 'NOT LISTENING' })" -ForegroundColor White
Write-Host "Firewall Rule: $(if (Get-NetFirewallRule -Name 'SSH' -ErrorAction SilentlyContinue) { 'EXISTS' } else { 'MISSING' })" -ForegroundColor White
Write-Host "User glaz-deploy: $(if (Get-LocalUser -Name 'glaz-deploy' -ErrorAction SilentlyContinue) { 'EXISTS' } else { 'MISSING' })" -ForegroundColor White

Write-Host "`nSSH setup completed!" -ForegroundColor Green
Write-Host "You can now test GitHub Actions deployment." -ForegroundColor Yellow
