import Foundation

// MARK: - Input / Output

struct FertilityInput {
    let prediction: CyclePrediction
    let today: CalendarDate
    let lhTests: [(day: CalendarDate, result: TestResult)]
    let temperatures: [(day: CalendarDate, celsius: Double)]
    let mucus: [(day: CalendarDate, type: CervicalMucusType)]

    init(
        prediction: CyclePrediction,
        today: CalendarDate = CalendarDate(Date()),
        lhTests: [(day: CalendarDate, result: TestResult)] = [],
        temperatures: [(day: CalendarDate, celsius: Double)] = [],
        mucus: [(day: CalendarDate, type: CervicalMucusType)] = []
    ) {
        self.prediction = prediction
        self.today = today
        self.lhTests = lhTests
        self.temperatures = temperatures
        self.mucus = mucus
    }
}

enum FertilityInsightKind: String {
    case calendarEstimate
    case observedSign
    case uncertain
}

struct FertilityInsight: Identifiable {
    let id: String
    let kind: FertilityInsightKind
    let title: String
    let detail: String
    let caution: String?
}

enum TemperatureTrend: String {
    case possibleRetrospectiveRise
    case noClearPattern
    case insufficientData

    var displayName: String {
        switch self {
        case .possibleRetrospectiveRise: return "Возможный ретроспективный подъём"
        case .noClearPattern: return "Чёткой закономерности пока не видно"
        case .insufficientData: return "Недостаточно измерений"
        }
    }
}

struct FertilitySnapshot {
    let estimatedOvulationDay: CalendarDate
    let fertileWindow: ClosedRange<CalendarDate>
    let daysUntilEstimatedOvulation: Int
    let temperatureTrend: TemperatureTrend
    let insights: [FertilityInsight]
    let disclaimers: [String]

    var isFertileWindowToday: Bool {
        fertileWindow.contains(CalendarDate(Date()))
    }
}

// MARK: - Engine

/// Движок наблюдений за фертильностью.
///
/// Календарная оценка, наблюдаемые признаки и неопределённые результаты
/// разделены. Движок не вычисляет «уверенность овуляции» и не даёт
/// рекомендаций по предотвращению беременности.
enum FertilityInsightsEngine {

    static func makeSnapshot(_ input: FertilityInput) -> FertilitySnapshot {
        let estimatedOvulation = input.prediction.nextStart.adding(days: -14)
        let window = (estimatedOvulation.adding(days: -5))...(estimatedOvulation.adding(days: 1))

        var insights: [FertilityInsight] = []

        insights.append(FertilityInsight(
            id: "calendar-estimate",
            kind: .calendarEstimate,
            title: "Календарная оценка",
            detail: "По длительности предыдущих циклов ориентировочное фертильное окно — с \(shortDate(window.lowerBound)) по \(shortDate(window.upperBound)). Ориентировочная дата овуляции — \(shortDate(estimatedOvulation)).",
            caution: "Это расчёт по календарю, а не подтверждение овуляции."
        ))

        if input.prediction.confidence == .insufficient {
            insights.append(FertilityInsight(
                id: "calendar-low-data",
                kind: .uncertain,
                title: "Календарная оценка неточна",
                detail: "Истории циклов недостаточно, поэтому даты ориентировочного окна могут сильно отличаться от реальных.",
                caution: "Не используйте календарную оценку как способ предотвращения беременности."
            ))
        }

        let recentPositiveLH = input.lhTests
            .filter { $0.result == .positive && input.today.days(until: $0.day) >= -2 && input.today.days(until: $0.day) <= 0 }
            .max { $0.day < $1.day }

        if recentPositiveLH != nil {
            insights.append(FertilityInsight(
                id: "lh-positive",
                kind: .observedSign,
                title: "Положительный ЛГ-тест",
                detail: "Положительный результат может указывать на приближение овуляции.",
                caution: "Тест не доказывает, что овуляция уже произошла."
            ))
        }

        let fertileMucusDays = input.mucus
            .filter { $0.type.isMoreFertileSign && input.today.days(until: $0.day) >= -3 && input.today.days(until: $0.day) <= 0 }
            .map(\.day)
            .sorted()

        if let lastDay = fertileMucusDays.last {
            insights.append(FertilityInsight(
                id: "mucus-sign",
                kind: .observedSign,
                title: "Наблюдение за слизью",
                detail: "\(shortDate(lastDay)) вы отметили слизь, которая обычно считается более благоприятной для зачатия.",
                caution: "Это наблюдение, а не подтверждение овуляции."
            ))
        }

        let trend = temperatureTrend(input.temperatures, today: input.today)
        if trend == .possibleRetrospectiveRise {
            insights.append(FertilityInsight(
                id: "bbt-trend",
                kind: .observedSign,
                title: "Температурная закономерность",
                detail: "В последних измерениях заметен подъём температуры относительно предыдущих дней.",
                caution: "Температурный график помогает заметить закономерность только задним числом и не подтверждает овуляцию."
            ))
        }

        if insights.count == 1 {
            insights.append(FertilityInsight(
                id: "observations-empty",
                kind: .uncertain,
                title: "Пока мало наблюдений",
                detail: "Отмечайте ЛГ-тесты, температуру и слизь, чтобы видеть личные закономерности вместе с календарной оценкой.",
                caution: nil
            ))
        }

        return FertilitySnapshot(
            estimatedOvulationDay: estimatedOvulation,
            fertileWindow: window,
            daysUntilEstimatedOvulation: input.today.days(until: estimatedOvulation),
            temperatureTrend: trend,
            insights: insights,
            disclaimers: [
                "Ни один из признаков не подтверждает овуляцию или беременность.",
                "Приложение не является средством контрацепции.",
                "Оценка фертильности не заменяет консультацию врача."
            ]
        )
    }

    /// Ретроспективный анализ temperatures. Требует минимум 5 измерений за последние 8 дней.
    static func temperatureTrend(
        _ entries: [(day: CalendarDate, celsius: Double)],
        today: CalendarDate
    ) -> TemperatureTrend {
        let recent = entries
            .filter { $0.celsius >= 35 && $0.celsius <= 39 }
            .filter { today.days(until: $0.day) >= -7 && today.days(until: $0.day) <= 0 }
            .sorted { $0.day < $1.day }

        guard recent.count >= 5 else { return .insufficientData }

        let byDay = Dictionary(grouping: recent, by: \.day)
            .compactMapValues { $0.map(\.celsius).reduce(0, +) / Double($0.count) }

        let lastThree = byDay.keys.sorted().suffix(3).compactMap { byDay[$0] }
        let previousThree = byDay.keys.sorted().dropLast(3).suffix(3).compactMap { byDay[$0] }

        guard lastThree.count == 3, previousThree.count >= 2 else { return .insufficientData }

        let lastMean = lastThree.reduce(0, +) / Double(lastThree.count)
        let previousMean = previousThree.reduce(0, +) / Double(previousThree.count)

        return lastMean - previousMean >= 0.3 ? .possibleRetrospectiveRise : .noClearPattern
    }

    private static func shortDate(_ day: CalendarDate) -> String {
        String(format: "%d.%02d", day.day, day.month)
    }
}
