# Информация о портах Glaz Finance App

## 🔧 Настройка портов

### Причина изменения портов
На сервере уже работает приложение на порту **3000**, поэтому мы изменили порты нашего приложения, чтобы избежать конфликта.

### Новые порты приложения

| Сервис | Порт | Описание |
|--------|------|----------|
| **Frontend** | **3001** | React приложение (изменен с 3000) |
| **Backend API** | **3002** | Node.js API (изменен с 3001) |
| **PostgreSQL** | 5432 | База данных |
| **Redis** | 6379 | Кэширование |
| **Nginx** | 80/443 | Reverse proxy |

### Доступ к приложению

**Основной URL**: `http://YOUR_SERVER_IP:3001`

**API URL**: `http://YOUR_SERVER_IP:3002`

### Проверка портов

#### На сервере (Windows):
```powershell
# Проверка занятых портов
netstat -an | findstr :3001
netstat -an | findstr :3002
netstat -an | findstr :5432
netstat -an | findstr :6379
```

#### Из Docker:
```bash
# Проверка контейнеров и портов
docker-compose ps
docker port glaz-finance-frontend
docker port glaz-finance-backend
```

### Настройка firewall

Если нужно открыть порты в firewall:

```powershell
# Открытие портов в Windows Firewall
New-NetFirewallRule -Name "Glaz-Finance-Frontend" -DisplayName "Glaz Finance Frontend" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 3001
New-NetFirewallRule -Name "Glaz-Finance-Backend" -DisplayName "Glaz Finance Backend" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 3002
New-NetFirewallRule -Name "Glaz-Finance-PostgreSQL" -DisplayName "Glaz Finance PostgreSQL" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5432
New-NetFirewallRule -Name "Glaz-Finance-Redis" -DisplayName "Glaz Finance Redis" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 6379
```

### Изменения в конфигурации

#### Docker Compose
- Frontend: `"3001:3000"` (внешний порт 3001, внутренний 3000)
- Backend: `"3002:3002"` (внешний и внутренний порт 3002)

#### Environment Variables
- `REACT_APP_API_URL=http://localhost:3002`
- `PORT=3002` (для backend)

### Устранение проблем

#### Если порт занят:
1. Проверьте, что порт свободен:
   ```powershell
   netstat -an | findstr :3001
   ```

2. Если порт занят, измените в `docker-compose.yml`:
   ```yaml
   ports:
     - "3003:3000"  # Используйте другой порт
   ```

3. Перезапустите контейнеры:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

#### Если приложение не доступно:
1. Проверьте статус контейнеров:
   ```bash
   docker-compose ps
   ```

2. Проверьте логи:
   ```bash
   docker-compose logs frontend
   docker-compose logs backend
   ```

3. Проверьте firewall:
   ```powershell
   Get-NetFirewallRule -Name "*Glaz*"
   ```

### Резервные порты

Если основные порты заняты, можно использовать:
- Frontend: 3003, 3004, 3005
- Backend: 3006, 3007, 3008
- PostgreSQL: 5433, 5434
- Redis: 6380, 6381

### Мониторинг портов

#### Создание скрипта мониторинга:
```powershell
# monitor-ports.ps1
Write-Host "Проверка портов Glaz Finance App..." -ForegroundColor Green

$ports = @(3001, 3002, 5432, 6379)
foreach ($port in $ports) {
    $result = netstat -an | findstr ":$port"
    if ($result) {
        Write-Host "Порт $port: ЗАНЯТ" -ForegroundColor Red
        Write-Host $result -ForegroundColor Yellow
    } else {
        Write-Host "Порт $port: СВОБОДЕН" -ForegroundColor Green
    }
    Write-Host ""
}
```

---

**Важно**: Всегда проверяйте доступность портов перед запуском приложения!
