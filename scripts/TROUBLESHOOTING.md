# Устранение проблем настройки сервера

## Проблемы, обнаруженные при установке

### 1. Docker Desktop не установился
**Ошибка**: `The request was aborted: Could not create SSL/TLS secure channel.`

**Решение**:
1. Скачайте Docker Desktop вручную с https://www.docker.com/products/docker-desktop/
2. Установите Docker Desktop
3. Перезапустите компьютер
4. Проверьте установку: `docker --version`

### 2. Пользователь glaz-deploy не создался
**Ошибка**: `Не удается обновить пароль. Введенный пароль не обеспечивает требований домена`

**Решение**:
```powershell
# Создайте пользователя с более сложным паролем
$deployUser = "glaz-deploy"
$deployPassword = "GlazDeploy2024!@#"

New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User"
Add-LocalGroupMember -Group "Администраторы" -Member $deployUser
```

### 3. OpenSSH Server не установился
**Ошибка**: `Имя "Add-WindowsCapability" не распознано`

**Причина**: Windows Server 2012 R2 не поддерживает эту команду

**Решение**:
1. Скачайте OpenSSH Server вручную с https://github.com/PowerShell/Win32-OpenSSH/releases
2. Или используйте скрипт `fix-issues.ps1`

## Быстрое исправление

### Запустите скрипт исправления:
```powershell
.\fix-issues.ps1
```

### Или исправьте вручную:

#### 1. Создание пользователя:
```powershell
$deployUser = "glaz-deploy"
$deployPassword = "GlazDeploy2024!@#"

# Удалить существующего пользователя
Remove-LocalUser -Name $deployUser -ErrorAction SilentlyContinue

# Создать нового пользователя
New-LocalUser -Name $deployUser -Password (ConvertTo-SecureString $deployPassword -AsPlainText -Force) -FullName "Glaz Finance Deploy User"

# Добавить в группу администраторов
Add-LocalGroupMember -Group "Администраторы" -Member $deployUser
```

#### 2. Установка OpenSSH Server:
```powershell
# Скачать OpenSSH
$sshUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.2.0p1-Beta/OpenSSH-Win64.zip"
$sshZip = "$env:TEMP\OpenSSH-Win64.zip"
Invoke-WebRequest -Uri $sshUrl -OutFile $sshZip

# Извлечь и установить
Expand-Archive -Path $sshZip -DestinationPath $env:TEMP -Force
Set-Location "$env:TEMP\OpenSSH-Win64"
.\install-sshd.ps1

# Настроить сервис
Set-Service -Name sshd -StartupType 'Automatic'
Start-Service sshd
```

#### 3. Установка Docker Desktop:
1. Перейдите на https://www.docker.com/products/docker-desktop/
2. Скачайте Docker Desktop для Windows
3. Установите и перезапустите компьютер

## Проверка установки

### Проверьте все компоненты:
```powershell
# Проверка Git
git --version

# Проверка Node.js
node --version

# Проверка Docker
docker --version

# Проверка пользователя
Get-LocalUser -Name "glaz-deploy"

# Проверка SSH
Get-Service sshd

# Проверка портов
netstat -an | findstr :22
```

## Обновленные данные для GitHub Secrets

После исправления используйте:

```
SERVER_USERNAME: glaz-deploy
SERVER_PASSWORD: GlazDeploy2024!@#
SERVER_PORT: 22
```

## Следующие шаги

1. **Исправьте проблемы** с помощью `fix-issues.ps1`
2. **Установите Docker Desktop** вручную
3. **Перезапустите компьютер**
4. **Клонируйте репозиторий**:
   ```powershell
   cd C:\glaz-finance-app
   git clone https://github.com/Progress-collab/glaz-finance-app.git .
   ```
5. **Запустите приложение**:
   ```powershell
   docker-compose up -d
   ```

## Альтернативные решения

### Если OpenSSH не работает:
- Используйте RDP для доступа
- Настройте VPN
- Используйте альтернативные SSH серверы

### Если Docker не работает:
- Используйте виртуальные машины
- Установите Linux на сервер
- Используйте облачные решения

## Контакты

При возникновении проблем:
1. Проверьте логи установки
2. Убедитесь, что все компоненты установлены
3. Обратитесь к документации
