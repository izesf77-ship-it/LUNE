import SwiftUI

/// Информационный сценарий после положительного домашнего теста.
/// Не меняет режим и не объявляет диагноз.
struct PregnancyObservationView: View {
    @EnvironmentObject private var appState: AppState
    @State private var consentGiven = false

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                LuneGradientCard(palette: .rose) {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(ColorTokens.roseDeep)
                        Text("Вы записали положительный результат")
                            .font(TypographyTokens.titleMedium)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("Это важный сигнал, но домашний тест не заменяет медицинское подтверждение. Запись в приложении не является диагнозом.")
                            .font(TypographyTokens.bodyMedium)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                LuneCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                        Text("Что дальше")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.textPrimary)

                        InfoBullet(
                            symbol: "stethoscope",
                            title: "Обратитесь к врачу",
                            text: "Подтверждение и наблюдение проводит специалист. Запись результата помогает сохранить историю."
                        )
                        InfoBullet(
                            symbol: "calendar.badge.clock",
                            title: "Сохраните дату теста",
                            text: "Она уже записана в истории тестов и доступна в резервной копии."
                        )
                        InfoBullet(
                            symbol: "exclamationmark.triangle",
                            title: "Когда нужна срочная помощь",
                            text: "При сильной боли, обильном кровотечении или головокружении обратитесь за медицинской помощью сразу."
                        )
                    }
                }

                LuneCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                        Text("Отдельное согласие")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Toggle("Сохранить историю и вести наблюдение в приложении", isOn: $consentGiven)
                            .tint(ColorTokens.rosePrimary)
                            .font(TypographyTokens.bodySmall)
                        Text("Мы не изменяем режим автоматически. Приложение по-прежнему не делает выводов о беременности по вашей записи.")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }

                if consentGiven {
                    LunePrimaryButton(title: "Сохранить согласие") {
                        let entries = DatabaseManager.shared.all(PregnancyTestEntry.self)
                        if let latest = entries.filter({ $0.result == .positive }).max(by: { $0.day < $1.day }) {
                            latest.wantsObservationScenario = true
                            latest.touch()
                            DatabaseManager.shared.save()
                            appState.refresh()
                            appState.showToast("Согласие сохранено")
                        }
                    }
                }
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("После теста")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoBullet: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            Image(systemName: symbol)
                .foregroundStyle(ColorTokens.roseDeep)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(TypographyTokens.labelMedium)
                Text(text)
                    .font(TypographyTokens.bodySmall)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }
}

/// Добровольная регистрация близости — только по инициативе пользователя.
struct IntimacyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var day = CalendarDate(Date()).localDate() ?? Date()
    @State private var protection = false
    @State private var note = ""
    private let database = DatabaseManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneCard {
                        VStack(spacing: SpacingTokens.sm) {
                            Text("Эта запись совершенно добровольна")
                                .font(TypographyTokens.titleSmall)
                                .foregroundStyle(ColorTokens.textPrimary)
                            Text("Данные остаются только на устройстве и не используются для автоматических выводов.")
                                .font(TypographyTokens.bodySmall)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .multilineTextAlignment(.center)

                            LuneDatePicker(title: "День", date: $day)
                            Toggle("Использовалась защита", isOn: $protection)
                                .tint(ColorTokens.rosePrimary)
                            LuneTextField(title: "Заметка", placeholder: "Необязательно", text: $note)
                            LunePrimaryButton(title: "Сохранить") {
                                database.insert(IntimacyEntry(
                                    day: CalendarDate(day),
                                    protectionUsed: protection,
                                    notes: note.isEmpty ? nil : note
                                ))
                                database.save()
                                appState.refresh()
                                appState.showToast("Запись сохранена")
                                dismiss()
                            }
                        }
                    }

                    let entries = database.all(IntimacyEntry.self).sorted { $0.day > $1.day }
                    if !entries.isEmpty {
                        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                            LuneSectionHeader(title: "История", subtitle: "\(entries.count) записей")
                            ForEach(entries.prefix(20), id: \.id) { entry in
                                LuneCard {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(entry.day.key)
                                                .font(TypographyTokens.bodyMedium)
                                            Text(entry.protectionUsed ? "Защита использовалась" : "Без защиты")
                                                .font(TypographyTokens.caption)
                                                .foregroundStyle(ColorTokens.textSecondary)
                                        }
                                        Spacer()
                                        Button(role: .destructive) {
                                            database.delete(entry); appState.refresh()
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
            }
            .background(ColorTokens.background)
            .navigationTitle("Близость")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }.foregroundStyle(ColorTokens.roseDeep)
                }
            }
        }
    }
}
