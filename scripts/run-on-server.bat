@echo off
echo === RUNNING ON SERVER DIRECTLY ===
echo This script runs directly on Windows Server
echo.

cd /d C:\glaz-finance-app

echo 1. Setting environment variables...
set NODE_SKIP_PLATFORM_CHECK=1

echo 2. Checking current status...
echo Current directory: %CD%
echo.

echo 3. Git status:
git status
echo.

echo 4. Current files:
dir glaz-finance-app*.js
echo.

echo 5. Public directory:
if exist "public" (
    echo public directory exists
    dir public
) else (
    echo public directory NOT FOUND!
)
echo.

echo 6. Stopping all processes...
pm2 stop all
pm2 delete all
taskkill /F /IM node.exe 2>nul

echo 7. Force git pull...
git stash
git fetch origin
git reset --hard origin/main
git pull origin main

echo 8. Checking files after sync...
dir glaz-finance-app*.js
if exist "public" (
    echo public directory now exists
    dir public
) else (
    echo public directory STILL NOT FOUND!
)

echo 9. Installing dependencies...
npm install --legacy-peer-deps

echo 10. Starting application...
if exist "glaz-finance-app-v2.js" (
    echo Starting glaz-finance-app-v2.js...
    pm2 start glaz-finance-app-v2.js --name "glaz-finance-v2"
    timeout /t 5 /nobreak >nul
    
    echo 11. Testing...
    powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:3000' -TimeoutSec 5; Write-Host 'SUCCESS: Status' $r.StatusCode; Write-Host 'Content-Type:' $r.Headers.'Content-Type' } catch { Write-Host 'FAILED:' $_.Exception.Message }"
) else (
    echo ERROR: glaz-finance-app-v2.js NOT FOUND!
)

echo.
echo === COMPLETE ===
pause
