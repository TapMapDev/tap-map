# TapMap 🗺️

TapMap - это мобильное приложение на Flutter для интерактивной работы с картами, включающее систему push-уведомлений и аутентификации.

## 🚀 Возможности

- 🔐 Аутентификация пользователей
- 📍 Интерактивная карта с Mapbox
- 🔔 Push-уведомления (Firebase Cloud Messaging)
- 🔄 Автоматическое обновление FCM токена
- 📱 Поддержка iOS и Android
- 🌐 Работа с REST API
- 💾 Локальное хранение данных

## 📋 Требования

- Flutter SDK: последняя стабильная версия
- Dart SDK: последняя стабильная версия
- iOS 11.0 или новее
- Android 5.0 (API 21) или новее
- Firebase проект
- Mapbox API ключ

## 🛠️ Настройка проекта

1. **Клонирование репозитория**
```bash
git clone [URL репозитория]
cd tap_map
```

2. **Установка зависимостей**
```bash
flutter pub get
```

3. **Настройка Firebase**
- Создайте проект в Firebase Console
- Добавьте приложения для Android и iOS
- Скачайте и добавьте конфигурационные файлы:
  - `google-services.json` для Android
  - `GoogleService-Info.plist` для iOS

4. **Настройка переменных окружения**
Создайте файл `.env` в корне проекта:
```env
MAPBOX_ACCESS_TOKEN=ваш_токен_mapbox
API_URL=ваш_базовый_url_api
```

5. **Настройка Android**
- Добавьте иконку уведомлений:
  - Поместите `ic_notification.png` в `android/app/src/main/res/drawable/`

## 🏗️ Архитектура

Проект использует:
- GetIt для внедрения зависимостей
- Dio для работы с сетью
- SharedPreferences для локального хранения
- Firebase Cloud Messaging для push-уведомлений
- flutter_local_notifications для отображения уведомлений

### 📂 Структура проекта

```
lib/
├── core/
│   ├── di/              # Внедрение зависимостей
│   ├── network/         # Сетевой слой
│   ├── services/        # Сервисы
│   └── shared_prefs/    # Хранение данных
├── src/
│   └── features/        # Функциональные модули
└── main.dart
```

### Пример структуры фичи

```
lib/src/features/example/
├── bloc/
├── data/
│   ├── models/
│   └── repositories/
└── ui/
```

В папке `data` обычно располагаются модели и классы репозиториев. На практике название каталога чаще употребляют во множественном числе — `repositories`.


## 🔔 Push-уведомления

Приложение поддерживает:
- Foreground уведомления
- Background уведомления
- Data-only сообщения
- Notification-only сообщения
- Смешанные сообщения

## 🚀 Запуск

```bash
flutter run
```

## 📱 Сборка релиза

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ips --release
```

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для фичи (`git checkout -b feature/amazing_feature`)
3. Зафиксируйте изменения (`git commit -m 'Add amazing feature'`)
4. Отправьте изменения в ветку (`git push origin feature/amazing_feature`)
5. Откройте Pull Request

## 📄 Лицензия

[Укажите тип лицензии]

## 👥 Авторы

Нежный повелитель Артем [Уссури]
Король Нордов Евген [驯蛇师Eugene]
Сладкий отшельник СЕгор [Джафарт]
Хуаранг Славэн [самый сексуальный мужчина]
Марина и Алина

