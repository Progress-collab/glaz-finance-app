// Data Storage - постоянное хранение данных в файловой системе
const fs = require('fs');
const path = require('path');

class DataStorage {
    constructor() {
        this.dataDir = path.join(__dirname, 'data');
        this.accountsFile = path.join(this.dataDir, 'accounts.json');
        this.ensureDataDirectory();
    }

    // Создание директории для данных если не существует
    ensureDataDirectory() {
        if (!fs.existsSync(this.dataDir)) {
            fs.mkdirSync(this.dataDir, { recursive: true });
            console.log('Created data directory:', this.dataDir);
        }
    }

    // Загрузка счетов из файла
    loadAccounts() {
        try {
            if (!fs.existsSync(this.accountsFile)) {
                console.log('Accounts file does not exist, creating default data...');
                const defaultAccounts = [
                    { 
                        id: 1, 
                        name: 'Основной счет', 
                        balance: 100000, 
                        currency: 'RUB', 
                        type: 'checking', 
                        description: 'Основной расчетный счет',
                        createdAt: new Date().toISOString(),
                        updatedAt: new Date().toISOString()
                    },
                    { 
                        id: 2, 
                        name: 'Инвестиционный счет', 
                        balance: 50000, 
                        currency: 'RUB', 
                        type: 'investment', 
                        description: 'Счет для инвестиций',
                        createdAt: new Date().toISOString(),
                        updatedAt: new Date().toISOString()
                    }
                ];
                this.saveAccounts(defaultAccounts);
                return { accounts: defaultAccounts, nextId: 3 };
            }

            const data = fs.readFileSync(this.accountsFile, 'utf8');
            const accountsData = JSON.parse(data);
            
            // Валидация данных
            if (!accountsData.accounts || !Array.isArray(accountsData.accounts)) {
                throw new Error('Invalid accounts data format');
            }

            // Добавляем временные метки если их нет (для старых данных)
            accountsData.accounts = accountsData.accounts.map(account => ({
                ...account,
                createdAt: account.createdAt || new Date().toISOString(),
                updatedAt: account.updatedAt || new Date().toISOString()
            }));

            console.log(`Loaded ${accountsData.accounts.length} accounts from storage`);
            return accountsData;
        } catch (error) {
            console.error('Error loading accounts:', error);
            
            // В случае ошибки возвращаем пустые данные
            const emptyData = { accounts: [], nextId: 1 };
            this.saveAccounts(emptyData.accounts);
            return emptyData;
        }
    }

    // Сохранение счетов в файл
    saveAccounts(accounts) {
        try {
            const accountsData = {
                accounts: accounts,
                nextId: this.getNextId(accounts),
                lastSaved: new Date().toISOString(),
                version: '2.1.0'
            };

            // Создаем резервную копию перед сохранением
            if (fs.existsSync(this.accountsFile)) {
                const backupFile = path.join(this.dataDir, `accounts_backup_${Date.now()}.json`);
                fs.copyFileSync(this.accountsFile, backupFile);
                
                // Удаляем старые резервные копии (оставляем только последние 5)
                this.cleanupBackups();
            }

            fs.writeFileSync(this.accountsFile, JSON.stringify(accountsData, null, 2), 'utf8');
            console.log(`Saved ${accounts.length} accounts to storage`);
            return true;
        } catch (error) {
            console.error('Error saving accounts:', error);
            return false;
        }
    }

    // Получение следующего ID
    getNextId(accounts) {
        if (!accounts || accounts.length === 0) {
            return 1;
        }
        const maxId = Math.max(...accounts.map(account => account.id || 0));
        return maxId + 1;
    }

    // Очистка старых резервных копий
    cleanupBackups() {
        try {
            const files = fs.readdirSync(this.dataDir);
            const backupFiles = files
                .filter(file => file.startsWith('accounts_backup_') && file.endsWith('.json'))
                .map(file => ({
                    name: file,
                    path: path.join(this.dataDir, file),
                    time: fs.statSync(path.join(this.dataDir, file)).mtime.getTime()
                }))
                .sort((a, b) => b.time - a.time);

            // Удаляем все кроме последних 5 резервных копий
            if (backupFiles.length > 5) {
                const filesToDelete = backupFiles.slice(5);
                filesToDelete.forEach(file => {
                    fs.unlinkSync(file.path);
                    console.log(`Deleted old backup: ${file.name}`);
                });
            }
        } catch (error) {
            console.error('Error cleaning up backups:', error);
        }
    }

    // Получение статистики хранилища
    getStorageStats() {
        try {
            if (!fs.existsSync(this.accountsFile)) {
                return {
                    accountsCount: 0,
                    fileSize: 0,
                    lastSaved: null,
                    version: null
                };
            }

            const stats = fs.statSync(this.accountsFile);
            const data = fs.readFileSync(this.accountsFile, 'utf8');
            const accountsData = JSON.parse(data);

            return {
                accountsCount: accountsData.accounts ? accountsData.accounts.length : 0,
                fileSize: stats.size,
                lastSaved: accountsData.lastSaved,
                version: accountsData.version,
                nextId: accountsData.nextId
            };
        } catch (error) {
            console.error('Error getting storage stats:', error);
            return {
                accountsCount: 0,
                fileSize: 0,
                lastSaved: null,
                version: null,
                error: error.message
            };
        }
    }

    // Создание полной резервной копии
    createBackup() {
        try {
            if (!fs.existsSync(this.accountsFile)) {
                return null;
            }

            const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            const backupFile = path.join(this.dataDir, `full_backup_${timestamp}.json`);
            
            fs.copyFileSync(this.accountsFile, backupFile);
            console.log(`Created full backup: ${backupFile}`);
            
            return backupFile;
        } catch (error) {
            console.error('Error creating backup:', error);
            return null;
        }
    }

    // Восстановление из резервной копии
    restoreFromBackup(backupFile) {
        try {
            if (!fs.existsSync(backupFile)) {
                throw new Error('Backup file not found');
            }

            // Создаем резервную копию текущих данных
            const currentBackup = this.createBackup();
            
            // Восстанавливаем из указанной резервной копии
            fs.copyFileSync(backupFile, this.accountsFile);
            
            console.log(`Restored from backup: ${backupFile}`);
            console.log(`Current data backed up to: ${currentBackup}`);
            
            return true;
        } catch (error) {
            console.error('Error restoring from backup:', error);
            return false;
        }
    }
}

module.exports = DataStorage;
