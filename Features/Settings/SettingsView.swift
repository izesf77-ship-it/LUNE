import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneCard {
                        LuneSectionHeader(title: "LUNÉ", subtitle: "Ваше пространство — только на этом iPhone")
                        HStack(spacing: SpacingTokens.sm) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 28))
                                .foregroundStyle(ColorTokens.roseDeep)
                            VStack(alignment: .leading) {
                                Text(appState.mode.displayName)
                                    .font(TypographyTokens.titleSmall)
                                Text("История сохраняется при смене режима")
                                    .font(TypographyTokens.caption)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            }
                        }
                    }

                    settingsGroup("Приложение") {
                        NavigationLink { ModeSwitcherView() } label: {
                            LuneSettingsRow(icon: "arrow.left.arrow.right", title: "Режим приложения", trailing: appState.mode.shortName)
                        }
                        NavigationLink { NotificationSettingsView() } label: {
                            LuneSettingsRow(icon: "bell", title: "Уведомления")
                        }
                        NavigationLink { PrivacySettingsView() } label: {
                            LuneSettingsRow(icon: "lock.shield", title: "Приватность и безопасность")
                        }
                    }

                    settingsGroup("Данные") {
                        NavigationLink { BackupSettingsView() } label: {
                            LuneSettingsRow(icon: "externaldrive", title: "Резервные копии и экспорт")
                        }
                        NavigationLink { ReportsView() } label: {
                            LuneSettingsRow(icon: "doc.text", title: "PDF-отчёты")
                        }
                        NavigationLink { MedicalLibraryView() } label: {
                            LuneSettingsRow(icon: "book.closed", title: "Медицинский справочник")
                        }
                        NavigationLink { RecommendationsView() } label: {
                            LuneSettingsRow(icon: "lightbulb", title: "Рекомендации")
                        }
                    }

                    settingsGroup("Интерфейс") {
                        LuneCard {
                            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                                Text("Внешний вид")
                                    .font(TypographyTokens.labelMedium)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                LuneSegmentedControl(
                                    options: AppearanceOption.allCases,
                                    selection: Binding(
                                        get: { AppearanceOption(rawValue: appState.appearance) ?? .system },
                                        set: { appState.appearance = $0.rawValue }
                                    )
                                ) { $0.title }
                            }
                        }
                    }

                    settingsGroup("Информация") {
                        NavigationLink { AboutView() } label: {
                            LuneSettingsRow(icon: "info.circle", title: "О LUNÉ")
                        }
                    }

                    Text("Версия 1.0 · без интернета, аккаунта и аналитики")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, SpacingTokens.sm)
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.vertical, SpacingTokens.xs)
            }
            .background(ColorTokens.background)
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            LuneSectionHeader(title: title)
            LuneCard(padding: SpacingTokens.xs) { content() }
        }
    }
}

enum AppearanceOption: Int, Identifiable, CaseIterable, Hashable {
    case system = 0, light = 1, dark = 2
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .system: return "Системная"
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }
}
