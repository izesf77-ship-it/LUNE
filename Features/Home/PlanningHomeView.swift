import SwiftUI
import Charts

struct PlanningHomeView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var showLHEditor: Bool
    @Binding var showPregnancyEditor: Bool
    @Binding var showTemperature: Bool
    @Binding var showMucus: Bool
    @Binding var showRecommendations: Bool

    private var snapshot: FertilitySnapshot { appState.fertilitySnapshot }
    private var database: DatabaseManager { DatabaseManager.shared }

    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            centralCard
            testActions
            temperatureCard
            insightCard
            disclaimer
        }
        .padding(.horizontal, SpacingTokens.screenHorizontal)
    }

    private var centralCard: some View {
        LuneCard(padding: SpacingTokens.md) {
            HStack {
                Label("Планирование беременности", systemImage: "heart.circle.fill")
                    .font(TypographyTokens.titleSmall)
                    .foregroundStyle(ColorTokens.roseDeep)
                Spacer()
            }

            HStack(spacing: SpacingTokens.md) {
                ZStack {
                    Circle()
                        .fill(ColorTokens.lavender.opacity(0.55))
                        .frame(width: 104, height: 104)
                    Image(systemName: "sparkles")
                        .font(.system(size: 34))
                        .foregroundStyle(ColorTokens.roseDeep)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Ориентировочное фертильное окно")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                    Text("\(snapshot.fertileWindow.lowerBound.key) — \(snapshot.fertileWindow.upperBound.key)")
                        .font(TypographyTokens.labelLarge)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text("Ориентировочная овуляция: \(snapshot.estimatedOvulationDay.key)")
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                    Text(snapshot.daysUntilEstimatedOvulation > 0
                         ? "Через \(snapshot.daysUntilEstimatedOvulation) \(RussianPlural.days(snapshot.daysUntilEstimatedOvulation)) до ориентировочной даты"
                         : "Ориентировочная дата близко или прошла")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.roseDeep)
                }
            }
            .padding(.top, SpacingTokens.xxs)

            Text("Календарная оценка не подтверждает овуляцию и не является способом предотвращения беременности.")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textTertiary)
                .padding(.top, SpacingTokens.xxs)
        }
    }

    private var testActions: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
            LuneSectionHeader(title: "Наблюдения и тесты")
            HStack(spacing: SpacingTokens.sm) {
                QuickAction(title: "ЛГ-тест", symbol: "testtube.2", color: ColorTokens.lavender) {
                    showLHEditor = true
                }
                QuickAction(title: "Тест на беременность", symbol: "cross.case", color: ColorTokens.rosePrimary) {
                    showPregnancyEditor = true
                }
                QuickAction(title: "Температура", symbol: "thermometer", color: ColorTokens.roseDeep) {
                    showTemperature = true
                }
                QuickAction(title: "Слизь", symbol: "drop", color: ColorTokens.fertilityWindow) {
                    showMucus = true
                }
            }
        }
    }

    private var temperatureCard: some View {
        let entries = database.all(BasalTemperatureEntry.self)
            .sorted { $0.day < $1.day }
            .suffix(14)

        return Group {
            if entries.isEmpty {
                LuneCard {
                    LuneEmptyState(
                        symbol: "thermometer",
                        title: "Температурный график пока пуст",
                        message: "Измерения помогают заметить личную закономерность задним числом.",
                        actionTitle: "Добавить измерение"
                    ) {
                        showTemperature = true
                    }
                }
            } else {
                LuneCard {
                    LuneSectionHeader(title: "Базальная температура", subtitle: snapshot.temperatureTrend.displayName)
                    Chart(entries) { entry in
                        LineMark(
                            x: .value("День", entry.day.key),
                            y: .value("°C", entry.celsius)
                        )
                        .foregroundStyle(ColorTokens.roseDeep)
                        .symbol(Circle())
                    }
                    .chartYScale(domain: 35.8...37.6)
                    .frame(height: 120)
                    .accessibilityLabel("График базальной температуры")
                }
            }
        }
    }

    private var insightCard: some View {
        let items = RecommendationEngine.recommendations(for: appState.recommendationContext)
        return Group {
            if let first = items.first {
                LuneCard {
                    HStack(alignment: .top, spacing: SpacingTokens.sm) {
                        Image(systemName: "book.closed")
                            .foregroundStyle(ColorTokens.roseDeep)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(first.recommendation.title)
                                .font(TypographyTokens.titleSmall)
                            Text(first.recommendation.text)
                                .font(TypographyTokens.bodySmall)
                                .foregroundStyle(ColorTokens.textSecondary)
                            Button("Все рекомендации") { showRecommendations = true }
                                .font(TypographyTokens.labelMedium)
                                .foregroundStyle(ColorTokens.roseDeep)
                                .frame(minHeight: SpacingTokens.touchMinimum)
                        }
                    }
                }
            }
        }
    }

    private var disclaimer: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(snapshot.disclaimers, id: \.self) { text in
                HStack(alignment: .top, spacing: 6) {
                    Text("•").foregroundStyle(ColorTokens.roseDeep)
                    Text(text)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
