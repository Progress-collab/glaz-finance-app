@echo off
echo Starting Port 3000 Server...

cd /d C:\glaz-finance-app

echo Installing Express...
npm install express --save

echo Creating server file...
(
echo const express = require^('express'^);
echo const app = express^(^);
echo const PORT = 3000;
echo.
echo app.get^('/', ^(req, res^) =^> {
echo   res.json^({ 
echo     message: 'Port 3000 Application Restored!',
echo     timestamp: new Date^(^).toISOString^(^),
echo     port: PORT
echo   }^);
echo }^);
echo.
echo app.get^('/health', ^(req, res^) =^> {
echo   res.json^({ 
echo     status: 'OK',
echo     timestamp: new Date^(^).toISOString^(^),
echo     port: PORT
echo   }^);
echo }^);
echo.
echo app.listen^(PORT, '0.0.0.0', ^(^) =^> {
echo   console.log^(`Port 3000 server running on ${PORT}`^);
echo }^);
) > port3000-server.js

echo Starting with PM2...
pm2 stop all
pm2 delete all
pm2 start port3000-server.js --name "port3000-app"
pm2 save

echo Checking status...
pm2 list

echo Checking port...
netstat -an | findstr :3000

echo Done!
