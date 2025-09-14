# Setup Auto Update - creates scheduled task for automatic updates
Write-Host "=== SETTING UP AUTO UPDATE ===" -ForegroundColor Green

$RepoPath = "C:\glaz-finance-app"
$ScriptPath = "$RepoPath\scripts\auto-update.ps1"
$TaskName = "GlazFinanceAutoUpdate"

Write-Host "Repository: $RepoPath" -ForegroundColor Cyan
Write-Host "Script: $ScriptPath" -ForegroundColor Cyan
Write-Host "Task: $TaskName" -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Running as Administrator" -ForegroundColor Green

# Remove existing task if it exists
Write-Host "`n1. REMOVING EXISTING TASK:" -ForegroundColor Yellow
try {
    schtasks /Delete /TN $TaskName /F 2>$null
    Write-Host "✓ Existing task removed" -ForegroundColor Green
} catch {
    Write-Host "No existing task to remove" -ForegroundColor Cyan
}

# Create new scheduled task
Write-Host "`n2. CREATING SCHEDULED TASK:" -ForegroundColor Yellow
$TaskCommand = "powershell.exe"
$TaskArguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

try {
    # Create task that runs every 5 minutes
    schtasks /Create /TN $TaskName /TR "$TaskCommand $TaskArguments" /SC Minute /MO 5 /RU SYSTEM /F
    
    Write-Host "✓ Scheduled task created successfully" -ForegroundColor Green
    Write-Host "Task will run every 5 minutes" -ForegroundColor Cyan
    
    # Test the task
    Write-Host "`n3. TESTING TASK:" -ForegroundColor Yellow
    schtasks /Run /TN $TaskName
    
    Write-Host "✓ Task executed successfully" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Show task information
Write-Host "`n4. TASK INFORMATION:" -ForegroundColor Yellow
schtasks /Query /TN $TaskName /FO List | Select-String -Pattern "TaskName|Status|Next Run Time|Last Run Time"

Write-Host "`n5. MANUAL COMMANDS:" -ForegroundColor Yellow
Write-Host "To run update manually:" -ForegroundColor Cyan
Write-Host "  cd $RepoPath" -ForegroundColor White
Write-Host "  powershell -ExecutionPolicy Bypass -File scripts\auto-update.ps1" -ForegroundColor White

Write-Host "`nTo check task status:" -ForegroundColor Cyan
Write-Host "  schtasks /Query /TN $TaskName" -ForegroundColor White

Write-Host "`nTo remove task:" -ForegroundColor Cyan
Write-Host "  schtasks /Delete /TN $TaskName /F" -ForegroundColor White

Write-Host "`n=== AUTO UPDATE SETUP COMPLETE ===" -ForegroundColor Green
Write-Host "Your application will now auto-update every 5 minutes!" -ForegroundColor Cyan
