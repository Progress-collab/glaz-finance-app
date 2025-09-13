-- Начальные данные для Glaz Finance App

-- Вставка пользователей (семейные профили)
INSERT INTO users (name, email, role, timezone) VALUES
('Evgeny Glazeykin', 'glazeykin@gmail.com', 'admin', 'Asia/Ho_Chi_Minh'),
('Wife', 'wife@example.com', 'member', 'Asia/Ho_Chi_Minh'),
('Son', 'son@example.com', 'member', 'Asia/Ho_Chi_Minh');

-- Вставка типов счетов
INSERT INTO account_types (name, description, color, icon, is_default) VALUES
('Текущие счета', 'Счета для повседневных расходов и доходов', '#1976d2', 'account_balance', true),
('Инвестиционные счета', 'Счета для инвестиций и накоплений', '#388e3c', 'trending_up', true),
('Сберегательные счета', 'Счета для долгосрочных накоплений', '#f57c00', 'savings', false),
('Кредитные счета', 'Кредитные карты и займы', '#d32f2f', 'credit_card', false);

-- Вставка валют
INSERT INTO currencies (code, name, symbol, is_crypto, is_active) VALUES
('RUB', 'Российский рубль', '₽', false, true),
('USD', 'Доллар США', '$', false, true),
('KZT', 'Казахстанский тенге', '₸', false, true),
('VND', 'Вьетнамский донг', '₫', false, true),
('EUR', 'Евро', '€', false, true),
('USDT', 'Tether', 'USDT', true, true),
('BTC', 'Bitcoin', '₿', true, true),
('ETH', 'Ethereum', 'Ξ', true, true);

-- Вставка начальных курсов валют (примерные значения)
INSERT INTO exchange_rates (from_currency_id, to_currency_id, rate, source, date) VALUES
-- USD к RUB (примерный курс)
((SELECT id FROM currencies WHERE code = 'USD'), (SELECT id FROM currencies WHERE code = 'RUB'), 95.50, 'cbr', CURRENT_DATE),
-- KZT к RUB
((SELECT id FROM currencies WHERE code = 'KZT'), (SELECT id FROM currencies WHERE code = 'RUB'), 0.20, 'cbr', CURRENT_DATE),
-- VND к RUB
((SELECT id FROM currencies WHERE code = 'VND'), (SELECT id FROM currencies WHERE code = 'RUB'), 0.0039, 'cbr', CURRENT_DATE),
-- EUR к RUB
((SELECT id FROM currencies WHERE code = 'EUR'), (SELECT id FROM currencies WHERE code = 'RUB'), 102.30, 'cbr', CURRENT_DATE),
-- USDT к USD
((SELECT id FROM currencies WHERE code = 'USDT'), (SELECT id FROM currencies WHERE code = 'USD'), 1.00, 'crypto', CURRENT_DATE),
-- BTC к USD
((SELECT id FROM currencies WHERE code = 'BTC'), (SELECT id FROM currencies WHERE code = 'USD'), 43000.00, 'crypto', CURRENT_DATE),
-- ETH к USD
((SELECT id FROM currencies WHERE code = 'ETH'), (SELECT id FROM currencies WHERE code = 'USD'), 2600.00, 'crypto', CURRENT_DATE);

-- Вставка настроек погоды по умолчанию
INSERT INTO weather_settings (city, country, latitude, longitude, timezone, is_default, created_by) VALUES
('Nha Trang', 'Vietnam', 12.2388, 109.1967, 'Asia/Ho_Chi_Minh', true, (SELECT id FROM users WHERE email = 'glazeykin@gmail.com'));

-- Вставка настроек приложения
INSERT INTO app_settings (key, value, description) VALUES
('default_currency', 'RUB', 'Валюта по умолчанию для отображения'),
('backup_enabled', 'true', 'Включено ли автоматическое резервное копирование'),
('backup_interval_hours', '24', 'Интервал резервного копирования в часах'),
('backup_retention_days', '180', 'Количество дней хранения резервных копий'),
('weather_api_key', '', 'API ключ для OpenWeatherMap'),
('google_drive_enabled', 'false', 'Включена ли синхронизация с Google Drive'),
('google_sheets_enabled', 'false', 'Включена ли синхронизация с Google Sheets'),
('auto_currency_update', 'true', 'Автоматическое обновление курсов валют'),
('currency_update_interval_hours', '1', 'Интервал обновления курсов валют в часах');

-- Создание представлений для удобства работы
CREATE VIEW account_summary AS
SELECT 
    a.id,
    a.name,
    a.description,
    at.name as account_type,
    at.color as account_type_color,
    c.code as currency_code,
    c.symbol as currency_symbol,
    a.balance,
    u.name as created_by_name,
    a.created_at,
    a.updated_at
FROM accounts a
JOIN account_types at ON a.account_type_id = at.id
JOIN currencies c ON a.currency_id = c.id
JOIN users u ON a.created_by = u.id
WHERE a.is_active = true;

CREATE VIEW balance_by_currency AS
SELECT 
    c.code as currency_code,
    c.name as currency_name,
    c.symbol as currency_symbol,
    at.name as account_type,
    SUM(a.balance) as total_balance,
    COUNT(a.id) as account_count
FROM accounts a
JOIN currencies c ON a.currency_id = c.id
JOIN account_types at ON a.account_type_id = at.id
WHERE a.is_active = true
GROUP BY c.code, c.name, c.symbol, at.name
ORDER BY c.code, at.name;

CREATE VIEW recent_transactions AS
SELECT 
    t.id,
    t.amount,
    t.description,
    t.transaction_type,
    t.category,
    t.tags,
    a.name as account_name,
    c.code as currency_code,
    c.symbol as currency_symbol,
    u.name as created_by_name,
    t.created_at
FROM transactions t
JOIN accounts a ON t.account_id = a.id
JOIN currencies c ON a.currency_id = c.id
JOIN users u ON t.created_by = u.id
ORDER BY t.created_at DESC
LIMIT 100;
