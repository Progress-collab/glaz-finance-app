# Setup SQLite Deployment (Simplified)
# Run as Administrator

Write-Host "Setting up SQLite deployment for Glaz Finance App..." -ForegroundColor Green

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit 1
}

# Create user with very strong password
Write-Host "Creating user with very strong password..." -ForegroundColor Yellow
$deployUser = "glaz-deploy"
$deployPassword = "GlazDeploy2024!@#$%^&*()"

try {
    # Remove existing user if exists
    Remove-LocalUser -Name $deployUser -ErrorAction SilentlyContinue
    
    # Create new user with very strong password
    New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User" -Description "User for deploying Glaz Finance App"
    
    # Find correct administrators group name
    $adminGroup = Get-LocalGroup | Where-Object {$_.Name -like "*admin*"} | Select-Object -First 1
    if ($adminGroup) {
        Add-LocalGroupMember -Group $adminGroup.Name -Member $deployUser
        Write-Host "User added to group: $($adminGroup.Name)" -ForegroundColor Green
    }
    
    Write-Host "User $deployUser created successfully" -ForegroundColor Green
} catch {
    Write-Host "Error creating user: $($_.Exception.Message)" -ForegroundColor Red
}

# Start Redis service (Memurai)
Write-Host "Starting Redis service..." -ForegroundColor Yellow
try {
    $redisService = Get-Service | Where-Object {$_.Name -like "*redis*" -or $_.Name -like "*memurai*"} | Select-Object -First 1
    if ($redisService) {
        Start-Service $redisService.Name
        Write-Host "Redis service started: $($redisService.Name)" -ForegroundColor Green
    } else {
        Write-Host "Redis service not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error starting Redis service: $($_.Exception.Message)" -ForegroundColor Red
}

# Install PM2 with platform check bypass
Write-Host "Installing PM2 with platform check bypass..." -ForegroundColor Yellow
try {
    $env:NODE_SKIP_PLATFORM_CHECK = "1"
    npm install -g pm2
    Write-Host "PM2 installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing PM2: $($_.Exception.Message)" -ForegroundColor Red
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

# Create logs directory
$logsDir = "$appDir\logs"
if (!(Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force
    Write-Host "Logs directory created: $logsDir" -ForegroundColor Green
}

# Create SQLite configuration
Write-Host "Creating SQLite configuration..." -ForegroundColor Yellow
$configContent = @"
# Glaz Finance App Configuration (SQLite)
SERVER_HOST=YOUR_SERVER_IP
SERVER_USERNAME=$deployUser
SERVER_PASSWORD=$deployPassword
SERVER_PORT=22

# Application settings
APP_PORT=3001
API_PORT=3002
DB_TYPE=sqlite
DB_PATH=C:\glaz-finance-app\database\glaz_finance.db

# Redis settings
REDIS_URL=redis://localhost:6379

# API keys (fill manually)
OPENWEATHER_API_KEY=
GOOGLE_DRIVE_API_KEY=
GOOGLE_SHEETS_API_KEY=
"@

$configContent | Out-File -FilePath "$appDir\config.env" -Encoding UTF8

Write-Host "`nSQLite deployment setup completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Clone repository: git clone https://github.com/Progress-collab/glaz-finance-app.git C:\glaz-finance-app" -ForegroundColor White
Write-Host "2. Install dependencies: cd C:\glaz-finance-app && npm install" -ForegroundColor White
Write-Host "3. Build application: npm run build" -ForegroundColor White
Write-Host "4. Start with PM2: pm2 start ecosystem.config.js" -ForegroundColor White

Write-Host "`nUpdated GitHub Secrets data:" -ForegroundColor Cyan
Write-Host "SERVER_USERNAME: $deployUser" -ForegroundColor White
Write-Host "SERVER_PASSWORD: $deployPassword" -ForegroundColor White
Write-Host "SERVER_PORT: 22" -ForegroundColor White

Write-Host "`nVerification commands:" -ForegroundColor Yellow
Write-Host "Get-LocalUser -Name $deployUser" -ForegroundColor White
Write-Host "Get-Service | Where-Object {\$_.Name -like '*redis*' -or \$_.Name -like '*memurai*'}" -ForegroundColor White
Write-Host "pm2 --version" -ForegroundColor White
