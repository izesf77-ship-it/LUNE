# LUNÉ

Premium iOS-приложение для отслеживания менструального цикла и планирования беременности.

## Особенности

- ✨ **Два режима**: отслеживание цикла и планирование беременности
- 🔒 **100% приватность**: все данные хранятся локально на устройстве
- 🎨 **Premium UI**: элегантный интерфейс в стиле Soft Rose Luxury
- 📱 **Нативный SwiftUI**: современная разработка для iOS 17+
- 📊 **Аналитика**: визуализация циклов, симптомов и тенденций
- 🌙 **Тёмная тема**: полная поддержка Dark Mode
- ♿️ **Accessibility**: VoiceOver, Dynamic Type, Reduce Motion

## Технологии

- **Platform**: iOS 17+
- **UI Framework**: SwiftUI
- **Database**: SwiftData
- **Target Device**: iPhone 16
- **Language**: Swift 5.9+
- **Build Tool**: Xcode 27

## Структура проекта

```
LUNE/
├── App/                  # Точка входа и главная навигация
├── Core/
│   ├── DesignSystem/     # Токены, компоненты UI
│   ├── Database/         # SwiftData менеджер
│   ├── Models/           # Модели данных
│   ├── Security/         # Шифрование, Face ID
│   ├── Predictions/      # Алгоритмы прогнозирования
│   ├── Recommendations/  # Медицинские рекомендации
│   ├── Notifications/    # Локальные уведомления
│   └── Backup/           # Экспорт и импорт
├── Features/             # Экраны и функции приложения
│   ├── Onboarding/
│   ├── Home/
│   ├── Calendar/
│   ├── Journal/
│   ├── Planning/
│   ├── Analytics/
│   ├── Reports/
│   └── Settings/
├── Resources/            # Ассеты, локализации, контент
└── Tests/                # Unit и Integration тесты
```

## Сборка

### Требования

- macOS с Xcode 15+
- iOS SDK 17+
- GitHub Actions с xcode-27 runner

### Локальная сборка

```bash
# Открыть проект
open LUNE.xcodeproj

# Выбрать iPhone 16 simulator
# Build (⌘B)
# Run (⌘R)
```

### CI/CD

Проект использует GitHub Actions для автоматической сборки unsigned IPA:

```bash
# Push в main запускает workflow
git push origin main

# Артефакт: LUNE-unsigned.ipa
# Скачайте из Actions → Artifacts
```

## Установка IPA

Unsigned IPA можно установить через:

- **Sideloadly** (Windows/macOS)
- **AltStore** (требует AltServer)
- **Xcode** (Devices and Simulators)
- **Apple Configurator** (macOS)

## Приватность

LUNÉ — это полностью офлайн-приложение:

- ❌ Нет серверов
- ❌ Нет аналитики
- ❌ Нет рекламы
- ❌ Нет аккаунтов
- ✅ Все данные хранятся локально в SwiftData
- ✅ Опциональное шифрование с Face ID
- ✅ Безопасный экспорт с паролем

## Лицензия

Все права защищены. Это закрытый проект разработан для личного использования.

## Контакты

Вопросы и предложения: создайте Issue в этом репозитории.

---

**LUNÉ** — забота о женском здоровье с уважением к приватности.
