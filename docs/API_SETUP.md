# Настройка API ключей для Glaz Finance App

## 1. OpenWeatherMap API

### Получение API ключа:
1. Перейдите на сайт [OpenWeatherMap](https://openweathermap.org/api)
2. Нажмите "Sign Up" для создания аккаунта
3. Заполните форму регистрации
4. Подтвердите email
5. Войдите в аккаунт
6. Перейдите в раздел "API Keys"
7. Скопируйте ваш API ключ

### Настройка в приложении:
1. Откройте файл `config.env` на сервере
2. Добавьте ваш API ключ:
   ```
   OPENWEATHER_API_KEY=your_api_key_here
   ```
3. Перезапустите приложение

### Тарифные планы:
- **Free**: 1,000 запросов/день, 5-дневный прогноз
- **Startup**: $40/месяц, 100,000 запросов/день, 16-дневный прогноз
- **Professional**: $160/месяц, 1,000,000 запросов/день, 30-дневный прогноз

## 2. Google API (Drive & Sheets)

### Настройка Google Cloud Console:
1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Создайте новый проект или выберите существующий
3. Включите следующие API:
   - Google Drive API
   - Google Sheets API
4. Создайте учетные данные (API ключ)
5. Создайте Service Account для серверного доступа

### Настройка Service Account:
1. В Google Cloud Console перейдите в "IAM & Admin" > "Service Accounts"
2. Нажмите "Create Service Account"
3. Заполните данные:
   - Name: `glaz-finance-app`
   - Description: `Service account for Glaz Finance App`
4. Создайте ключ (JSON файл)
5. Скачайте JSON файл с ключами

### Настройка в приложении:
1. Загрузите JSON файл на сервер в директорию `config/`
2. Обновите `config.env`:
   ```
   GOOGLE_DRIVE_API_KEY=path/to/service-account.json
   GOOGLE_SHEETS_API_KEY=path/to/service-account.json
   ```

## 3. Центральный банк РФ API

### Получение курсов валют:
- **URL**: `https://www.cbr-xml-daily.ru/daily_json.js`
- **Метод**: GET
- **Лимиты**: Без ограничений
- **Обновление**: Ежедневно в 12:00 МСК

### Поддерживаемые валюты:
- USD (Доллар США)
- EUR (Евро)
- KZT (Казахстанский тенге)
- VND (Вьетнамский донг)
- И другие валюты ЦБ РФ

## 4. Криптовалютные API

### CoinGecko API (рекомендуется):
- **URL**: `https://api.coingecko.com/api/v3/`
- **Метод**: GET
- **Лимиты**: 50 запросов/минуту (бесплатно)
- **Поддерживаемые валюты**: BTC, ETH, USDT и другие

### Настройка:
1. Зарегистрируйтесь на [CoinGecko](https://www.coingecko.com/en/api)
2. Получите API ключ
3. Добавьте в `config.env`:
   ```
   COINGECKO_API_KEY=your_api_key_here
   ```

## 5. Настройка GitHub Secrets

### Добавление секретов в GitHub:
1. Перейдите в ваш репозиторий на GitHub
2. Нажмите "Settings" > "Secrets and variables" > "Actions"
3. Добавьте следующие секреты:

```
SERVER_HOST=YOUR_SERVER_IP
SERVER_USERNAME=glaz-deploy
SERVER_PASSWORD=GlazDeploy2024!
SERVER_PORT=22
OPENWEATHER_API_KEY=your_openweather_api_key
GOOGLE_DRIVE_API_KEY=your_google_api_key
GOOGLE_SHEETS_API_KEY=your_google_sheets_key
COINGECKO_API_KEY=your_coingecko_api_key
```

## 6. Проверка настройки

### Тест API ключей:
```bash
# Тест OpenWeatherMap
curl "http://api.openweathermap.org/data/2.5/weather?q=Nha%20Trang&appid=YOUR_API_KEY"

# Тест ЦБ РФ
curl "https://www.cbr-xml-daily.ru/daily_json.js"

# Тест CoinGecko
curl "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,tether&vs_currencies=usd"
```

## 7. Мониторинг использования

### Отслеживание лимитов:
- OpenWeatherMap: Проверяйте в личном кабинете
- Google API: Мониторинг в Google Cloud Console
- CoinGecko: Проверяйте в личном кабинете

### Рекомендации:
- Используйте кэширование для уменьшения количества запросов
- Настройте уведомления о приближении к лимитам
- Рассмотрите возможность перехода на платные тарифы при необходимости
