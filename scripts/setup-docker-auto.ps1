# Automatic Docker Desktop Installation Script
# Run as Administrator

Write-Host "Installing Docker Desktop automatically..." -ForegroundColor Green

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    exit 1
}

# Method 1: Try Chocolatey with different approach
Write-Host "Attempting to install Docker Desktop via Chocolatey..." -ForegroundColor Yellow

try {
    # Update Chocolatey
    choco upgrade chocolatey -y
    
    # Try installing Docker Desktop with different parameters
    choco install docker-desktop -y --force --ignore-checksums
    
    Write-Host "Docker Desktop installed successfully via Chocolatey" -ForegroundColor Green
} catch {
    Write-Host "Chocolatey installation failed, trying alternative method..." -ForegroundColor Yellow
    
    # Method 2: Direct download and installation
    Write-Host "Downloading Docker Desktop directly..." -ForegroundColor Yellow
    
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
    
    try {
        # Download Docker Desktop
        Write-Host "Downloading Docker Desktop installer..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
        
        # Install Docker Desktop silently
        Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
        Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet", "--accept-license" -Wait
        
        Write-Host "Docker Desktop installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Direct download failed, trying alternative URL..." -ForegroundColor Yellow
        
        # Method 3: Alternative download URL
        $altDockerUrl = "https://download.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
        
        try {
            Write-Host "Trying alternative download URL..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri $altDockerUrl -OutFile $dockerInstaller -UseBasicParsing
            
            Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet", "--accept-license" -Wait
            
            Write-Host "Docker Desktop installed successfully via alternative URL" -ForegroundColor Green
        } catch {
            Write-Host "All automatic installation methods failed" -ForegroundColor Red
            Write-Host "Please install Docker Desktop manually:" -ForegroundColor Yellow
            Write-Host "1. Go to https://www.docker.com/products/docker-desktop/" -ForegroundColor White
            Write-Host "2. Download Docker Desktop for Windows" -ForegroundColor White
            Write-Host "3. Run the installer" -ForegroundColor White
        }
    }
}

# Method 4: Try winget (Windows Package Manager)
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Trying winget installation..." -ForegroundColor Yellow
    
    try {
        # Check if winget is available
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install Docker.DockerDesktop
            Write-Host "Docker Desktop installed via winget" -ForegroundColor Green
        } else {
            Write-Host "winget is not available on this system" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "winget installation failed" -ForegroundColor Yellow
    }
}

# Verify installation
Write-Host "Verifying Docker installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Docker is installed successfully!" -ForegroundColor Green
    docker --version
} else {
    Write-Host "Docker installation verification failed" -ForegroundColor Red
    Write-Host "You may need to restart the computer and try again" -ForegroundColor Yellow
}

Write-Host "Docker Desktop installation script completed" -ForegroundColor Green
