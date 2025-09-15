// Account Types Service - управление типами счетов с защитой от багов
const fs = require('fs');
const path = require('path');

class AccountTypesService {
    constructor(dataStorage) {
        this.dataStorage = dataStorage;
        this.typesFile = path.join(dataStorage.dataDir, 'account-types.json');
        this.defaultTypes = [
            { id: 'checking', name: 'Расчётный', description: 'Основной расчётный счёт', isSystem: true, createdAt: new Date().toISOString() },
            { id: 'savings', name: 'Накопительный', description: 'Счёт для накоплений', isSystem: false, createdAt: new Date().toISOString() },
            { id: 'investment', name: 'Инвестиционный', description: 'Счёт для инвестиций', isSystem: false, createdAt: new Date().toISOString() },
            { id: 'credit', name: 'Кредитный', description: 'Кредитный счёт', isSystem: false, createdAt: new Date().toISOString() }
        ];
    }

    // Загрузка типов счетов
    loadAccountTypes() {
        try {
            if (!fs.existsSync(this.typesFile)) {
                console.log('Account types file does not exist, creating default types...');
                this.saveAccountTypes(this.defaultTypes);
                return this.defaultTypes;
            }

            const data = fs.readFileSync(this.typesFile, 'utf8');
            const typesData = JSON.parse(data);
            
            // Валидация данных
            if (!typesData.types || !Array.isArray(typesData.types)) {
                throw new Error('Invalid account types data format');
            }

            // Проверяем наличие системного типа "Расчётный"
            const hasCheckingType = typesData.types.some(type => type.id === 'checking' && type.isSystem);
            if (!hasCheckingType) {
                console.log('System type "checking" not found, adding it...');
                typesData.types.unshift(this.defaultTypes[0]);
                this.saveAccountTypes(typesData.types);
            }

            console.log(`Loaded ${typesData.types.length} account types from storage`);
            return typesData.types;
        } catch (error) {
            console.error('Error loading account types:', error);
            
            // В случае ошибки возвращаем базовые типы
            this.saveAccountTypes(this.defaultTypes);
            return this.defaultTypes;
        }
    }

    // Сохранение типов счетов
    saveAccountTypes(types) {
        try {
            const typesData = {
                types: types,
                lastSaved: new Date().toISOString(),
                version: '2.2.0'
            };

            // Создаем резервную копию перед сохранением
            if (fs.existsSync(this.typesFile)) {
                const backupFile = path.join(this.dataStorage.dataDir, `account-types_backup_${Date.now()}.json`);
                fs.copyFileSync(this.typesFile, backupFile);
            }

            fs.writeFileSync(this.typesFile, JSON.stringify(typesData, null, 2), 'utf8');
            console.log(`Saved ${types.length} account types to storage`);
            return true;
        } catch (error) {
            console.error('Error saving account types:', error);
            return false;
        }
    }

    // Получение всех типов счетов
    getAllTypes() {
        return this.loadAccountTypes();
    }

    // Получение типа по ID
    getTypeById(id) {
        const types = this.loadAccountTypes();
        return types.find(type => type.id === id);
    }

    // Добавление нового типа счета
    addAccountType(typeData) {
        try {
            const { name, description } = typeData;
            
            if (!name || name.trim() === '') {
                throw new Error('Type name is required');
            }

            const types = this.loadAccountTypes();
            
            // Проверяем уникальность имени
            const existingType = types.find(type => 
                type.name.toLowerCase() === name.toLowerCase()
            );
            if (existingType) {
                throw new Error('Account type with this name already exists');
            }

            // Генерируем ID
            const id = this.generateTypeId(name);
            
            const newType = {
                id,
                name: name.trim(),
                description: description ? description.trim() : '',
                isSystem: false,
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString()
            };

            types.push(newType);
            
            if (this.saveAccountTypes(types)) {
                return { success: true, type: newType };
            } else {
                throw new Error('Failed to save account types');
            }
        } catch (error) {
            console.error('Error adding account type:', error);
            return { success: false, error: error.message };
        }
    }

