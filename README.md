# Клуб Романтики

Я делаю мобильную визуальную новеллу на Dart и Flutter. В игре можно читать эпизоды, выбирать действия персонажей и сохранять прогресс. Также есть регистрация, профиль и редактор эпизодов.

Клиент у меня написан на Flutter, сервер — на Rust, а данные хранятся в SurrealDB. Для запросов между приложением и сервером использую gRPC и Protobuf.

## Как устроен проект

Экраны приложения лежат в `lib/screens`. В `lib/src/domain` находятся модели и интерфейсы репозиториев, а в `lib/src/data` — работа с сервером. Логику прохождения и переходов между сценами я вынесла в `lib/src/features/game`.

В `lib/services/storage_service.dart` храню локальные настройки и данные входа. Файлы в `lib/generated` получены из Protobuf-контрактов из папки `protos`.

Код сервера находится в `server/src`. В `server/migrations` описаны таблицы базы, а в `assets` лежат локальные картинки.

## Как приходят данные

Приложение обращается к серверу на порту `50051`. Сервер подключается к SurrealDB по адресу `127.0.0.1:8000/rpc`. Использую namespace `romance_club` и database `main`.

Когда игрок открывает эпизод, приложение отправляет запрос `GetEpisode`. Сервер читает из базы эпизод, его сцены, выборы и действия, собирает ответ и отправляет его клиенту. После этого приложение показывает сюжет.

## Как я запускаю проект

Сначала открываю PowerShell в папке проекта и запускаю базу:

```powershell
surreal start --user root --pass root --bind 127.0.0.1:8000 surrealkv://database
```

Это окно оставляю открытым. В другом окне запускаю сервер:

```powershell
cd C:\flutter_projects\romance_club\server
$env:SURREAL_NAMESPACE = 'romance_club'
$env:SURREAL_DATABASE = 'main'
$env:GRPC_BIND = '0.0.0.0:50051'
$env:JWT_SECRET = (Get-Content ..\.local\jwt-secret.txt -Raw).Trim()
cargo run
```

Если сервер уже собран, могу запустить `start-server.cmd` из корня проекта.

Затем запускаю Android-эмулятор, жду домашний экран и открываю приложение через F5 в VS Code. Через терминал из корня проекта запуск такой:

```powershell
flutter pub get
flutter run
```

В клиенте указан адрес `10.0.2.2` — через него Android-эмулятор обращается к моему компьютеру. При запуске на телефоне нужен адрес компьютера в локальной сети.

## Что нужно для сборки

Для клиента нужны Flutter и Android SDK. Для сервера — Rust, MSVC и компилятор Protobuf `protoc`. Версия Rust указана в `server/rust-toolchain.toml`. Сейчас использую SurrealDB 3.3.0 и Dart 3.13.2.

Миграции создают таблицы, но не добавляют сюжет. На другом компьютере данные загружаются из SQL-выгрузки SurrealDB с расширением `.surql` через команду `surreal import`.

## Ключ для токенов

JWT_SECRET передаю серверу через окружение. Ключ должен быть случайным, не короче 32 байт и без пробелов. Без него сервер не запускается. Ключ не добавляю в Git и не включаю в архив для сдачи.

На новом компьютере создаю отдельный локальный ключ из корня проекта:

```powershell
New-Item -ItemType Directory -Force .local | Out-Null
$jwtBytes = New-Object byte[] 32
$jwtRandom = [Security.Cryptography.RandomNumberGenerator]::Create()
$jwtRandom.GetBytes($jwtBytes)
$jwtRandom.Dispose()
$jwtSecret = [BitConverter]::ToString($jwtBytes).Replace('-', '').ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path (Get-Location) '.local\jwt-secret.txt'), $jwtSecret)
```

start-server.cmd читает этот файл, если JWT_SECRET ещё не задан в окружении. При замене ключа старые токены перестают работать, нужно войти в приложение заново. Аккаунты и прогресс остаются в базе.