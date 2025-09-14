# Simple Server Starter
Write-Host "=== Starting Simple Server ===" -ForegroundColor Green

Set-Location "C:\glaz-finance-app"

# Create simple server
Write-Host "Creating simple server..." -ForegroundColor Yellow
@"
const express = require('express');
const app = express();
const PORT = 3002;

app.get('/', (req, res) => {
  res.json({ 
    message: 'Glaz Finance App is running!',
    timestamp: new Date().toISOString(),
    port: PORT
  });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    timestamp: new Date().toISOString(),
    port: PORT
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Local: http://localhost:${PORT}`);
  console.log(`External: http://195.133.47.134:${PORT}`);
});
"@ | Out-File -FilePath "simple-server.js" -Encoding UTF8

# Install Express if not exists
Write-Host "Installing Express..." -ForegroundColor Yellow
npm install express --save

# Start server
Write-Host "Starting server..." -ForegroundColor Yellow
node simple-server.js
