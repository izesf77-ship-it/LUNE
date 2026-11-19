import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showDeleteConfirmation = false
    @State private var showBiometricError = false
    private let database = DatabaseManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                LuneGradientCard(palette: .rose) {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(ColorTokens.roseDeep)
                        Text("Все данные остаются на этом iPhone")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("Никаких серверов, аккаунтов, аналитики, рекламы и облачной синхронизации. Приложение не содержит сетевых запросов.")
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                LuneCard {
                    LuneSectionHeader(title: "Защита", subtitle: "\(database.totalRecordCount) записей в локальной базе")
                    LuneSettingsRow(
                        icon: "faceid",
                        title: "Аутентификация при запуске",
                        subtitle: BiometricAuth.biometryName,
                        isOn: Binding(
                            get: { appState.profile?.faceIDEnabled ?? false },
                            set: { value in setBiometric(value) }
                        )
                    )
                    LuneSettingsRow(
                        icon: "eye.slash",
                        title: "Скрывать уведомления",
                        subtitle: "Нейтральный текст на экране блокировки",
                        isOn: Binding(
                            get: { appState.profile?.hideNotificationPreviews ?? true },
                            set: { appState.profile?.hideNotificationPreviews = $0; appState.refresh() }
                        )
                    )
                    LuneSettingsRow(
                        icon: "rectangle.on.rectangle",
                        title: "Скрывать в переключателе приложений",
                        subtitle: "Содержимое закрывается при уходе в фон",
                        isOn: Binding(
                            get: { appState.profile?.hideSensitiveOnHome ?? true },
                            set: { appState.profile?.hideSensitiveOnHome = $0; appState.refresh() }
                        )
                    )
                }

                if showBiometricError {
                    Text("Не удалось подтвердить доступ. Настройка не изменена.")
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.warning)
                }

                LuneCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Text("О хранении данных")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("Записи хранятся в локальном хранилище SwiftData с классом защиты до первой разблокировки устройства. Секреты (например, пароль резервной копии) не сохраняются — ключ выводится из введённого пароля при каждом использовании. Мы не заявляем, что вся база зашифрована отдельным ключом приложения.")
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                LuneCard(background: ColorTokens.surfaceSecondary, showShadow: false) {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Text("Удаление данных")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("Действие удаляет всю историю на этом устройстве и не может быть отменено. Перед удалением рекомендуется создать резервную копию.")
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Удалить все данные", systemImage: "trash")
                        }
                        .frame(minHeight: SpacingTokens.touchMinimum)
                    }
                }
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("Приватность")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Удалить все данные?", isPresented: $showDeleteConfirmation) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) { deleteAll() }
        } message: {
            Text("Вся история, настройки и записи будут удалены с этого устройства.")
        }
    }

    private func setBiometric(_ value: Bool) {
        if !value {
            appState.profile?.faceIDEnabled = false
            appState.refresh()
            return
        }
        Task { @MainActor in
            let ok = await BiometricAuth.authenticate(reason: "Включить защиту LUNE")
            if ok {
                appState.profile?.faceIDEnabled = true
                appState.refresh()
            } else {
                showBiometricError = true
            }
        }
    }

    private func deleteAll() {
        database.deleteAllData()
        let newProfile = database.fetchOrCreateProfile()
        newProfile.hasCompletedOnboarding = false
        database.save()
        appState.profile = newProfile
        appState.refresh()
        appState.showToast("Все данные удалены")
    }
}
