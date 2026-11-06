# Romance Club

Flutter-клиент обращается к Rust-серверу по gRPC. Только сервер подключается
к SurrealDB, проверяет JWT, права игрока и операции с данными. В приложении
нет SDK SurrealDB и учётных данных БД.

## Локальный сервер

Нужны Flutter/Dart из `pubspec.yaml`, стабильный Rust, `protoc` и SurrealDB 3.
Запустите SurrealDB на **127.0.0.1:8000**, задав свои логин и пароль.
Порт БД не требуется открывать для телефона.

Из каталога `server`:

```sh
cp .env.example .env
# Заполните SURREAL_USER и SURREAL_PASS в .env.
# Для JWT_SECRET сгенерируйте значение командой: openssl rand -hex 32
set -a
source .env
set +a
cargo run --locked
```

`.env` загружается этими командами оболочки и исключён из Git. Сервер требует
непустые учётные данные и JWT-ключ длиной не менее 32 байт без пробелов.
Сначала применяются миграции, затем открывается gRPC. Перед первым запуском
новой версии сделайте резервную копию существующей БД: миграции меняют схему.

`SURREAL_ENDPOINT`, `SURREAL_NAMESPACE`, `SURREAL_DATABASE` задают адрес и базу.
Обычное и ограниченное подключение удаления ассетов используют один endpoint.

## Подключение клиента

Все семь gRPC-сервисов используют общие параметры сборки:

| Параметр | По умолчанию | Значение |
| --- | --- | --- |
| `GRPC_HOST` | `localhost` | Имя или IP сервера без схемы и порта |
| `GRPC_PORT` | `50051` | TCP-порт |
| `GRPC_TLS` | `false` | `true` включает TLS с проверкой сертификата |

Изменение `--dart-define` требует перезапуска сборки, hot reload недостаточен.
Автоопределения эмулятора нет: Android работает и на реальных устройствах.

**Android-эмулятор:** `10.0.2.2` — адрес компьютера со стороны эмулятора.

```sh
flutter run --dart-define=GRPC_HOST=10.0.2.2
```

**Android-телефон через USB:** включите отладку, подключите устройство и
пробросьте порт. Тогда `localhost` телефона ведёт к серверу компьютера:

```sh
adb reverse tcp:50051 tcp:50051
flutter run
```

При нескольких устройствах используйте `adb -s DEVICE_ID reverse ...` и
`flutter run -d DEVICE_ID`. После переподключения проверьте `adb reverse --list`.

**Телефон по Wi-Fi (Android или iOS):** подключите телефон и компьютер к одной
сети, задайте серверу `GRPC_BIND=0.0.0.0:50051`, перезапустите его и укажите
локальный IP компьютера. Разрешите входящий TCP 50051 в firewall компьютера.

```sh
flutter run --dart-define=GRPC_HOST=192.168.1.10
```

На iOS разрешите приложению доступ к локальной сети. `localhost` на реальном
телефоне обозначает сам телефон; без проброса это не адрес компьютера.
Для iOS Simulator и настольного клиента на том же компьютере подходит
обычный `flutter run` с `localhost`.

**Удалённый сервер:** нужен публичный DNS и TLS-прокси с поддержкой HTTP/2
и gRPC перед Rust-сервером. Клиент подключается к этому прокси:

```sh
flutter run --dart-define=GRPC_HOST=game.example.com --dart-define=GRPC_PORT=443 --dart-define=GRPC_TLS=true
```

Rust-сервер в этой конфигурации принимает незашифрованный gRPC во внутренней
сети. Прямой публичный доступ к SurrealDB не нужен. Параметры клиента не
содержат секретов. Нативный gRPC-клиент не поддерживает Flutter Web без
отдельного gRPC-Web транспорта и прокси.

## Проверки

```sh
flutter pub get
flutter analyze
flutter test
cd server
cargo test --locked
```

Интеграционные Rust-тесты помечены `ignored`. Они требуют отдельного тестового
экземпляра SurrealDB на `127.0.0.1:8000`, берут `SURREAL_USER`/`SURREAL_PASS`
из окружения, создают уникальные базы и удаляют их после тестов:

```sh
cargo test --locked -- --ignored --test-threads=1
```

О сетевых адресах: [Android Emulator](https://developer.android.com/studio/run/emulator-networking-address),
[adb reverse](https://developer.android.com/develop/ui/views/layout/webapps/access-local-server),
[параметры сборки Dart](https://dart.dev/libraries/core/environment-declarations).
