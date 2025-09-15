const express = require('express');
const cors = require('cors');
const path = require('path');
const CurrencyService = require('./currency-service');
const DataStorage = require('./data-storage');
const AccountTypesService = require('./account-types-service');
const app = express();
const PORT = 3000;

// Инициализация сервисов
const currencyService = new CurrencyService();
const dataStorage = new DataStorage();
const accountTypesService = new AccountTypesService(dataStorage);

// Загрузка данных из постоянного хранилища
let accountsData = dataStorage.loadAccounts();
let accounts = accountsData.accounts;
let nextId = accountsData.nextId;

console.log(`Application started with ${accounts.length} accounts loaded from storage`);

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
    description: description || '',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };

  accounts.push(newAccount);
  
  // Сохраняем данные в файл
  if (dataStorage.saveAccounts(accounts)) {
    res.status(201).json({ account: newAccount });
  } else {
    // Откатываем изменения если не удалось сохранить
    accounts.pop();
    nextId--;
    res.status(500).json({ error: 'Failed to save account' });
  }
});

app.put('/api/accounts/:id', (req, res) => {
  const accountIndex = accounts.findIndex(acc => acc.id === parseInt(req.params.id));
  
  if (accountIndex === -1) {
    return res.status(404).json({ error: 'Account not found' });
  }

  const { name, balance, currency, type, description } = req.body;
  
  // Сохраняем старые данные для отката
  const oldAccount = { ...accounts[accountIndex] };
  
  accounts[accountIndex] = {
    ...accounts[accountIndex],
    name: name || accounts[accountIndex].name,
    balance: balance !== undefined ? parseFloat(balance) : accounts[accountIndex].balance,
    currency: currency || accounts[accountIndex].currency,
    type: type || accounts[accountIndex].type,
    description: description !== undefined ? description : accounts[accountIndex].description,
    updatedAt: new Date().toISOString()
  };

  // Сохраняем данные в файл
  if (dataStorage.saveAccounts(accounts)) {
    res.json({ account: accounts[accountIndex] });
  } else {
    // Откатываем изменения если не удалось сохранить
    accounts[accountIndex] = oldAccount;
    res.status(500).json({ error: 'Failed to save account changes' });
  }
});

app.delete('/api/accounts/:id', (req, res) => {
  const accountIndex = accounts.findIndex(acc => acc.id === parseInt(req.params.id));
  
  if (accountIndex === -1) {
    return res.status(404).json({ error: 'Account not found' });
  }

  const deletedAccount = accounts.splice(accountIndex, 1)[0];
  
  // Сохраняем данные в файл
  if (dataStorage.saveAccounts(accounts)) {
    res.json({ message: 'Account deleted', account: deletedAccount });
  } else {
    // Восстанавливаем удаленный счет если не удалось сохранить
    accounts.splice(accountIndex, 0, deletedAccount);
    res.status(500).json({ error: 'Failed to save account deletion' });
  }
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
    
    // Вычисляем курс конвертации между валютами
    const fromRate = rates[from.toUpperCase()]?.rate || 1;
    const toRate = rates[to.toUpperCase()]?.rate || 1;
    const conversionRate = fromRate / toRate;
    
    res.json({
      originalAmount: parseFloat(amount),
      originalCurrency: from.toUpperCase(),
      convertedAmount,
      targetCurrency: to.toUpperCase(),
      rate: conversionRate,
      lastUpdated: rates.lastUpdated
    });
  } catch (error) {
    console.error('Error converting currency:', error);
    res.status(500).json({ error: 'Failed to convert currency' });
  }
});

