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
├── docker-compose.yml         # nginx-контейнер с сайтом
├── nginx/
│   └── default.conf           # конфиг nginx внутри контейнера
├── deploy/
│   └── setup-docker.sh        # первичная настройка контейнера на сервере
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

## Деплой: GitHub → DigitalOcean (Docker + Traefik)

На сервере уже работает **Traefik** (порты 80/443) и проект bbmarket.live.
Поэтому «Боярский Край» поднимается **отдельным nginx-контейнером** и не мешает
другим проектам.

Схема: исходники в GitHub → при пуше в `main` GitHub Actions заливает статику
по SSH (`rsync`) в папку `site/`, которую раздаёт nginx-контейнер.

- **Сейчас (без домена):** контейнер опубликован на порт `8080` →
  сайт доступен по `http://<IP_СЕРВЕРА>:8080`.
- **Позже (с доменом):** добавляются лейблы Traefik, порт закрывается
  (см. раздел «Домен и HTTPS»).

### Шаг 1. Отдельный SSH-ключ для деплоя

Сгенерируйте пару ключей и добавьте:
- **приватный** ключ → в GitHub-секрет `DEPLOY_SSH_KEY`;
- **публичный** ключ (`.pub`) → в `~/.ssh/authorized_keys` пользователя `deploy`
  на сервере.

### Шаг 2. Настроить контейнер на сервере (один раз)

```bash
ssh root@<IP_DROPLET>

sudo mkdir -p /opt/apps/boyarskiy-kray
sudo git clone https://github.com/IgorPylin/boyarkray.git /opt/apps/boyarskiy-kray
cd /opt/apps/boyarskiy-kray

# создать пользователя deploy (если его ещё нет) и добавить ему публичный ключ:
sudo adduser --disabled-password --gecos "" deploy
sudo install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
echo "ssh-ed25519 AAAA...ваш_публичный_ключ..." | sudo tee -a /home/deploy/.ssh/authorized_keys
sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys

# поднять контейнер
sudo DEPLOY_USER=deploy bash deploy/setup-docker.sh
```

Скрипт создаст `site/`, наполнит её текущим содержимым, откроет порт `8080`
в ufw и запустит контейнер. Сайт станет доступен на `http://<IP>:8080`.

> **DigitalOcean firewall:** если на Droplet включён облачный firewall,
> добавьте inbound-правило **TCP 8080** (публикация Docker-порта может
> не учитывать ufw).

### Шаг 3. Добавить секреты в GitHub

Репозиторий → **Settings → Secrets and variables → Actions → New repository secret**:

| Секрет           | Значение                                              |
|------------------|-------------------------------------------------------|
| `DEPLOY_HOST`    | IP Droplet                                            |
| `DEPLOY_USER`    | `deploy`                                              |
| `DEPLOY_PATH`    | `/opt/apps/boyarskiy-kray/site`                       |
| `DEPLOY_SSH_KEY` | **всё содержимое** приватного ключа                   |
| `DEPLOY_PORT`    | (необязательно) SSH-порт, если не `22`                |

### Шаг 4. Запустить деплой

Пуш в `main` (или **Actions → Deploy to DigitalOcean → Run workflow**) обновит
статику в `site/`. nginx отдаёт новые файлы сразу, без перезапуска контейнера.

```bash
git commit --allow-empty -m "trigger deploy"
git push
```

---

## Домен и HTTPS (когда домен будет готов)

1. Создайте `A`-запись домена на IP Droplet.
2. В `docker-compose.yml` уберите секцию `ports` и раскомментируйте блок Traefik,
   подставив из вашего bbmarket-проекта:
   - имя внешней сети Traefik (`TRAEFIK_NETWORK`);
   - имя certresolver (`RESOLVER_NAME`);
   - нужный домен в `Host(...)`.
3. Пересоздайте контейнер: `docker compose up -d`.
   Traefik сам выпустит сертификат Let's Encrypt — отдельный certbot не нужен.
4. Закройте порт `8080`: `sudo ufw delete allow 8080/tcp` и уберите правило
   из firewall DigitalOcean.
5. В `index.html` замените плейсхолдер `https://boyarskiy-kray.ru`
   в Open Graph и JSON-LD на реальный домен.

---

## Как работает автодеплой

- `rsync --delete` синхронизирует репозиторий с папкой `site/` на сервере,
  удаляя файлы, которых уже нет в репозитории.
- Не выгружаются служебные файлы: `.git`, `.github`, `deploy`, `nginx`, `site`,
  `docker-compose.yml`, `*.md`, `.gitignore`, `.gitattributes`
  (см. `--exclude` в `.github/workflows/deploy.yml`).
- HTML отдаётся без кэша, ассеты (css/js/картинки) кэшируются на 30 дней.

## Что заменить перед продакшеном

- Реальные фотографии вместо SVG-заглушек в `assets/images/`.
- Реальный логотип `assets/images/logo.svg`.
- Домен в Open Graph / JSON-LD (`index.html`).
- ID Яндекс.Метрики в `js/main.js` (переменная `YANDEX_METRIKA_ID`).
