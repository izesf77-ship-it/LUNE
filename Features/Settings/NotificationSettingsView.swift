import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var statusText = ""
    @State private var showDeniedAlert = false

    private var profile: UserProfile? { appState.profile }
    private let database = DatabaseManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                LuneCard {
                    LuneSettingsRow(
                        icon: "bell",
                        title: "Локальные напоминания",
                        subtitle: "Только с этого устройства, без push-уведомлений",
                        isOn: Binding(
                            get: { profile?.notificationsEnabled ?? false },
                            set: { value in
                                profile?.notificationsEnabled = value
                                appState.refresh()
                                if value { Task { @MainActor in await enable() } }
                                else { Task { @MainActor in NotificationService.cancelAll() } }
                            }
                        )
                    )
                }

                if !statusText.isEmpty {
                    Text(statusText)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textTertiary)
                }

                settingsGroup("Напоминания") {
                    LuneCard {
                        LuneSettingsRow(
                            icon: "drop.circle",
                            title: "О менструации",
                            subtitle: "За сколько дней до ожидаемой даты",
                            trailing: "\(profile?.periodReminderDaysBefore ?? 2) дн."
                        )
                        Picker("За сколько дней", selection: Binding(
                            get: { profile?.periodReminderDaysBefore ?? 2 },
                            set: { profile?.periodReminderDaysBefore = $0; appState.refresh(); reschedule() }
                        )) {
                            ForEach(0...5, id: \.self) { Text("\($0) дн.").tag($0) }
                        }
                        .pickerStyle(.segmented)

                        LuneSettingsRow(
                            icon: "bolt.circle",
                            title: "Внести симптомы",
                            subtitle: "Ежедневно в выбранное время",
                            isOn: Binding(
                                get: { profile?.symptomReminderEnabled ?? false },
                                set: { profile?.symptomReminderEnabled = $0; appState.refresh(); reschedule() }
                            )
                        )
                        hourPicker(
                            title: "Время напоминания о симптомах",
                            value: Binding(
                                get: { profile?.symptomReminderHour ?? 20 },
                                set: { profile?.symptomReminderHour = $0; appState.refresh(); reschedule() }
                            )
                        )

                        LuneSettingsRow(
                            icon: "testtube.2",
                            title: "ЛГ-тест",
                            subtitle: "Включите, только если делаете тесты",
                            isOn: Binding(
                                get: { profile?.lhTestReminderEnabled ?? false },
                                set: { profile?.lhTestReminderEnabled = $0; appState.refresh(); reschedule() }
                            )
                        )
                        hourPicker(
                            title: "Время напоминания о ЛГ-тесте",
                            value: Binding(
                                get: { profile?.lhTestReminderHour ?? 9 },
                                set: { profile?.lhTestReminderHour = $0; appState.refresh(); reschedule() }
                            )
                        )

                        LuneSettingsRow(
                            icon: "cross.case",
                            title: "Тест на беременность",
                            subtitle: "Включите, только если запланировали тест",
                            isOn: Binding(
                                get: { profile?.pregnancyTestReminderEnabled ?? false },
                                set: { profile?.pregnancyTestReminderEnabled = $0; appState.refresh(); reschedule() }
                            )
                        )
                        hourPicker(
                            title: "Время напоминания о тесте",
                            value: Binding(
                                get: { profile?.pregnancyTestReminderHour ?? 9 },
                                set: { profile?.pregnancyTestReminderHour = $0; appState.refresh(); reschedule() }
                            )
                        )
                    }
                }

                LuneInsightCard(
                    symbol: "eye.slash",
                    title: "Нейтральные уведомления",
                    detail: "Текст на экране блокировки не содержит интимных сведений. Если уведомления запрещены системой, приложение не настаивает.",
                    caution: nil
                )
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("Уведомления")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadStatus() }
        .alert("Разрешение не получено", isPresented: $showDeniedAlert) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("Разрешите уведомления в системных настройках, если хотите получать напоминания.")
        }
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            LuneSectionHeader(title: title)
            content()
        }
    }

    private func hourPicker(title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
            Picker(title, selection: value) {
                ForEach(6...23, id: \.self) { hour in
                    Text(String(format: "%02d:00", hour)).tag(hour)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel(title)
        }
        .padding(.horizontal, SpacingTokens.sm)
    }

    private func loadStatus() async {
        let status = await NotificationService.authorizationStatus()
        switch status {
        case .authorized, .provisional: statusText = "Разрешение получено"
        case .denied: statusText = "Уведомления запрещены в системных настройках"
        case .notDetermined: statusText = "Разрешение не запрошено"
        default: statusText = ""
        }
    }

    private func enable() async {
        let granted = await NotificationService.requestAuthorization()
        if !granted { showDeniedAlert = true }
        await loadStatus()
        reschedule()
    }

    private func reschedule() {
        guard let profile else { return }
        Task { @MainActor in
            await NotificationService.reschedule(
                enabled: profile.notificationsEnabled,
                prediction: appState.prediction,
                periodDaysBefore: profile.periodReminderDaysBefore,
                symptomHour: profile.symptomReminderEnabled ? profile.symptomReminderHour : nil,
                lhHour: profile.lhTestReminderEnabled ? profile.lhTestReminderHour : nil,
                pregnancyHour: profile.pregnancyTestReminderEnabled ? profile.pregnancyTestReminderHour : nil
            )
        }
    }
}