// Storage API endpoints
app.get('/api/storage/stats', (req, res) => {
  try {
    const stats = dataStorage.getStorageStats();
    res.json({
      ...stats,
      uptime: process.uptime(),
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error getting storage stats:', error);
    res.status(500).json({ error: 'Failed to get storage stats' });
  }
});

app.post('/api/storage/backup', (req, res) => {
  try {
    const backupFile = dataStorage.createBackup();
    if (backupFile) {
      res.json({ 
        message: 'Backup created successfully',
        backupFile: backupFile,
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(500).json({ error: 'Failed to create backup' });
    }
  } catch (error) {
    console.error('Error creating backup:', error);
    res.status(500).json({ error: 'Failed to create backup' });
  }
});

app.get('/api/storage/backups', (req, res) => {
  try {
    const backups = dataStorage.getAvailableBackups();
    res.json({
      backups: backups,
      count: backups.length,
      maxBackups: 150,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error getting backups:', error);
    res.status(500).json({ error: 'Failed to get backups list' });
  }
});

app.post('/api/storage/restore', (req, res) => {
  try {
    const { filename } = req.body;
    
    if (!filename) {
      return res.status(400).json({ error: 'Filename is required' });
    }
    
    const result = dataStorage.restoreFromBackupByName(filename);
    
    if (result.success) {
      // Обновляем данные в памяти после восстановления
      const restoredData = dataStorage.loadAccounts();
      accounts = restoredData.accounts;
      nextId = restoredData.nextId;
      
      res.json({
        message: 'Data restored successfully',
        ...result,
        reloadedAccounts: accounts.length
      });
    } else {
      res.status(500).json({
        error: 'Failed to restore data',
        details: result.error
      });
    }
  } catch (error) {
    console.error('Error restoring data:', error);
    res.status(500).json({ error: 'Failed to restore data' });
  }
});

app.post('/api/storage/restore/:filename', (req, res) => {
  try {
    const { filename } = req.params;
    
    const result = dataStorage.restoreFromBackupByName(filename);
    
    if (result.success) {
      // Обновляем данные в памяти после восстановления
      const restoredData = dataStorage.loadAccounts();
      accounts = restoredData.accounts;
      nextId = restoredData.nextId;
      
      res.json({
        message: 'Data restored successfully',
        ...result,
        reloadedAccounts: accounts.length
      });
    } else {
      res.status(500).json({
        error: 'Failed to restore data',
        details: result.error
      });
    }
  } catch (error) {
    console.error('Error restoring data:', error);
    res.status(500).json({ error: 'Failed to restore data' });
  }
});

// Account Types API endpoints
app.get('/api/account-types', (req, res) => {
  try {
    const types = accountTypesService.getAllTypes();
    const usageStats = accountTypesService.getTypeUsageStats(accounts);
    
    res.json({
      types: types,
      usageStats: usageStats,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error getting account types:', error);
    res.status(500).json({ error: 'Failed to get account types' });
  }
});

app.get('/api/account-types/:id', (req, res) => {
  try {
    const { id } = req.params;
    const type = accountTypesService.getTypeById(id);
    
    if (!type) {
      return res.status(404).json({ error: 'Account type not found' });
    }
    
    const usageStats = accountTypesService.getTypeUsageStats(accounts);
    
    res.json({
      type: type,
      usage: usageStats[id] || { count: 0, accounts: [] },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error getting account type:', error);
    res.status(500).json({ error: 'Failed to get account type' });
  }
});

app.post('/api/account-types', (req, res) => {
  try {
    const result = accountTypesService.addAccountType(req.body);
    
    if (result.success) {
      res.status(201).json({
        message: 'Account type created successfully',
        type: result.type,
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(400).json({
        error: 'Failed to create account type',
        details: result.error
      });
    }
  } catch (error) {
    console.error('Error creating account type:', error);
    res.status(500).json({ error: 'Failed to create account type' });
  }
});

app.put('/api/account-types/:id', (req, res) => {
  try {
    const { id } = req.params;
    
    // Валидация операции
    const validation = accountTypesService.validateTypeOperation('update', id, accounts);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const result = accountTypesService.updateAccountType(id, req.body);
    
    if (result.success) {
      res.json({
        message: 'Account type updated successfully',
        type: result.type,
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(400).json({
        error: 'Failed to update account type',
        details: result.error
      });
    }
  } catch (error) {
    console.error('Error updating account type:', error);
    res.status(500).json({ error: 'Failed to update account type' });
  }
});

app.delete('/api/account-types/:id', (req, res) => {
  try {
    const { id } = req.params;
    
    // Валидация операции
    const validation = accountTypesService.validateTypeOperation('delete', id, accounts);
    if (!validation.valid) {
      return res.status(400).json({ error: validation.error });
    }
    
    const result = accountTypesService.deleteAccountType(id, accounts);
    
    if (result.success) {
      // Обновляем данные в памяти
      const updatedData = dataStorage.loadAccounts();
      accounts = updatedData.accounts;
      nextId = updatedData.nextId;
      
      res.json({
        message: 'Account type deleted successfully',
        deletedType: result.deletedType,
        reassignedAccounts: result.reassignedAccounts,
        timestamp: new Date().toISOString()
      });
    } else {
      res.status(400).json({
        error: 'Failed to delete account type',
        details: result.error
      });
    }
  } catch (error) {
    console.error('Error deleting account type:', error);
    res.status(500).json({ error: 'Failed to delete account type' });
  }
});

app.get('/health', (req, res) => {
  try {
    const storageStats = dataStorage.getStorageStats();
    res.json({ 
      status: 'OK',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      port: PORT,
      version: '2.3.0',
      features: ['accounts', 'currencies', 'conversion', 'persistent_storage', 'backup_restore', 'account_types'],
      storage: {
        accountsCount: storageStats.accountsCount,
        lastSaved: storageStats.lastSaved,
        fileSize: storageStats.fileSize
      }
    });
  } catch (error) {
    res.json({ 
      status: 'OK',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
      port: PORT,
      version: '2.3.0',
      features: ['accounts', 'currencies', 'conversion', 'persistent_storage', 'backup_restore', 'account_types'],
      storage: { error: 'Unable to get storage stats' }
    });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('Glaz Finance App v2.0 running on port ' + PORT);
  console.log('Local: http://localhost:' + PORT);
  console.log('External: http://195.133.47.134:' + PORT);
  console.log('API: http://195.133.47.134:' + PORT + '/api/accounts');
});
