# Quick Setup Script for Glaz Finance App
# Run as Administrator

Write-Host "Quick setup for Glaz Finance App..." -ForegroundColor Green

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit 1
}

# Install Chocolatey
Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install packages
Write-Host "Installing packages..." -ForegroundColor Yellow
choco install -y git docker-desktop nodejs

# Create directory
$appDir = "C:\glaz-finance-app"
if (!(Test-Path $appDir)) {
    New-Item -ItemType Directory -Path $appDir -Force
    Write-Host "Directory created: $appDir" -ForegroundColor Green
}

# Create deploy user
$deployUser = "glaz-deploy"
$deployPassword = "GlazDeploy2024!"

try {
    New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User"
    Add-LocalGroupMember -Group "Administrators" -Member $deployUser
    Write-Host "User created: $deployUser" -ForegroundColor Green
} catch {
    Write-Host "User already exists" -ForegroundColor Yellow
}

# Setup SSH
Write-Host "Setting up SSH..." -ForegroundColor Yellow
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

Write-Host "Quick setup completed!" -ForegroundColor Green
Write-Host "Next: Clone repository and run docker-compose up -d" -ForegroundColor Yellow
Write-Host "GitHub Secrets:" -ForegroundColor Cyan
Write-Host "SERVER_USERNAME: $deployUser" -ForegroundColor White
Write-Host "SERVER_PASSWORD: $deployPassword" -ForegroundColor White
Write-Host "SERVER_PORT: 22" -ForegroundColor White
