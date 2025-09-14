# Setup PM2 Deployment (Alternative to Docker)
# Run as Administrator

Write-Host "Setting up PM2 deployment for Glaz Finance App..." -ForegroundColor Green

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit 1
}

# Fix user creation
Write-Host "Fixing user creation..." -ForegroundColor Yellow
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

# Install PostgreSQL
Write-Host "Installing PostgreSQL..." -ForegroundColor Yellow
try {
    choco install postgresql -y
    
    # Set up PostgreSQL
    $env:PATH += ";C:\Program Files\PostgreSQL\15\bin"
    
    Write-Host "PostgreSQL installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing PostgreSQL: $($_.Exception.Message)" -ForegroundColor Red
}

# Install Redis
Write-Host "Installing Redis..." -ForegroundColor Yellow
try {
    choco install redis-64 -y
    Start-Service redis
    Write-Host "Redis installed and started successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing Redis: $($_.Exception.Message)" -ForegroundColor Red
}

# Install PM2 globally
Write-Host "Installing PM2..." -ForegroundColor Yellow
try {
    npm install -g pm2
    Write-Host "PM2 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing PM2: $($_.Exception.Message)" -ForegroundColor Red
}

# Restart SSH service
Write-Host "Restarting SSH service..." -ForegroundColor Yellow
try {
    Restart-Service sshd
    Write-Host "SSH service restarted successfully" -ForegroundColor Green
} catch {
    Write-Host "Error restarting SSH service: $($_.Exception.Message)" -ForegroundColor Red
}

# Create logs directory
Write-Host "Creating logs directory..." -ForegroundColor Yellow
$logsDir = "C:\glaz-finance-app\logs"
if (!(Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force
    Write-Host "Logs directory created: $logsDir" -ForegroundColor Green
}

# Set up directory permissions
$appDir = "C:\glaz-finance-app"
if (Test-Path $appDir) {
    icacls $appDir /grant "${deployUser}:(OI)(CI)F" /T
    Write-Host "Directory permissions updated" -ForegroundColor Green
}

Write-Host "`nPM2 deployment setup completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Clone repository: git clone https://github.com/Progress-collab/glaz-finance-app.git C:\glaz-finance-app" -ForegroundColor White
Write-Host "2. Install dependencies: cd C:\glaz-finance-app && npm install" -ForegroundColor White
Write-Host "3. Build application: npm run build" -ForegroundColor White
Write-Host "4. Start with PM2: pm2 start ecosystem.config.js" -ForegroundColor White
Write-Host "5. Save PM2 config: pm2 save && pm2 startup" -ForegroundColor White

Write-Host "`nUpdated GitHub Secrets data:" -ForegroundColor Cyan
Write-Host "SERVER_USERNAME: $deployUser" -ForegroundColor White
Write-Host "SERVER_PASSWORD: $deployPassword" -ForegroundColor White
Write-Host "SERVER_PORT: 22" -ForegroundColor White

Write-Host "`nVerification commands:" -ForegroundColor Yellow
Write-Host "Get-Service sshd" -ForegroundColor White
Write-Host "Get-Service postgresql*" -ForegroundColor White
Write-Host "Get-Service redis*" -ForegroundColor White
Write-Host "pm2 --version" -ForegroundColor White
