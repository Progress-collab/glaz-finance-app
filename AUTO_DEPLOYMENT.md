# Автоматическое развертывание Glaz Finance App

## 🚀 Варианты автоматического развертывания

### Вариант 1: Полная автоматическая установка (рекомендуется)

**Скрипт**: `scripts/setup-server-auto.ps1`

**Что делает**:
- ✅ Устанавливает Chocolatey, Git, Node.js
- ✅ Создает пользователя glaz-deploy
- ✅ Устанавливает OpenSSH Server
- ✅ **Автоматически устанавливает Docker Desktop** (3 метода)
- ✅ Настраивает firewall и права доступа
- ✅ Создает конфигурационные файлы

**Запуск**:
```powershell
# Скопируйте скрипт на сервер
# Запустите от имени администратора
.\setup-server-auto.ps1
```

### Вариант 2: Установка без Docker (альтернатива)

**Скрипты**: 
- `scripts/setup-server-auto.ps1` (без Docker части)
- `scripts/setup-services.ps1` (PostgreSQL + Redis)

**Что делает**:
- ✅ Устанавливает Node.js, Git
- ✅ Устанавливает PostgreSQL и Redis напрямую
- ✅ Устанавливает PM2 для управления процессами
- ✅ Настраивает базу данных

## 🔧 Методы автоматической установки Docker Desktop

### Метод 1: Chocolatey с принудительной установкой
```powershell
choco install docker-desktop -y --force --ignore-checksums
```

### Метод 2: Прямое скачивание
```powershell
$dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet", "--accept-license" -Wait
```

### Метод 3: Альтернативный URL
```powershell
$altDockerUrl = "https://download.docker.com/win/stable/Docker%20Desktop%20Installer.exe"
# ... аналогично методу 2
```

### Метод 4: Windows Package Manager (winget)
```powershell
winget install Docker.DockerDesktop
```

## 📋 Пошаговая инструкция

### Шаг 1: Подготовка сервера
1. Подключитесь к Windows Server 2012 R2 через RDP
2. Откройте PowerShell от имени администратора
3. Скачайте скрипт `setup-server-auto.ps1`

### Шаг 2: Запуск автоматической установки
```powershell
# Установите политику выполнения
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Запустите скрипт
.\setup-server-auto.ps1
```

### Шаг 3: Перезапуск и проверка
```powershell
# Перезапустите компьютер
Restart-Computer

# После перезапуска проверьте установку
git --version
node --version
docker --version
Get-Service sshd
```

### Шаг 4: Клонирование и запуск
```powershell
# Клонируйте репозиторий
cd C:\glaz-finance-app
git clone https://github.com/Progress-collab/glaz-finance-app.git .

# Запустите приложение
docker-compose up -d
```

## 🔄 GitHub Actions автоматический деплой

### Умный деплой
GitHub Actions автоматически определяет, установлен ли Docker:

- **Если Docker доступен**: использует `docker-compose up -d`
- **Если Docker недоступен**: использует PM2 для Node.js

### Настройка GitHub Secrets
```
SERVER_HOST: YOUR_SERVER_IP
SERVER_USERNAME: glaz-deploy
SERVER_PASSWORD: GlazDeploy2024!@#
SERVER_PORT: 22
```

## 🛠️ Альтернативное развертывание без Docker

### Если Docker не установился:

#### 1. Установите сервисы напрямую:
```powershell
.\setup-services.ps1
```

#### 2. Клонируйте и настройте:
```powershell
cd C:\glaz-finance-app
git clone https://github.com/Progress-collab/glaz-finance-app.git .
npm install
npm run build
```

#### 3. Запустите с PM2:
```powershell
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

## 📊 Мониторинг и управление

### С Docker:
```powershell
# Статус контейнеров
docker-compose ps

# Логи
docker-compose logs

# Перезапуск
docker-compose restart
```

### Без Docker (PM2):
```powershell
# Статус процессов
pm2 status

# Логи
pm2 logs

# Перезапуск
pm2 restart all
```

## 🔍 Устранение проблем

### Docker не установился:
1. Проверьте логи установки
2. Попробуйте установить вручную
3. Используйте альтернативное развертывание

### SSH не работает:
1. Проверьте статус сервиса: `Get-Service sshd`
2. Проверьте firewall: `Get-NetFirewallRule -Name sshd`
3. Перезапустите сервис: `Restart-Service sshd`

### Приложение не запускается:
1. Проверьте логи: `docker-compose logs` или `pm2 logs`
2. Проверьте порты: `netstat -an | findstr :3001`
3. Проверьте конфигурацию

## ✅ Преимущества автоматического развертывания

- **Полная автоматизация**: один скрипт устанавливает все
- **Умный деплой**: GitHub Actions адаптируется к окружению
- **Резервные варианты**: если Docker не работает, используется PM2
- **Мониторинг**: автоматическое резервное копирование
- **Масштабируемость**: легко добавить новые серверы

---

**Готово к автоматическому развертыванию!** 🚀
