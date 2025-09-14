@echo off
echo === Glaz Finance App Installation ===

cd /d C:\glaz-finance-app

echo Checking Node.js...
node --version
if %errorlevel% neq 0 (
    echo Node.js not found! Please install Node.js first.
    echo Download from: https://nodejs.org/en/download/
    pause
    exit /b 1
)

echo Installing PM2 globally...
npm install -g pm2

echo Installing dependencies...
npm install
npm install -g typescript

echo Installing backend dependencies...
cd backend
npm install
cd ..

echo Installing frontend dependencies...
cd frontend
npm install --legacy-peer-deps
cd ..

echo Creating PM2 configuration...
(
echo module.exports = {
echo   apps : [{
echo     name: 'glaz-finance-backend',
echo     script: './backend/index.js',
echo     instances: 1,
echo     autorestart: true,
echo     watch: false,
echo     max_memory_restart: '1G',
echo     env: {
echo       NODE_ENV: 'production',
echo       PORT: 3002,
echo       NODE_SKIP_PLATFORM_CHECK: '1'
echo     }
echo   }]
echo };
) > ecosystem.config.js

echo Stopping existing PM2 processes...
pm2 stop all
pm2 delete all

echo Starting application with PM2...
pm2 start ecosystem.config.js
pm2 save

echo PM2 Status:
pm2 list

echo Port Status:
netstat -an | findstr :3002

echo === Installation Complete ===
echo Application should be available at: http://localhost:3002
echo External access: http://195.133.47.134:3002
pause
