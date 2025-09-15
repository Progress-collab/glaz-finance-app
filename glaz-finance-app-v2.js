const express = require('express');
const cors = require('cors');
const path = require('path');
const CurrencyService = require('./currency-service');
const app = express();
const PORT = 3000;

// Инициализация сервиса валют
const currencyService = new CurrencyService();

// In-memory storage (временное решение)
let accounts = [
  { id: 1, name: 'Основной счет', balance: 100000, currency: 'RUB', type: 'checking', description: 'Основной расчетный счет' },
  { id: 2, name: 'Инвестиционный счет', balance: 50000, currency: 'RUB', type: 'investment', description: 'Счет для инвестиций' }
];
let nextId = 3;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Serve HTML page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API Routes
app.get('/api/accounts', (req, res) => {
  res.json({ accounts });
});

app.get('/api/accounts/total', async (req, res) => {
  try {
    const { currency = 'RUB' } = req.query;
    const rates = await currencyService.getExchangeRates();
    
    let totalBalance = 0;
    
    accounts.forEach(account => {
      const convertedBalance = currencyService.convertAmount(
        account.balance,
        account.currency,
        currency.toUpperCase(),
        rates
      );
      totalBalance += convertedBalance;
    });
    
    res.json({
      totalBalance: Math.round(totalBalance * 100) / 100,
      currency: currency.toUpperCase(),
      accountsCount: accounts.length,
      lastUpdated: rates.lastUpdated
    });
  } catch (error) {
    console.error('Error calculating total balance:', error);
    res.status(500).json({ error: 'Failed to calculate total balance' });
  }
});

app.get('/api/accounts/:id', (req, res) => {
  const account = accounts.find(acc => acc.id === parseInt(req.params.id));
  if (!account) {
    return res.status(404).json({ error: 'Account not found' });
  }
  res.json({ account });
});

app.post('/api/accounts', (req, res) => {
  const { name, balance, currency, type, description } = req.body;
  
  if (!name || balance === undefined || !currency) {
    return res.status(400).json({ error: 'Name, balance and currency are required' });
  }

  const newAccount = {
    id: nextId++,
    name,
    balance: parseFloat(balance),
    currency,
    type: type || 'checking',
    description: description || ''
  };

  accounts.push(newAccount);
  res.status(201).json({ account: newAccount });
});

app.put('/api/accounts/:id', (req, res) => {
  const accountIndex = accounts.findIndex(acc => acc.id === parseInt(req.params.id));
  
  if (accountIndex === -1) {
    return res.status(404).json({ error: 'Account not found' });
  }

  const { name, balance, currency, type, description } = req.body;
  
  accounts[accountIndex] = {
    ...accounts[accountIndex],
    name: name || accounts[accountIndex].name,
    balance: balance !== undefined ? parseFloat(balance) : accounts[accountIndex].balance,
    currency: currency || accounts[accountIndex].currency,
    type: type || accounts[accountIndex].type,
    description: description !== undefined ? description : accounts[accountIndex].description
  };

  res.json({ account: accounts[accountIndex] });
});

app.delete('/api/accounts/:id', (req, res) => {
  const accountIndex = accounts.findIndex(acc => acc.id === parseInt(req.params.id));
  
  if (accountIndex === -1) {
    return res.status(404).json({ error: 'Account not found' });
  }

  const deletedAccount = accounts.splice(accountIndex, 1)[0];
  res.json({ message: 'Account deleted', account: deletedAccount });
});

// Currency API endpoints
app.get('/api/currencies', async (req, res) => {
  try {
    const rates = await currencyService.getExchangeRates();
    const availableCurrencies = currencyService.getAvailableCurrencies(rates);
    
    res.json({
      rates,
      availableCurrencies,
      lastUpdated: rates.lastUpdated
    });
  } catch (error) {
    console.error('Error fetching currencies:', error);
    res.status(500).json({ error: 'Failed to fetch exchange rates' });
  }
});

app.get('/api/currencies/convert', async (req, res) => {
  try {
    const { amount, from, to } = req.query;
    
    if (!amount || !from || !to) {
      return res.status(400).json({ error: 'Amount, from, and to parameters are required' });
    }
    
    const rates = await currencyService.getExchangeRates();
    const convertedAmount = currencyService.convertAmount(
      parseFloat(amount), 
      from.toUpperCase(), 
      to.toUpperCase(), 
      rates
    );
    
    res.json({
      originalAmount: parseFloat(amount),
      originalCurrency: from.toUpperCase(),
      convertedAmount,
      targetCurrency: to.toUpperCase(),
      rate: rates[to.toUpperCase()]?.rate || 1,
      lastUpdated: rates.lastUpdated
    });
  } catch (error) {
    console.error('Error converting currency:', error);
    res.status(500).json({ error: 'Failed to convert currency' });
  }
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    port: PORT,
    version: '2.1.0',
    features: ['accounts', 'currencies', 'conversion']
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('Glaz Finance App v2.0 running on port ' + PORT);
  console.log('Local: http://localhost:' + PORT);
  console.log('External: http://195.133.47.134:' + PORT);
  console.log('API: http://195.133.47.134:' + PORT + '/api/accounts');
});
