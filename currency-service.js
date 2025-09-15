// Currency Service - работа с API ЦБ РФ
const https = require('https');

class CurrencyService {
    constructor() {
        this.cache = new Map();
        this.cacheTimeout = 60 * 60 * 1000; // 1 час
        this.cbrApiUrl = 'https://www.cbr-xml-daily.ru/daily_json.js';
    }

    // Получение курсов валют с кэшированием
    async getExchangeRates() {
        const now = Date.now();
        const cached = this.cache.get('rates');
        
        if (cached && (now - cached.timestamp) < this.cacheTimeout) {
            console.log('Using cached exchange rates');
            return cached.data;
        }

        try {
            console.log('Fetching fresh exchange rates from CBR API...');
            const rates = await this.fetchFromCBR();
            this.cache.set('rates', {
                data: rates,
                timestamp: now
            });
            return rates;
        } catch (error) {
            console.error('Error fetching exchange rates:', error);
            
            // Возвращаем кэшированные данные если есть
            if (cached) {
                console.log('Using stale cached data due to API error');
                return cached.data;
            }
            
            // Возвращаем базовые курсы если нет кэша
            return this.getDefaultRates();
        }
    }

    // Получение данных с API ЦБ РФ
    fetchFromCBR() {
        return new Promise((resolve, reject) => {
            https.get(this.cbrApiUrl, (response) => {
                let data = '';
                
                response.on('data', (chunk) => {
                    data += chunk;
                });
                
                response.on('end', () => {
                    try {
                        const jsonData = JSON.parse(data);
                        const rates = this.parseCBRData(jsonData);
                        resolve(rates);
                    } catch (error) {
                        reject(new Error('Failed to parse CBR API response: ' + error.message));
                    }
                });
            }).on('error', (error) => {
                reject(new Error('Failed to fetch from CBR API: ' + error.message));
            });
        });
    }

    // Парсинг данных ЦБ РФ
    parseCBRData(data) {
        const rates = {
            RUB: { name: 'Российский рубль', rate: 1, symbol: '₽' },
            USD: { name: 'Доллар США', rate: 1, symbol: '$' },
            EUR: { name: 'Евро', rate: 1, symbol: '€' }
        };

        // Обновляем курсы из API
        if (data.Valute) {
            if (data.Valute.USD) {
                rates.USD.rate = data.Valute.USD.Value;
                rates.USD.name = data.Valute.USD.Name;
            }
            if (data.Valute.EUR) {
                rates.EUR.rate = data.Valute.EUR.Value;
                rates.EUR.name = data.Valute.EUR.Name;
            }
        }

        // Добавляем время обновления
        rates.lastUpdated = new Date().toISOString();
        
        return rates;
    }

    // Базовые курсы (fallback)
    getDefaultRates() {
        return {
            RUB: { name: 'Российский рубль', rate: 1, symbol: '₽' },
            USD: { name: 'Доллар США', rate: 95.5, symbol: '$' },
            EUR: { name: 'Евро', rate: 104.2, symbol: '€' },
            lastUpdated: new Date().toISOString(),
            isDefault: true
        };
    }

    // Конвертация между валютами
    convertAmount(amount, fromCurrency, toCurrency, rates) {
        if (!rates || fromCurrency === toCurrency) {
            return amount;
        }

        const fromRate = rates[fromCurrency]?.rate || 1;
        const toRate = rates[toCurrency]?.rate || 1;

        // Конвертируем в рубли, затем в целевую валюту
        const amountInRubles = amount * fromRate;
        const convertedAmount = amountInRubles / toRate;

        return Math.round(convertedAmount * 100) / 100; // Округляем до 2 знаков
    }

    // Получение символа валюты
    getCurrencySymbol(currency, rates) {
        if (!rates || !rates[currency]) {
            const symbols = { RUB: '₽', USD: '$', EUR: '€' };
            return symbols[currency] || currency;
        }
        return rates[currency].symbol;
    }

    // Форматирование суммы с символом валюты
    formatAmount(amount, currency, rates) {
        const symbol = this.getCurrencySymbol(currency, rates);
        const formatted = new Intl.NumberFormat('ru-RU', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(amount);
        
        return `${formatted} ${symbol}`;
    }

    // Получение списка доступных валют
    getAvailableCurrencies(rates) {
        if (!rates) return ['RUB', 'USD', 'EUR'];
        return Object.keys(rates).filter(key => key !== 'lastUpdated' && key !== 'isDefault');
    }
}

module.exports = CurrencyService;
