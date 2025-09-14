# Setup PostgreSQL and Redis without Docker
# Run as Administrator

Write-Host "Setting up PostgreSQL and Redis services..." -ForegroundColor Green

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit 1
}

# Install PostgreSQL
Write-Host "Installing PostgreSQL..." -ForegroundColor Yellow
try {
    choco install postgresql -y
    
    # Set up PostgreSQL
    $env:PATH += ";C:\Program Files\PostgreSQL\15\bin"
    
    # Create database and user
    Write-Host "Setting up PostgreSQL database..." -ForegroundColor Yellow
    
    # Set password for postgres user
    $postgresPassword = "postgres_password_2024"
    
    # Create database and user
    & "C:\Program Files\PostgreSQL\15\bin\createdb.exe" -U postgres glaz_finance
    & "C:\Program Files\PostgreSQL\15\bin\createuser.exe" -U postgres -s glaz_user
    
    # Set password for glaz_user
    & "C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -c "ALTER USER glaz_user PASSWORD 'glaz_password_2024';"
    
    Write-Host "PostgreSQL installed and configured successfully" -ForegroundColor Green
} catch {
    Write-Host "Error installing PostgreSQL: $($_.Exception.Message)" -ForegroundColor Red
}

# Install Redis
Write-Host "Installing Redis..." -ForegroundColor Yellow
try {
    choco install redis-64 -y
    
    # Start Redis service
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

# Create logs directory
Write-Host "Creating logs directory..." -ForegroundColor Yellow
$logsDir = "C:\glaz-finance-app\logs"
if (!(Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force
    Write-Host "Logs directory created: $logsDir" -ForegroundColor Green
}

Write-Host "`nServices setup completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Clone repository: git clone https://github.com/Progress-collab/glaz-finance-app.git C:\glaz-finance-app" -ForegroundColor White
Write-Host "2. Install dependencies: cd C:\glaz-finance-app && npm install" -ForegroundColor White
Write-Host "3. Build application: npm run build" -ForegroundColor White
Write-Host "4. Start with PM2: pm2 start ecosystem.config.js" -ForegroundColor White
Write-Host "5. Save PM2 config: pm2 save && pm2 startup" -ForegroundColor White

Write-Host "`nVerification commands:" -ForegroundColor Yellow
Write-Host "Get-Service postgresql*" -ForegroundColor White
Write-Host "Get-Service redis*" -ForegroundColor White
Write-Host "pm2 status" -ForegroundColor White
