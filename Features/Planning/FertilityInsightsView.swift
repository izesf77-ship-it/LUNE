import SwiftUI
import Charts

struct FertilityInsightsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showLHEditor = false
    @State private var showTemperature = false
    @State private var showMucus = false
    @State private var showIntimacy = false
    @State private var showObservation = false

    private var snapshot: FertilitySnapshot { appState.fertilitySnapshot }
    private let database = DatabaseManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                summaryCard
                observationSection
                temperatureSection
                lhSection
                mucusSection
                disclaimerCard
                actions
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("Планирование")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLHEditor) { LHTestEditorView(day: CalendarDate(Date())) }
        .sheet(isPresented: $showTemperature) { BasalTemperatureView() }
        .sheet(isPresented: $showMucus) { CervicalMucusView(day: CalendarDate(Date())) }
        .sheet(isPresented: $showIntimacy) { IntimacyView() }
        .navigationDestination(isPresented: $showObservation) { PregnancyObservationView() }
    }

    private var summaryCard: some View {
        LuneGradientCard(palette: .lavender) {
            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                Label("Ориентировочное фертильное окно", systemImage: "sparkles")
                    .font(TypographyTokens.titleSmall)
                    .foregroundStyle(ColorTokens.roseDeep)
                Text("\(snapshot.fertileWindow.lowerBound.key) — \(snapshot.fertileWindow.upperBound.key)")
                    .font(TypographyTokens.numberMedium)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text("Ориентировочная овуляция: \(snapshot.estimatedOvulationDay.key)")
                    .font(TypographyTokens.bodyMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
                Text(appState.prediction.explanation)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }

    private var observationSection: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            LuneSectionHeader(title: "Наблюдения и оценки")
            ForEach(snapshot.insights) { insight in
                LuneInsightCard(
                    symbol: insight.kind == .observedSign ? "eye" : (insight.kind == .calendarEstimate ? "calendar" : "questionmark.circle"),
                    title: insight.title,
                    detail: insight.detail,
                    caution: insight.caution,
                    tint: insight.kind == .observedSign ? ColorTokens.blush : ColorTokens.lavender
                )
            }
        }
    }

    private var temperatureSection: some View {
        let entries = database.all(BasalTemperatureEntry.self).sorted { $0.day < $1.day }
        return LuneCard {
            LuneSectionHeader(
                title: "Базальная температура",
                subtitle: snapshot.temperatureTrend.displayName
            )
            if entries.isEmpty {
                LuneEmptyState(
                    symbol: "thermometer",
                    title: "Нет измерений",
                    message: "График помогает заметить закономерность только задним числом."
                )
            } else {
                Chart(entries.suffix(30)) { entry in
                    LineMark(
                        x: .value("День", entry.day.key),
                        y: .value("°C", entry.celsius)
                    )
                    .foregroundStyle(ColorTokens.roseDeep)
                    .symbol(Circle())
                }
                .chartYScale(domain: 35.5...38.0)
                .frame(height: 160)
            }
        }
    }

    private var lhSection: some View {
        let tests = database.all(LHTestEntry.self).sorted { $0.day < $1.day }
        return LuneCard {
            LuneSectionHeader(title: "ЛГ-тесты", subtitle: tests.isEmpty ? nil : "\(tests.count) записано")
            if tests.isEmpty {
                LuneEmptyState(symbol: "testtube.2", title: "Тестов пока нет", message: "Запишите результат, чтобы видеть историю.")
            } else {
                ForEach(tests.suffix(8).reversed(), id: \.id) { test in
                    HStack {
                        Image(systemName: test.result.symbolName)
                            .foregroundStyle(test.result == .positive ? ColorTokens.success : ColorTokens.textSecondary)
                        Text(test.day.key)
                            .font(TypographyTokens.bodyMedium)
                        Spacer()
                        Text(test.result.displayName)
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    .frame(minHeight: 36)
                }
            }
        }
    }

    private var mucusSection: some View {
        let entries = database.all(CervicalMucusEntry.self).sorted { $0.day > $1.day }
        return Group {
            if !entries.isEmpty {
                LuneCard {
                    LuneSectionHeader(title: "Цервикальная слизь")
                    ForEach(entries.prefix(5), id: \.id) { entry in
                        HStack {
                            Text(entry.day.key)
                                .font(TypographyTokens.bodySmall)
                                .foregroundStyle(ColorTokens.textSecondary)
                            Spacer()
                            Text(entry.type.displayName)
                                .font(TypographyTokens.bodyMedium)
                        }
                        .frame(minHeight: 32)
                    }
                }
            }
        }
    }

    private var disclaimerCard: some View {
        LuneCard(background: ColorTokens.blush.opacity(0.45), showShadow: false) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Важно", systemImage: "info.circle.fill")
                    .font(TypographyTokens.labelMedium)
                    .foregroundStyle(ColorTokens.roseDeep)
                ForEach(snapshot.disclaimers, id: \.self) { text in
                    Text("• \(text)")
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Button("После положительного теста") { showObservation = true }
                    .font(TypographyTokens.labelMedium)
                    .foregroundStyle(ColorTokens.roseDeep)
                    .frame(minHeight: SpacingTokens.touchMinimum)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: SpacingTokens.xs) {
            LuneSecondaryButton(title: "Записать ЛГ-тест", icon: "testtube.2") { showLHEditor = true }
            LuneSecondaryButton(title: "Измерить температуру", icon: "thermometer") { showTemperature = true }
            LuneSecondaryButton(title: "Отметить слизь", icon: "drop") { showMucus = true }
            LuneSecondaryButton(title: "Отметить близость", icon: "heart") { showIntimacy = true }
        }
    }
}
