import SwiftUI
import Charts

enum AnalyticsTab: String, Identifiable, CaseIterable, Hashable {
    case cycle, symptoms, observations
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cycle: return "Цикл"
        case .symptoms: return "Симптомы"
        case .observations: return "Наблюдения"
        }
    }
}

struct AnalyticsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var tab: AnalyticsTab = .cycle
    @State private var showHistory = false

    private let database = DatabaseManager.shared
    private var prediction: CyclePrediction { appState.prediction }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneSegmentedControl(options: AnalyticsTab.allCases, selection: $tab) { $0.title }

                    switch tab {
                    case .cycle: cycleSection
                    case .symptoms: symptomsSection
                    case .observations: observationsSection
                    }
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.vertical, SpacingTokens.xs)
            }
            .background(ColorTokens.background)
            .navigationTitle("Аналитика")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showHistory) { HistoricalCyclesView() }
        }
    }

    // MARK: - Cycle

    private var cycleSection: some View {
        let intervals = cycleIntervals()
        return VStack(spacing: SpacingTokens.md) {
            HStack(spacing: SpacingTokens.sm) {
                Metric(title: "Медиана", value: "\(prediction.cycleLength) дн.")
                Metric(title: "Разброс", value: "\(prediction.cycleLengthSpread) дн.")
                Metric(title: "Циклов", value: "\(prediction.sampleCount)")
            }

            LuneCard {
                LuneSectionHeader(title: "Длительность циклов", subtitle: prediction.explanation)
                if intervals.isEmpty {
                    LuneEmptyState(
                        symbol: "chart.bar",
                        title: "Пока нечего показывать",
                        message: "Запишите даты нескольких менструаций, чтобы увидеть график."
                    )
                } else {
                    Chart(intervals, id: \.self) { value in
                        BarMark(
                            x: .value("Цикл", "\(value) дн."),
                            y: .value("Дней", value)
                        )
                        .foregroundStyle(ColorTokens.rosePrimary)
                        .cornerRadius(6)
                    }
                    .chartYScale(domain: 0...max(40, (intervals.max() ?? 28) + 5))
                    .frame(height: 190)
                    .accessibilityLabel("График длительности циклов")
                }
            }

            LuneInsightCard(
                symbol: "info.circle",
                title: "Как читать график",
                detail: "Показываются только интервалы между подтверждёнными датами начала менструаций. Слишком короткие и слишком длинные интервалы исключаются как вероятные ошибки записи.",
                caution: "График не является медицинским диагнозом."
            )

            LuneSecondaryButton(title: "История циклов", icon: "clock") { showHistory = true }
        }
    }

    private var symptomsSection: some View {
        let counts = symptomCounts()
        return LuneCard {
            LuneSectionHeader(title: "Частота симптомов", subtitle: "По всем записям дневника")
            if counts.isEmpty {
                LuneEmptyState(
                    symbol: "chart.bar.xaxis",
                    title: "Симптомы не записаны",
                    message: "Отмечайте симптомы в дневнике, чтобы увидеть частоту."
                )
            } else {
                Chart(counts) { item in
                    BarMark(
                        x: .value("Количество", item.count),
                        y: .value("Симптом", item.name)
                    )
                    .foregroundStyle(ColorTokens.rosePrimary)
                    .cornerRadius(6)
                }
                .frame(height: CGFloat(max(180, counts.count * 34)))
                .accessibilityLabel("График частоты симптомов")
            }
        }
    }

    private var observationsSection: some View {
        let temperatures = database.all(BasalTemperatureEntry.self).sorted { $0.day < $1.day }
        let lh = database.all(LHTestEntry.self).sorted { $0.day < $1.day }
        let pregnancy = database.all(PregnancyTestEntry.self).sorted { $0.day < $1.day }

        return VStack(spacing: SpacingTokens.md) {
            LuneCard {
                LuneSectionHeader(title: "Базальная температура")
                if temperatures.isEmpty {
                    LuneEmptyState(symbol: "thermometer", title: "Нет измерений", message: "График появится после первых записей.")
                } else {
                    Chart(temperatures.suffix(30)) { entry in
                        LineMark(x: .value("День", entry.day.key), y: .value("°C", entry.celsius))
                            .foregroundStyle(ColorTokens.roseDeep)
                            .symbol(Circle())
                    }
                    .chartYScale(domain: 35.5...38.0)
                    .frame(height: 170)
                }
            }

            LuneCard {
                LuneSectionHeader(title: "ЛГ-тесты", subtitle: "\(lh.count) записано")
                if lh.isEmpty {
                    LuneEmptyState(symbol: "testtube.2", title: "Тестов пока нет", message: "Результаты появятся здесь.")
                } else {
                    Chart(lh) { test in
                        BarMark(
                            x: .value("День", test.day.key),
                            y: .value("Результат", test.result == .positive ? 1 : 0)
                        )
                        .foregroundStyle(test.result == .positive ? ColorTokens.roseDeep : ColorTokens.fertilityWindow)
                    }
                    .chartYAxis {
                        AxisMarks(values: [0, 1]) { value in
                            AxisValueLabel {
                                if value.as(Int.self) == 1 { Text("+") } else { Text("−") }
                            }
                        }
                    }
                    .frame(height: 120)
                }
            }

            LuneCard {
                LuneSectionHeader(title: "Тесты на беременность", subtitle: "\(pregnancy.count) записано")
                if pregnancy.isEmpty {
                    LuneEmptyState(symbol: "cross.case", title: "Тестов пока нет", message: "Результаты появятся здесь.")
                } else {
                    ForEach(pregnancy.suffix(10).reversed(), id: \.id) { test in
                        HStack {
                            Text(test.day.key).font(TypographyTokens.bodyMedium)
                            Spacer()
                            Label(test.result.displayName, systemImage: test.result.symbolName)
                                .font(TypographyTokens.bodySmall)
                                .foregroundStyle(test.result == .positive ? ColorTokens.success : ColorTokens.textSecondary)
                        }
                        .frame(minHeight: 34)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func cycleIntervals() -> [Int] {
        let starts = database.periodStarts()
        return zip(starts, starts.dropFirst()).compactMap { first, second in
            let value = first.days(until: second)
            return CyclePredictionEngine.plausibleCycleRange.contains(value) ? value : nil
        }
    }

    private struct SymptomCount: Identifiable {
        let name: String
        let count: Int
        var id: String { name }
    }

    private func symptomCounts() -> [SymptomCount] {
        Dictionary(grouping: database.all(DailySymptomEntry.self), by: \.symptom)
            .map { SymptomCount(name: $0.key.displayName, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
}
