# Настройка Windows Server 2012 R2

## Подготовка сервера

### Шаг 1: Подключение к серверу
1. Подключитесь к вашему Windows Server 2012 R2 через RDP
2. Откройте PowerShell от имени администратора
3. Выполните команду для проверки версии:
   ```powershell
   Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion
   ```

### Шаг 2: Настройка PowerShell
1. Установите политику выполнения:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### Шаг 3: Запуск скрипта настройки
1. Скопируйте файл `scripts/setup-server.ps1` на сервер
2. Запустите скрипт:
   ```powershell
   .\setup-server.ps1
   ```

## Ручная настройка (если скрипт не работает)

### Установка Docker Desktop
1. Скачайте Docker Desktop для Windows с [официального сайта](https://www.docker.com/products/docker-desktop/)
2. Установите Docker Desktop
3. Запустите Docker Desktop
4. Проверьте установку:
   ```powershell
   docker --version
   docker-compose --version
   ```

### Установка Git
1. Скачайте Git для Windows с [официального сайта](https://git-scm.com/download/win)
2. Установите Git с настройками по умолчанию
3. Проверьте установку:
   ```powershell
   git --version
   ```

### Установка Node.js
1. Скачайте Node.js LTS с [официального сайта](https://nodejs.org/)
2. Установите Node.js
3. Проверьте установку:
   ```powershell
   node --version
   npm --version
   ```

### Настройка SSH сервера
1. Установите OpenSSH Server:
   ```powershell
   Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
   ```

2. Запустите SSH сервис:
   ```powershell
   Start-Service sshd
   Set-Service -Name sshd -StartupType 'Automatic'
   ```

3. Настройте firewall:
   ```powershell
   New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
   ```

### Создание пользователя для деплоя
1. Создайте пользователя:
   ```powershell
   $deployUser = "glaz-deploy"
   $deployPassword = "GlazDeploy2024!"
   New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User"
   Add-LocalGroupMember -Group "Administrators" -Member $deployUser
   ```

### Создание директории приложения
1. Создайте директорию:
   ```powershell
   $appDir = "C:\glaz-finance-app"
   New-Item -ItemType Directory -Path $appDir -Force
   ```

2. Настройте права доступа:
   ```powershell
   icacls $appDir /grant "glaz-deploy:(OI)(CI)F" /T
   ```

## Проверка настройки

### Тест SSH подключения
1. С другого компьютера попробуйте подключиться:
   ```bash
   ssh glaz-deploy@YOUR_SERVER_IP
   ```

### Тест Docker
1. Запустите тестовый контейнер:
   ```powershell
   docker run hello-world
   ```

### Тест Git
1. Клонируйте тестовый репозиторий:
   ```powershell
   git clone https://github.com/octocat/Hello-World.git C:\test-repo
   ```

## Настройка API ключей

### Получение OpenWeatherMap API ключа
1. Перейдите на [OpenWeatherMap](https://openweathermap.org/api)
2. Зарегистрируйтесь и получите API ключ
3. Добавьте ключ в файл `C:\glaz-finance-app\config.env`

### Настройка Google API
1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Создайте проект
3. Включите Google Drive API и Google Sheets API
4. Создайте Service Account
5. Скачайте JSON файл с ключами
6. Загрузите файл на сервер в `C:\glaz-finance-app\config\`

## Запуск приложения

### Первый запуск
1. Перейдите в директорию приложения:
   ```powershell
   cd C:\glaz-finance-app
   ```

2. Клонируйте репозиторий:
   ```powershell
   git clone https://github.com/glazeykin/glaz-finance-app.git .
   ```

3. Запустите приложение:
   ```powershell
   docker-compose up -d
   ```

4. Проверьте статус:
   ```powershell
   docker-compose ps
   ```

### Проверка работы
1. Откройте браузер
2. Перейдите по адресу: `http://YOUR_SERVER_IP:3001`
3. Должно открыться приложение

## Мониторинг и логи

### Просмотр логов
```powershell
# Логи всех сервисов
docker-compose logs

# Логи конкретного сервиса
docker-compose logs backend
docker-compose logs frontend
docker-compose logs postgres
```

### Мониторинг ресурсов
```powershell
# Использование диска
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}}

# Использование памяти
Get-WmiObject -Class Win32_OperatingSystem | Select-Object @{Name="TotalRAM(GB)";Expression={[math]::Round($_.TotalVisibleMemorySize/1MB,2)}}, @{Name="FreeRAM(GB)";Expression={[math]::Round($_.FreePhysicalMemory/1MB,2)}}
```

## Резервное копирование

### Автоматическое резервное копирование
Приложение автоматически создает резервные копии базы данных каждые 24 часа.

### Ручное резервное копирование
```powershell
cd C:\glaz-finance-app
docker-compose exec postgres pg_dump -U glaz_user glaz_finance > backup_$(Get-Date -Format "yyyyMMdd_HHmmss").sql
```

## Устранение неполадок

### Проблемы с Docker
1. Перезапустите Docker Desktop
2. Проверьте статус сервисов:
   ```powershell
   Get-Service docker
   ```

### Проблемы с SSH
1. Проверьте статус SSH сервиса:
   ```powershell
   Get-Service sshd
   ```

2. Проверьте firewall:
   ```powershell
   Get-NetFirewallRule -Name sshd
   ```

### Проблемы с приложением
1. Проверьте логи:
   ```powershell
   docker-compose logs --tail=50
   ```

2. Перезапустите сервисы:
   ```powershell
   docker-compose restart
   ```

## Контакты и поддержка

При возникновении проблем:
1. Проверьте логи приложения
2. Убедитесь, что все сервисы запущены
3. Проверьте настройки API ключей
4. Обратитесь к документации в папке `docs/`
