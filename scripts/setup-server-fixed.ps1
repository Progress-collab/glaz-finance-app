# Glaz Finance App - Windows Server 2012 R2 Setup Script
# Run as Administrator

Write-Host "Setting up Windows Server 2012 R2 for Glaz Finance App..." -ForegroundColor Green

# Check if running as administrator
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

# Install required packages
Write-Host "Installing required packages..." -ForegroundColor Yellow
choco install -y git docker-desktop nodejs postgresql

# Configure Docker
Write-Host "Configuring Docker..." -ForegroundColor Yellow
# Docker Desktop should be running
Start-Service docker

# Create deploy user
Write-Host "Creating deploy user..." -ForegroundColor Yellow
$deployUser = "glaz-deploy"
$deployPassword = "GlazDeploy2024!"

try {
    New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User" -Description "User for deploying Glaz Finance App"
    Add-LocalGroupMember -Group "Administrators" -Member $deployUser
    Write-Host "User $deployUser created with password $deployPassword" -ForegroundColor Green
} catch {
    Write-Host "User already exists or creation error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Configure SSH server (OpenSSH)
Write-Host "Configuring SSH server..." -ForegroundColor Yellow
# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Start and configure SSH server
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Configure firewall for SSH
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Create application directory
Write-Host "Creating application directory..." -ForegroundColor Yellow
$appDir = "C:\glaz-finance-app"
if (!(Test-Path $appDir)) {
    New-Item -ItemType Directory -Path $appDir -Force
    Write-Host "Directory $appDir created" -ForegroundColor Green
}

# Configure permissions
icacls $appDir /grant "$deployUser:(OI)(CI)F" /T

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

Write-Host "Setup completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Fill API keys in file $appDir\config.env" -ForegroundColor White
Write-Host "2. Configure GitHub Secrets with server data" -ForegroundColor White
Write-Host "3. Run application with: docker-compose up -d" -ForegroundColor White
Write-Host "4. Open browser at: http://YOUR_SERVER_IP:3001" -ForegroundColor White

Write-Host "`nGitHub Secrets data:" -ForegroundColor Cyan
Write-Host "SERVER_HOST: YOUR_SERVER_IP" -ForegroundColor White
Write-Host "SERVER_USERNAME: $deployUser" -ForegroundColor White
Write-Host "SERVER_PASSWORD: $deployPassword" -ForegroundColor White
Write-Host "SERVER_PORT: 22" -ForegroundColor White
