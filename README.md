# Боярский Край — landing page

Одностраничный сайт-витрина мясной лавки «Боярский Край» (Химки, ул. Калинина, д. 7).
Статический сайт: HTML + CSS + JavaScript, без сборки и зависимостей.

## Структура

```
BoyarKray/
├── index.html                 # вся разметка страницы
├── css/styles.css             # стили
├── js/main.js                 # меню, аналитика, анимации
├── assets/
│   ├── icons/                 # SVG-иконки
│   └── images/                # изображения (сейчас SVG-заглушки)
├── nginx/
│   └── boyarskiy-kray.conf    # конфиг nginx для сервера
├── deploy/
│   └── setup-server.sh        # первичная настройка Droplet
└── .github/workflows/
    └── deploy.yml             # автодеплой при пуше в main
```

## Локальный просмотр

```powershell
# из папки проекта
python -m http.server 8765
```

Откройте http://127.0.0.1:8765

---

## Деплой: GitHub → DigitalOcean (автоматически при пуше в `main`)

Схема: исходники в GitHub → при пуше в `main` GitHub Actions подключается
к Droplet по SSH и заливает файлы через `rsync`. Сайт раздаёт `nginx`.

### Шаг 1. Создать репозиторий на GitHub и запушить код

```bash
git init
git add .
git commit -m "Initial commit: landing page + deploy"
git branch -M main
git remote add origin https://github.com/<USER>/<REPO>.git
git push -u origin main
```

### Шаг 2. Создать Droplet в DigitalOcean

- Образ: **Ubuntu 24.04 (LTS)**, самый дешёвый тариф подойдёт.
- Добавьте свой личный SSH-ключ при создании (для входа на сервер).
- Запомните **публичный IP** Droplet.

### Шаг 3. Сгенерировать отдельный SSH-ключ для деплоя

На своём компьютере (не на сервере):

```bash
ssh-keygen -t ed25519 -C "deploy@boyarskiy-kray" -f ./deploy_key -N ""
```

Получите два файла:
- `deploy_key` — **приватный** ключ (пойдёт в секрет GitHub `DEPLOY_SSH_KEY`),
- `deploy_key.pub` — **публичный** ключ (пойдёт на сервер).

> Не коммитьте эти файлы — они уже в `.gitignore`.

### Шаг 4. Настроить сервер (один раз)

Зайдите на Droplet под root и выполните:

```bash
ssh root@<IP_DROPLET>

git clone https://github.com/<USER>/<REPO>.git
cd <REPO>

# Вставьте СОДЕРЖИМОЕ файла deploy_key.pub в переменную ниже.
# Домен — необязателен; без него оставьте "_".
DEPLOY_PUBLIC_KEY="ssh-ed25519 AAAA...вставьте_сюда... deploy@boyarskiy-kray" \
  bash deploy/setup-server.sh boyarskiy-kray.ru
```

Скрипт установит nginx, создаст пользователя `deploy`, web-root
`/var/www/boyarskiy-kray`, добавит публичный ключ и поднимет сайт-заглушку.

### Шаг 5. Добавить секреты в GitHub

Репозиторий → **Settings → Secrets and variables → Actions → New repository secret**:

| Секрет           | Значение                                              |
|------------------|-------------------------------------------------------|
| `DEPLOY_HOST`    | IP Droplet (или домен)                                |
| `DEPLOY_USER`    | `deploy`                                              |
| `DEPLOY_PATH`    | `/var/www/boyarskiy-kray`                             |
| `DEPLOY_SSH_KEY` | **всё содержимое** приватного `deploy_key`            |
| `DEPLOY_PORT`    | (необязательно) SSH-порт, если не `22`                |

### Шаг 6. Запустить деплой

Любой пуш в `main` (или ручной запуск: вкладка **Actions → Deploy to DigitalOcean → Run workflow**) выкатит сайт на сервер.

```bash
git commit --allow-empty -m "trigger deploy"
git push
```

---

## Домен и HTTPS

1. В DNS-настройках домена создайте `A`-запись на IP Droplet
   (и при желании `www` → тот же IP).
2. На сервере выпустите бесплатный сертификат Let's Encrypt:

```bash
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d boyarskiy-kray.ru -d www.boyarskiy-kray.ru
```

Certbot сам пропишет HTTPS в конфиг nginx и настроит автопродление.

3. В `index.html` замените плейсхолдер `https://boyarskiy-kray.ru`
   в Open Graph и JSON-LD на ваш реальный домен.

---

## Как работает автодеплой

- `rsync --delete` синхронизирует содержимое репозитория с web-root,
  удаляя на сервере файлы, которых уже нет в репозитории.
- Не выгружаются служебные файлы: `.git`, `.github`, `deploy`, `nginx`,
  `*.md`, `.gitignore` (см. `--exclude` в `.github/workflows/deploy.yml`).
- HTML отдаётся без кэша, ассеты (css/js/картинки) кэшируются на 30 дней.

## Что заменить перед продакшеном

- Реальные фотографии вместо SVG-заглушек в `assets/images/`.
- Реальный логотип `assets/images/logo.svg`.
- Домен в Open Graph / JSON-LD (`index.html`).
- ID Яндекс.Метрики в `js/main.js` (переменная `YANDEX_METRIKA_ID`).
