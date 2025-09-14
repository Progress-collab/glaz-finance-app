# Quick SSH Fix for Windows Server 2012 R2
# Run as Administrator

Write-Host "Quick SSH Fix..." -ForegroundColor Green

# 1. Start SSH service
Write-Host "Starting SSH service..." -ForegroundColor Yellow
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service sshd -StartupType Automatic -ErrorAction SilentlyContinue

# 2. Create firewall rule
Write-Host "Creating firewall rule..." -ForegroundColor Yellow
New-NetFirewallRule -Name "SSH" -DisplayName "SSH Server" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue

# 3. Check status
Write-Host "`n=== Status ===" -ForegroundColor Cyan
Write-Host "SSH Service: $((Get-Service sshd).Status)" -ForegroundColor White
Write-Host "Port 22: $(if (netstat -an | findstr ':22') { 'LISTENING' } else { 'NOT LISTENING' })" -ForegroundColor White

Write-Host "`nSSH fix completed!" -ForegroundColor Green
