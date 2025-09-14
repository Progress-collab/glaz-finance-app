# Скрипт настройки Windows Server 2012 R2 для Glaz Finance App
# Запускать от имени администратора

Write-Host "Настройка Windows Server 2012 R2 для Glaz Finance App..." -ForegroundColor Green

# Проверка прав администратора
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Этот скрипт требует прав администратора!" -ForegroundColor Red
    exit 1
}

# Установка Chocolatey (если не установлен)
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Установка Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Установка необходимых пакетов
Write-Host "Установка необходимых пакетов..." -ForegroundColor Yellow
choco install -y git docker-desktop nodejs postgresql

# Настройка Docker
Write-Host "Настройка Docker..." -ForegroundColor Yellow
# Docker Desktop должен быть запущен
Start-Service docker

# Создание пользователя для деплоя
Write-Host "Создание пользователя для деплоя..." -ForegroundColor Yellow
$deployUser = "glaz-deploy"
$deployPassword = "GlazDeploy2024!"

try {
    New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User" -Description "User for deploying Glaz Finance App"
    Add-LocalGroupMember -Group "Administrators" -Member $deployUser
    Write-Host "Пользователь $deployUser создан с паролем $deployPassword" -ForegroundColor Green
} catch {
    Write-Host "Пользователь уже существует или ошибка создания: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Настройка SSH сервера (OpenSSH)
Write-Host "Настройка SSH сервера..." -ForegroundColor Yellow
# Установка OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Запуск и настройка SSH сервера
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# Настройка firewall для SSH
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Создание директории для приложения
Write-Host "Создание директории приложения..." -ForegroundColor Yellow
$appDir = "C:\glaz-finance-app"
if (!(Test-Path $appDir)) {
    New-Item -ItemType Directory -Path $appDir -Force
    Write-Host "Директория $appDir создана" -ForegroundColor Green
}

# Настройка прав доступа
icacls $appDir /grant "$deployUser:(OI)(CI)F" /T

# Создание файла конфигурации
Write-Host "Создание файла конфигурации..." -ForegroundColor Yellow
$configContent = @"
# Конфигурация Glaz Finance App
SERVER_HOST=YOUR_SERVER_IP
SERVER_USERNAME=$deployUser
SERVER_PASSWORD=$deployPassword
SERVER_PORT=22

# Настройки приложения
APP_PORT=3001
API_PORT=3002
DB_PORT=5432
REDIS_PORT=6379

# Настройки базы данных
DB_NAME=glaz_finance
DB_USER=glaz_user
DB_PASSWORD=glaz_password_2024

# API ключи (заполнить вручную)
OPENWEATHER_API_KEY=
GOOGLE_DRIVE_API_KEY=
GOOGLE_SHEETS_API_KEY=
"@

$configContent | Out-File -FilePath "$appDir\config.env" -Encoding UTF8

Write-Host "Настройка завершена!" -ForegroundColor Green
Write-Host "Следующие шаги:" -ForegroundColor Yellow
Write-Host "1. Заполните API ключи в файле $appDir\config.env" -ForegroundColor White
Write-Host "2. Настройте GitHub Secrets с данными сервера" -ForegroundColor White
Write-Host "3. Запустите приложение командой: docker-compose up -d" -ForegroundColor White
Write-Host "4. Откройте браузер по адресу: http://YOUR_SERVER_IP:3001" -ForegroundColor White

Write-Host "`nДанные для GitHub Secrets:" -ForegroundColor Cyan
Write-Host "SERVER_HOST: YOUR_SERVER_IP" -ForegroundColor White
Write-Host "SERVER_USERNAME: $deployUser" -ForegroundColor White
Write-Host "SERVER_PASSWORD: $deployPassword" -ForegroundColor White
Write-Host "SERVER_PORT: 22" -ForegroundColor White