    // Обновление типа счета
    updateAccountType(id, updateData) {
        try {
            const { name, description } = updateData;
            const types = this.loadAccountTypes();
            const typeIndex = types.findIndex(type => type.id === id);
            
            if (typeIndex === -1) {
                throw new Error('Account type not found');
            }

            const type = types[typeIndex];
            
            // Проверяем, не пытаемся ли мы изменить системный тип
            if (type.isSystem && id === 'checking') {
                // Для системного типа "Расчётный" разрешаем только переименование
                if (name && name.trim() !== '') {
                    types[typeIndex] = {
                        ...type,
                        name: name.trim(),
                        description: description ? description.trim() : type.description,
                        updatedAt: new Date().toISOString()
                    };
                } else {
                    throw new Error('System type "checking" can only be renamed, not deleted');
                }
            } else {
                // Для обычных типов разрешаем полное обновление
                if (name && name.trim() !== '') {
                    // Проверяем уникальность имени
                    const existingType = types.find(t => 
                        t.id !== id && t.name.toLowerCase() === name.toLowerCase()
                    );
                    if (existingType) {
                        throw new Error('Account type with this name already exists');
                    }
                    
                    types[typeIndex] = {
                        ...type,
                        name: name.trim(),
                        description: description ? description.trim() : type.description,
                        updatedAt: new Date().toISOString()
                    };
                } else {
                    throw new Error('Type name is required');
                }
            }

            if (this.saveAccountTypes(types)) {
                return { success: true, type: types[typeIndex] };
            } else {
                throw new Error('Failed to save account types');
            }
        } catch (error) {
            console.error('Error updating account type:', error);
            return { success: false, error: error.message };
        }
    }

    // Удаление типа счета
    deleteAccountType(id, accounts = []) {
        try {
            const types = this.loadAccountTypes();
            const typeIndex = types.findIndex(type => type.id === id);
            
            if (typeIndex === -1) {
                throw new Error('Account type not found');
            }

            const type = types[typeIndex];
            
            // Проверяем, не пытаемся ли мы удалить системный тип
            if (type.isSystem) {
                throw new Error('System account types cannot be deleted');
            }

            // Проверяем, используется ли этот тип в счетах
            const accountsUsingType = accounts.filter(account => account.type === id);
            
            if (accountsUsingType.length > 0) {
                // Переводим все счета с удаляемым типом на тип "Расчётный"
                console.log(`Found ${accountsUsingType.length} accounts using type "${type.name}", reassigning to "checking"`);
                
                // Обновляем счета
                accounts.forEach(account => {
                    if (account.type === id) {
                        account.type = 'checking';
                        account.updatedAt = new Date().toISOString();
                    }
                });
                
                // Сохраняем обновленные счета
                if (!this.dataStorage.saveAccounts(accounts)) {
                    throw new Error('Failed to update accounts after type deletion');
                }
            }

            // Удаляем тип
            types.splice(typeIndex, 1);
            
            if (this.saveAccountTypes(types)) {
                return { 
                    success: true, 
                    deletedType: type,
                    reassignedAccounts: accountsUsingType.length
                };
            } else {
                throw new Error('Failed to save account types');
            }
        } catch (error) {
            console.error('Error deleting account type:', error);
            return { success: false, error: error.message };
        }
    }

    // Генерация ID для типа счета
    generateTypeId(name) {
        const baseId = name.toLowerCase()
            .replace(/[^a-z0-9]/g, '')
            .substring(0, 20);
        
        const types = this.loadAccountTypes();
        let id = baseId;
        let counter = 1;
        
        while (types.some(type => type.id === id)) {
            id = `${baseId}${counter}`;
            counter++;
        }
        
        return id;
    }

    // Получение статистики использования типов
    getTypeUsageStats(accounts = []) {
        const types = this.loadAccountTypes();
        const stats = {};
        
        types.forEach(type => {
            stats[type.id] = {
                type: type,
                count: accounts.filter(account => account.type === type.id).length,
                accounts: accounts.filter(account => account.type === type.id)
            };
        });
        
        return stats;
    }

    // Валидация операций с типами
    validateTypeOperation(operation, typeId, accounts = []) {
        const types = this.loadAccountTypes();
        const type = types.find(t => t.id === typeId);
        
        if (!type) {
            return { valid: false, error: 'Account type not found' };
        }
        
        if (operation === 'delete' && type.isSystem) {
            return { valid: false, error: 'System account types cannot be deleted' };
        }
        
        if (operation === 'delete' && typeId === 'checking') {
            return { valid: false, error: 'Checking account type cannot be deleted' };
        }
        
        return { valid: true };
    }
}

module.exports = AccountTypesService;
