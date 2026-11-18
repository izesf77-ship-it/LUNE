import SwiftUI

struct ModeSwitcherView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                LuneCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Text("Один профиль — одна история")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("Переключение режима меняет главный экран, аналитику и доступные действия. Все записи остаются в общей базе и не удаляются.")
                            .font(TypographyTokens.bodyMedium)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                VStack(spacing: SpacingTokens.sm) {
                    ForEach(AppMode.allCases) { mode in
                        Button {
                            guard appState.mode != mode else { return }
                            appState.switchMode(to: mode)
                        } label: {
                            HStack(spacing: SpacingTokens.sm) {
                                Image(systemName: mode.iconName)
                                    .font(.system(size: 28))
                                    .foregroundStyle(ColorTokens.roseDeep)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.displayName)
                                        .font(TypographyTokens.titleSmall)
                                        .foregroundStyle(ColorTokens.textPrimary)
                                    Text(mode.description)
                                        .font(TypographyTokens.bodySmall)
                                        .foregroundStyle(ColorTokens.textSecondary)
                                }
                                Spacer()
                                if appState.mode == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(ColorTokens.roseDeep)
                                }
                            }
                            .padding(SpacingTokens.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: RadiusTokens.md)
                                    .fill(appState.mode == mode ? ColorTokens.blush.opacity(0.6) : ColorTokens.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: RadiusTokens.md)
                                    .stroke(appState.mode == mode ? ColorTokens.rosePrimary : ColorTokens.separator, lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(appState.mode == mode ? [.isSelected] : [])
                    }
                }

                LuneInsightCard(
                    symbol: "info.circle",
                    title: "Безопасное переключение",
                    detail: "Можно переключаться между режимами любое количество раз. Настройки уведомлений, приватности и вся история сохраняются.",
                    caution: "Ни один календарный расчёт не является подтверждением овуляции или беременности."
                )
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("Режим")
        .navigationBarTitleDisplayMode(.inline)
    }
}
