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
                
            // Удаляем старые резервные копии (оставляем только последние 150)
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

            // Удаляем все кроме последних 150 резервных копий
            const maxBackups = 150;
            if (backupFiles.length > maxBackups) {
                const filesToDelete = backupFiles.slice(maxBackups);
                filesToDelete.forEach(file => {
                    fs.unlinkSync(file.path);
                    console.log(`Deleted old backup: ${file.name}`);
                });
                console.log(`Cleaned up ${filesToDelete.length} old backup files. Kept ${maxBackups} most recent.`);
            }
        } catch (error) {
            console.error('Error cleaning up backups:', error);
        }
    }

    // Получение списка доступных резервных копий
    getAvailableBackups() {
        try {
            if (!fs.existsSync(this.dataDir)) {
                return [];
            }

            const files = fs.readdirSync(this.dataDir);
            const backupFiles = files
                .filter(file => file.startsWith('accounts_backup_') && file.endsWith('.json'))
                .map(file => {
                    const filePath = path.join(this.dataDir, file);
                    const stats = fs.statSync(filePath);
                    const timestamp = file.replace('accounts_backup_', '').replace('.json', '');
                    
                    return {
                        filename: file,
                        filepath: filePath,
                        timestamp: parseInt(timestamp),
                        date: new Date(parseInt(timestamp)).toISOString(),
                        size: stats.size
                    };
                })
                .sort((a, b) => b.timestamp - a.timestamp);

            return backupFiles;
        } catch (error) {
            console.error('Error getting available backups:', error);
            return [];
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
                    version: null,
                    backupsCount: 0
                };
            }

            const stats = fs.statSync(this.accountsFile);
            const data = fs.readFileSync(this.accountsFile, 'utf8');
            const accountsData = JSON.parse(data);
            const backups = this.getAvailableBackups();

            return {
                accountsCount: accountsData.accounts ? accountsData.accounts.length : 0,
                fileSize: stats.size,
                lastSaved: accountsData.lastSaved,
                version: accountsData.version,
                nextId: accountsData.nextId,
                backupsCount: backups.length,
                availableBackups: backups.slice(0, 10) // Показываем последние 10 для удобства
            };
        } catch (error) {
            console.error('Error getting storage stats:', error);
            return {
                accountsCount: 0,
                fileSize: 0,
                lastSaved: null,
                version: null,
                backupsCount: 0,
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
            
            // Читаем и валидируем резервную копию
            const backupData = fs.readFileSync(backupFile, 'utf8');
            const parsedBackup = JSON.parse(backupData);
            
            // Проверяем структуру данных
            if (!parsedBackup.accounts || !Array.isArray(parsedBackup.accounts)) {
                throw new Error('Invalid backup file format');
            }
            
            // Восстанавливаем из указанной резервной копии
            fs.copyFileSync(backupFile, this.accountsFile);
            
            console.log(`Restored from backup: ${backupFile}`);
            console.log(`Current data backed up to: ${currentBackup}`);
            console.log(`Restored ${parsedBackup.accounts.length} accounts`);
            
            return {
                success: true,
                restoredAccounts: parsedBackup.accounts.length,
                backupFile: backupFile,
                currentBackup: currentBackup,
                restoredAt: new Date().toISOString()
            };
        } catch (error) {
            console.error('Error restoring from backup:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Восстановление из резервной копии по имени файла
    restoreFromBackupByName(filename) {
        try {
            const backupFile = path.join(this.dataDir, filename);
            return this.restoreFromBackup(backupFile);
        } catch (error) {
            console.error('Error restoring from backup by name:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }
}

module.exports = DataStorage;
