# Скрипты настройки сервера

## Проблема с оригинальным скриптом

Оригинальный скрипт `setup-server.ps1` содержал русские символы, которые вызывали ошибки синтаксиса в PowerShell на Windows Server 2012 R2.

## Исправленные скрипты

### 1. setup-server.ps1 (исправленный)
- Убраны все русские символы
- Заменены на английские комментарии и сообщения
- Исправлены синтаксические ошибки

### 2. setup-server-fixed.ps1 (резервная копия)
- Полная исправленная версия
- Можно использовать как альтернативу

### 3. quick-setup.ps1 (упрощенная версия)
- Быстрая настройка только основных компонентов
- Минимум команд
- Быстрее выполняется

## Как использовать

### Вариант 1: Исправленный скрипт
```powershell
# Скопируйте файл на сервер
# Запустите от имени администратора
.\setup-server.ps1
```

### Вариант 2: Упрощенная версия
```powershell
# Быстрая настройка
.\quick-setup.ps1
```

### Вариант 3: Ручная настройка
Если скрипты не работают, выполните команды вручную:

```powershell
# 1. Установка Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Установка пакетов
choco install -y git docker-desktop nodejs

# 3. Создание пользователя
$deployUser = "glaz-deploy"
$deployPassword = "GlazDeploy2024!"
New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User"
Add-LocalGroupMember -Group "Administrators" -Member $deployUser

# 4. Настройка SSH
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# 5. Создание директории
$appDir = "C:\glaz-finance-app"
New-Item -ItemType Directory -Path $appDir -Force
icacls $appDir /grant "$deployUser:(OI)(CI)F" /T
```

## Проверка установки

После выполнения скрипта проверьте:

```powershell
# Проверка Chocolatey
choco --version

# Проверка Git
git --version

# Проверка Docker
docker --version

# Проверка SSH
Get-Service sshd

# Проверка пользователя
Get-LocalUser -Name "glaz-deploy"
```

## Следующие шаги

1. **Клонирование репозитория**:
   ```powershell
   cd C:\glaz-finance-app
   git clone https://github.com/Progress-collab/glaz-finance-app.git .
   ```

2. **Запуск приложения**:
   ```powershell
   docker-compose up -d
   ```

3. **Проверка работы**:
   - Откройте браузер: `http://YOUR_SERVER_IP:3001`
   - Проверьте логи: `docker-compose logs`

## Устранение проблем

### Если скрипт не запускается:
1. Проверьте права администратора
2. Установите политику выполнения:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### Если пакеты не устанавливаются:
1. Перезапустите PowerShell
2. Проверьте интернет-соединение
3. Попробуйте установить пакеты по отдельности

### Если SSH не работает:
1. Проверьте статус сервиса:
   ```powershell
   Get-Service sshd
   ```
2. Перезапустите сервис:
   ```powershell
   Restart-Service sshd
   ```

## Контакты

При возникновении проблем:
1. Проверьте логи выполнения скрипта
2. Убедитесь, что все команды выполнены успешно
3. Обратитесь к документации в папке `docs/`
