# Настройка GitHub репозитория

## Шаг 1: Создание репозитория на GitHub

1. Перейдите на [GitHub.com](https://github.com)
2. Войдите в аккаунт `Progress-collab`
3. Нажмите кнопку "New repository" (зеленая кнопка)
4. Заполните данные:
   - **Repository name**: `glaz-finance-app`
   - **Description**: `Семейное веб-приложение для учета финансов с полным управлением счетами, детальной аналитикой по валютам и погодным виджетом`
   - **Visibility**: Public (или Private, если хотите)
   - **Initialize**: НЕ ставьте галочки (у нас уже есть файлы)
5. Нажмите "Create repository"

## Шаг 2: Подключение локального репозитория

После создания репозитория на GitHub, выполните следующие команды:

```bash
# Добавление удаленного репозитория
git remote add origin https://github.com/Progress-collab/glaz-finance-app.git

# Переименование основной ветки в main (если нужно)
git branch -M main

# Отправка кода на GitHub
git push -u origin main
```

## Шаг 3: Настройка GitHub Secrets

1. Перейдите в ваш репозиторий на GitHub
2. Нажмите "Settings" > "Secrets and variables" > "Actions"
3. Нажмите "New repository secret"
4. Добавьте следующие секреты:

### Обязательные секреты:
- `SERVER_HOST` - IP адрес вашего Windows Server
- `SERVER_USERNAME` - `glaz-deploy`
- `SERVER_PASSWORD` - `GlazDeploy2024!`
- `SERVER_PORT` - `22`

### API ключи (добавить после получения):
- `OPENWEATHER_API_KEY` - ключ от OpenWeatherMap
- `GOOGLE_DRIVE_API_KEY` - ключ от Google Drive API
- `GOOGLE_SHEETS_API_KEY` - ключ от Google Sheets API
- `COINGECKO_API_KEY` - ключ от CoinGecko API

## Шаг 4: Проверка настройки

После настройки секретов:
1. Сделайте любой коммит в репозиторий
2. GitHub Actions автоматически запустится
3. Проверьте статус в разделе "Actions" вашего репозитория

## Шаг 5: Настройка автоматических коммитов

Для автоматического сохранения каждые полчаса, добавьте в GitHub Actions:

```yaml
# В .github/workflows/auto-commit.yml
name: Auto Commit
on:
  schedule:
    - cron: '0 */30 * * *'  # Каждые 30 минут
  workflow_dispatch:

jobs:
  auto-commit:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Auto commit
      run: |
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add .
        git commit -m "Auto commit: $(date)" || exit 0
        git push
```

## Полезные ссылки

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub CLI](https://cli.github.com/)

## Следующие шаги

1. Создайте репозиторий на GitHub
2. Выполните команды подключения
3. Настройте секреты
4. Переходите к настройке сервера
