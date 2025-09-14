# Fix Current Issues Script
# Run as Administrator

Write-Host "Fixing current setup issues..." -ForegroundColor Green

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit 1
}

# Fix 1: Create user with stronger password
Write-Host "Creating user with stronger password..." -ForegroundColor Yellow
$deployUser = "glaz-deploy"
$deployPassword = "GlazDeploy2024!@#$%"

try {
    # Remove existing user if exists
    Remove-LocalUser -Name $deployUser -ErrorAction SilentlyContinue
    
    # Create new user with stronger password
    New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User" -Description "User for deploying Glaz Finance App"
    
    # Add to administrators group (English name)
    Add-LocalGroupMember -Group "Administrators" -Member $deployUser
    
    Write-Host "User $deployUser created successfully" -ForegroundColor Green
} catch {
    Write-Host "Error creating user: $($_.Exception.Message)" -ForegroundColor Red
}

# Fix 2: Restart SSH service
Write-Host "Restarting SSH service..." -ForegroundColor Yellow
try {
    Restart-Service sshd
    Write-Host "SSH service restarted successfully" -ForegroundColor Green
} catch {
    Write-Host "Error restarting SSH service: $($_.Exception.Message)" -ForegroundColor Red
}

# Fix 3: Install PM2 for alternative deployment
Write-Host "Installing PM2 for alternative deployment..." -ForegroundColor Yellow
try {
    npm install -g pm2
    Write-Host "PM2 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing PM2: $($_.Exception.Message)" -ForegroundColor Red
}

# Fix 4: Install PostgreSQL
Write-Host "Installing PostgreSQL..." -ForegroundColor Yellow
try {
    choco install postgresql -y
    Write-Host "PostgreSQL installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing PostgreSQL: $($_.Exception.Message)" -ForegroundColor Red
}

# Fix 5: Install Redis
Write-Host "Installing Redis..." -ForegroundColor Yellow
try {
    choco install redis-64 -y
    Start-Service redis
    Write-Host "Redis installed and started successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing Redis: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nCurrent issues fixed!" -ForegroundColor Green
Write-Host "Updated GitHub Secrets data:" -ForegroundColor Cyan
Write-Host "SERVER_USERNAME: $deployUser" -ForegroundColor White
Write-Host "SERVER_PASSWORD: $deployPassword" -ForegroundColor White
Write-Host "SERVER_PORT: 22" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Clone repository: git clone https://github.com/Progress-collab/glaz-finance-app.git C:\glaz-finance-app" -ForegroundColor White
Write-Host "2. Install dependencies: cd C:\glaz-finance-app && npm install" -ForegroundColor White
Write-Host "3. Build application: npm run build" -ForegroundColor White
Write-Host "4. Start with PM2: pm2 start ecosystem.config.js" -ForegroundColor White

Write-Host "`nVerification commands:" -ForegroundColor Yellow
Write-Host "Get-Service sshd" -ForegroundColor White
Write-Host "Get-LocalUser -Name $deployUser" -ForegroundColor White
Write-Host "pm2 --version" -ForegroundColor White
