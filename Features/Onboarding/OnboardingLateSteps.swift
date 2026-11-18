import SwiftUI

struct PeriodDurationStep: View {
    @Binding var duration: Int?
    let next: () -> Void

    private let options = [2, 3, 4, 5, 6, 7, 8]

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            Text("Если знаете, сколько обычно длится кровотечение — выберите. Это поможет точнее оценить ближайшие даты.")
                .font(TypographyTokens.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 76), spacing: SpacingTokens.xs)],
                spacing: SpacingTokens.xs
            ) {
                ForEach(options, id: \.self) { value in
                    LuneSelectableChip(title: "\(value) дн.", isSelected: duration == value) {
                        duration = duration == value ? nil : value
                    }
                }
            }

            Button("Не знаю") { duration = nil; next() }
                .font(TypographyTokens.labelMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(minHeight: SpacingTokens.touchMinimum)

            LunePrimaryButton(title: duration == nil ? "Пропустить" : "Продолжить", action: next)
        }
    }
}

struct HistoryStep: View {
    @Binding var dates: [Date]
    let next: () -> Void
    @State private var newDate = Date()

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            Text("Можно добавить даты начала предыдущих менструаций. Это необязательно — данные всегда можно внести позже.")
                .font(TypographyTokens.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)

            LuneDatePicker(title: "Дата начала", date: $newDate)

            LuneSecondaryButton(title: "Добавить дату", icon: "plus") {
                let day = CalendarDate(newDate)
                guard !dates.contains(where: { CalendarDate($0) == day }) else { return }
                dates.append(newDate)
                dates.sort(by: >)
                AnimationTokens.successHaptic()
            }

            if dates.isEmpty {
                LuneEmptyState(
                    symbol: "calendar.badge.plus",
                    title: "Пока пусто",
                    message: "Добавьте даты, если помните их. Или пропустите этот шаг."
                )
            } else {
                List {
                    ForEach(dates, id: \.self) { date in
                        HStack {
                            Image(systemName: "drop.circle")
                                .foregroundStyle(ColorTokens.rosePrimary)
                            Text(CalendarDate(date).key)
                                .font(TypographyTokens.bodyLarge)
                            Spacer()
                            Button(role: .destructive) {
                                dates.removeAll { $0 == date }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .frame(minWidth: SpacingTokens.touchMinimum, minHeight: SpacingTokens.touchMinimum)
                        }
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 220)
            }

            LunePrimaryButton(title: dates.isEmpty ? "Пропустить" : "Продолжить", action: next)
        }
    }
}

struct NotificationsStep: View {
    @Binding var isOn: Bool
    let next: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            Image(systemName: "bell.badge")
                .font(.system(size: 44))
                .foregroundStyle(ColorTokens.rosePrimary)

            Text("Мягкие напоминания")
                .font(TypographyTokens.titleMedium)
                .foregroundStyle(ColorTokens.textPrimary)

            Text("Напоминания приходят только с этого устройства. Текст на экране блокировки намеренно нейтральный — он не раскрывает личную информацию.")
                .font(TypographyTokens.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)

            LuneCard {
                LuneSettingsRow(
                    icon: "bell",
                    title: "Включить напоминания",
                    subtitle: "Настроить время можно в настройках",
                    isOn: $isOn
                )
            }

            LunePrimaryButton(title: "Продолжить") {
                if isOn {
                    Task { @MainActor in _ = await NotificationService.requestAuthorization() }
                }
                next()
            }
        }
    }
}

struct BiometricStep: View {
    @Binding var isOn: Bool
    let next: () -> Void
    @State private var showWarning = false

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            Image(systemName: "faceid")
                .font(.system(size: 46))
                .foregroundStyle(ColorTokens.rosePrimary)

            Text("Защита \(BiometricAuth.biometryName)")
                .font(TypographyTokens.titleMedium)
                .foregroundStyle(ColorTokens.textPrimary)

            Text("При желании приложение будет запрашивать аутентификацию владельца устройства при каждом запуске.")
                .font(TypographyTokens.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)

            if !BiometricAuth.isAvailable() {
                Text("На этом устройстве аутентификация недоступна — приложение будет работать без неё.")
                    .font(TypographyTokens.bodySmall)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .multilineTextAlignment(.center)
            }

            LuneCard {
                LuneSettingsRow(
                    icon: "lock.shield",
                    title: "Запрашивать \(BiometricAuth.biometryName)",
                    subtitle: "Можно изменить в настройках",
                    isOn: $isOn
                )
            }

            if showWarning {
                Text("Подтверждение не пройдено — защита не включена.")
                    .font(TypographyTokens.bodySmall)
                    .foregroundStyle(ColorTokens.warning)
            }

            LunePrimaryButton(title: "Продолжить") {
                if isOn {
                    Task { @MainActor in
                        let ok = await BiometricAuth.authenticate(reason: "Включить защиту данных LUNÉ")
                        if ok { next() } else { isOn = false; showWarning = true }
                    }
                } else {
                    next()
                }
            }
        }
    }
}

struct FinishStep: View {
    let isSaving: Bool
    let finish: () -> Void

    var body: some View {
        OnboardingStepShell(
            symbol: "checkmark.circle.fill",
            title: "Всё готово",
            message: "LUNÉ настроен. Вы в любой момент сможете изменить режим, напоминания и уровень приватности в настройках.",
            buttonTitle: "Открыть LUNÉ",
            content: {
                VStack(spacing: SpacingTokens.xxs) {
                    Label("Все данные остаются на этом iPhone", systemImage: "iphone")
                    Label("Без интернета, аккаунта и аналитики", systemImage: "wifi.slash")
                    Label("Прогноз — оценка, а не диагноз", systemImage: "info.circle")
                }
                .font(TypographyTokens.bodySmall)
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            },
            next: finish
        )
    }
}
