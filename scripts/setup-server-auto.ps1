# Complete Server Setup Script with Automatic Docker Installation
# Run as Administrator

Write-Host "Complete setup for Glaz Finance App with automatic Docker installation..." -ForegroundColor Green

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit 1
}

# Install Chocolatey if not installed
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install basic packages first
Write-Host "Installing basic packages..." -ForegroundColor Yellow
choco install -y git nodejs

# Create deploy user with stronger password
Write-Host "Creating deploy user..." -ForegroundColor Yellow
$deployUser = "glaz-deploy"
$deployPassword = "GlazDeploy2024!@#"

try {
    # Remove existing user if exists
    Remove-LocalUser -Name $deployUser -ErrorAction SilentlyContinue
    
    # Create new user
    New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User" -Description "User for deploying Glaz Finance App"
    
    # Add to administrators group
    Add-LocalGroupMember -Group "Администраторы" -Member $deployUser
    
    Write-Host "User $deployUser created successfully" -ForegroundColor Green
} catch {
    Write-Host "Error creating user: $($_.Exception.Message)" -ForegroundColor Red
}

# Create application directory
Write-Host "Creating application directory..." -ForegroundColor Yellow
$appDir = "C:\glaz-finance-app"
if (!(Test-Path $appDir)) {
    New-Item -ItemType Directory -Path $appDir -Force
    Write-Host "Directory $appDir created" -ForegroundColor Green
}

# Set up directory permissions
icacls $appDir /grant "${deployUser}:(OI)(CI)F" /T

# Install OpenSSH Server
Write-Host "Installing OpenSSH Server..." -ForegroundColor Yellow
try {
    # Download and install OpenSSH Server
    $sshUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.2.0p1-Beta/OpenSSH-Win64.zip"
    $sshZip = "$env:TEMP\OpenSSH-Win64.zip"
    
    Invoke-WebRequest -Uri $sshUrl -OutFile $sshZip -UseBasicParsing
    Expand-Archive -Path $sshZip -DestinationPath $env:TEMP -Force
    
    Set-Location "$env:TEMP\OpenSSH-Win64"
    .\install-sshd.ps1
    
    Set-Service -Name sshd -StartupType 'Automatic'
    Start-Service sshd
    
    New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    
    Write-Host "OpenSSH Server installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing OpenSSH: $($_.Exception.Message)" -ForegroundColor Red
}

# Install Docker Desktop automatically
Write-Host "Installing Docker Desktop automatically..." -ForegroundColor Yellow

# Method 1: Try Chocolatey with force
try {
    choco install docker-desktop -y --force --ignore-checksums
    Write-Host "Docker Desktop installed via Chocolatey" -ForegroundColor Green
} catch {
    Write-Host "Chocolatey Docker installation failed, trying direct download..." -ForegroundColor Yellow
    
    # Method 2: Direct download
    try {
        $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
        
        Write-Host "Downloading Docker Desktop..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
        
        Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
        Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet", "--accept-license" -Wait
        
        Write-Host "Docker Desktop installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Direct download failed, trying alternative method..." -ForegroundColor Yellow
        
        # Method 3: Alternative URL
        try {
            $altDockerUrl = "https://download.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
            Invoke-WebRequest -Uri $altDockerUrl -OutFile $dockerInstaller -UseBasicParsing
            Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet", "--accept-license" -Wait
            Write-Host "Docker Desktop installed via alternative URL" -ForegroundColor Green
        } catch {
            Write-Host "All Docker installation methods failed" -ForegroundColor Red
            Write-Host "Please install Docker Desktop manually after script completion" -ForegroundColor Yellow
        }
    }
}

# Create configuration file
Write-Host "Creating configuration file..." -ForegroundColor Yellow
$configContent = @"
# Glaz Finance App Configuration
SERVER_HOST=YOUR_SERVER_IP
SERVER_USERNAME=$deployUser
SERVER_PASSWORD=$deployPassword
SERVER_PORT=22

# Application settings
APP_PORT=3001
API_PORT=3002
DB_PORT=5432
REDIS_PORT=6379

# Database settings
DB_NAME=glaz_finance
DB_USER=glaz_user
DB_PASSWORD=glaz_password_2024

# API keys (fill manually)
OPENWEATHER_API_KEY=
GOOGLE_DRIVE_API_KEY=
GOOGLE_SHEETS_API_KEY=
"@

$configContent | Out-File -FilePath "$appDir\config.env" -Encoding UTF8

Write-Host "`nSetup completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart the computer to complete Docker installation" -ForegroundColor White
Write-Host "2. Clone repository: git clone https://github.com/Progress-collab/glaz-finance-app.git C:\glaz-finance-app" -ForegroundColor White
Write-Host "3. Run: docker-compose up -d" -ForegroundColor White
Write-Host "4. Open browser at: http://YOUR_SERVER_IP:3001" -ForegroundColor White

Write-Host "`nGitHub Secrets data:" -ForegroundColor Cyan
Write-Host "SERVER_USERNAME: $deployUser" -ForegroundColor White
Write-Host "SERVER_PASSWORD: $deployPassword" -ForegroundColor White
Write-Host "SERVER_PORT: 22" -ForegroundColor White

Write-Host "`nVerification commands:" -ForegroundColor Yellow
Write-Host "git --version" -ForegroundColor White
Write-Host "node --version" -ForegroundColor White
Write-Host "docker --version" -ForegroundColor White
Write-Host "Get-Service sshd" -ForegroundColor White
