import SwiftUI

struct CycleHomeView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var selectedDay: CalendarDate
    @Binding var showDayDetail: Bool
    @Binding var showPeriodEditor: Bool
    @Binding var showSymptomJournal: Bool
    @Binding var showMoodJournal: Bool
    @Binding var showRecommendations: Bool

    private var prediction: CyclePrediction { appState.prediction }

    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            mainCard
            quickActions
            wellbeingCard
            if let guidance = appState.delayGuidance {
                guidanceCard(guidance)
            }
            insightCard
            calendarLink
        }
        .padding(.horizontal, SpacingTokens.screenHorizontal)
    }

    private var mainCard: some View {
        LuneCard(padding: SpacingTokens.md) {
            HStack(spacing: SpacingTokens.sm) {
                LuneCycleRing(day: prediction.currentDay, total: prediction.cycleLength)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Твой цикл")
                        .font(TypographyTokens.titleSmall)
                        .foregroundStyle(ColorTokens.textPrimary)

                    Text(prediction.shortForecast)
                        .font(TypographyTokens.bodyMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Ориентировочно \(prediction.nextStartRange.lowerBound.key) — \(prediction.nextStartRange.upperBound.key)")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textTertiary)

                    Text(prediction.confidence.displayName)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.roseDeep)
                }
            }

            Divider().padding(.vertical, SpacingTokens.xxs)

            Text(prediction.explanation)
                .font(TypographyTokens.bodySmall)
                .foregroundStyle(ColorTokens.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
            LuneSectionHeader(title: "Добавить запись")

            HStack(spacing: SpacingTokens.sm) {
                QuickAction(title: "Месячные", symbol: "drop.fill", color: ColorTokens.periodActive) {
                    selectedDay = CalendarDate(Date())
                    showPeriodEditor = true
                }
                QuickAction(title: "Симптомы", symbol: "bolt.circle", color: ColorTokens.roseDeep) {
                    selectedDay = CalendarDate(Date())
                    showSymptomJournal = true
                }
                QuickAction(title: "Настроение", symbol: "face.smiling", color: ColorTokens.rosePrimary) {
                    selectedDay = CalendarDate(Date())
                    showMoodJournal = true
                }
                QuickAction(title: "День", symbol: "note.text", color: ColorTokens.lavender) {
                    selectedDay = CalendarDate(Date())
                    showDayDetail = true
                }
            }
        }
    }

    private var wellbeingCard: some View {
        let records = DatabaseManager.shared.records(DailyMoodEntry.self, on: CalendarDate(Date()))
        let symptoms = DatabaseManager.shared.records(DailySymptomEntry.self, on: CalendarDate(Date()))
        return LuneCard {
            HStack(spacing: SpacingTokens.sm) {
                Image(systemName: "heart.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(ColorTokens.roseDeep)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Как ты себя чувствуешь?")
                        .font(TypographyTokens.titleSmall)
                        .foregroundStyle(ColorTokens.textPrimary)
                    if let mood = records.last?.mood.displayName {
                        Text("Сегодня: \(mood) · симптомов: \(symptoms.count)")
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                    } else {
                        Text("Отметьте настроение и симптомы за сегодня")
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showMoodJournal = true
            }
            .accessibilityAddTraits(.isButton)
        }
    }

    private func guidanceCard(_ guidance: MissedPeriodGuidance) -> some View {
        LuneCard(background: ColorTokens.blush.opacity(0.55), showShadow: false) {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(ColorTokens.roseDeep)
                VStack(alignment: .leading, spacing: 6) {
                    Text(guidance.title)
                        .font(TypographyTokens.titleSmall)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(guidance.detail)
                        .font(TypographyTokens.bodyMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                    if let action = guidance.action {
                        Text(action)
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.roseDeep)
                    }
                    Text(guidance.footnote)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
        }
    }

    private var insightCard: some View {
        let items = RecommendationEngine.recommendations(for: appState.recommendationContext)
        return Group {
            if let first = items.first(where: { $0.recommendation.category != .whenToSeeDoctor }) ?? items.first {
                LuneCard {
                    HStack(alignment: .top, spacing: SpacingTokens.sm) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(ColorTokens.rosePrimary)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(first.recommendation.title)
                                .font(TypographyTokens.titleSmall)
                                .foregroundStyle(ColorTokens.textPrimary)
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

    private var calendarLink: some View {
        LuneSecondaryButton(title: "Открыть календарь", icon: "calendar") {
            selectedDay = CalendarDate(Date())
            showDayDetail = true
        }
    }
}

struct QuickAction: View {
    let title: String
    let symbol: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            AnimationTokens.lightHaptic()
            action()
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: symbol).font(.system(size: 23)).foregroundStyle(color))
                Text(title)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 96)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
