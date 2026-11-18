import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                VStack(spacing: SpacingTokens.xs) {
                    ZStack {
                        Circle().fill(LinearGradient(colors: [ColorTokens.rosePrimary, ColorTokens.blush],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                        Image(systemName: "sparkles")
                            .font(.system(size: 34))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 84, height: 84)

                    Text("LUNÉ")
                        .font(TypographyTokens.displayLarge)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text("\(LuneAppVersion.displayText) · iOS 17+")
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                LuneCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Text("О приложении")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("LUNÉ — офлайн-приложение для наблюдения за менструальным циклом и планирования беременности. Оно помогает вести дневник, видеть ориентировочные даты и сохранять историю на вашем iPhone.")
                            .font(TypographyTokens.bodyMedium)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                LuneCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Text("Принципы")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.textPrimary)
                        ForEach([
                            "Без интернета, аккаунта и аналитики",
                            "Данные не покидают устройство",
                            "Прогноз — оценка, а не диагноз",
                            "Никаких безопасных дней и медицинских выводов по календарю",
                            "Решение о наблюдении беременности — только за вами"
                        ], id: \.self) { line in
                            HStack(alignment: .top, spacing: SpacingTokens.xxs) {
                                Text("•").foregroundStyle(ColorTokens.roseDeep)
                                Text(line)
                                    .font(TypographyTokens.bodySmall)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            }
                        }
                    }
                }

                LuneInsightCard(
                    symbol: "stethoscope",
                    title: "Медицинская ответственность",
                    detail: "Материалы справочника носят информационный характер. LUNÉ не ставит диагнозов, не назначает препараты и не заменяет консультацию врача.",
                    caution: "При выраженных симптомах обратитесь за медицинской помощью."
                )
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("О LUNÉ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
