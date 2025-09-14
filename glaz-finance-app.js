const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({ 
    message: 'Glaz Finance App - Full Version!',
    timestamp: new Date().toISOString(),
    port: PORT,
    version: '1.0.0',
    status: 'Running'
  });
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    port: PORT
  });
});

app.get('/api/accounts', (req, res) => {
  res.json({
    accounts: [
      { id: 1, name: 'Основной счет', balance: 100000, currency: 'RUB' },
      { id: 2, name: 'Инвестиционный счет', balance: 50000, currency: 'RUB' }
    ]
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('Glaz Finance App running on port ' + PORT);
  console.log('Local: http://localhost:' + PORT);
  console.log('External: http://195.133.47.134:' + PORT);
  console.log('API: http://195.133.47.134:' + PORT + '/api/accounts');
});
