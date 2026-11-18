import Foundation

// MARK: - Input / Output

/// Входные данные прогноза. Содержат только подтверждённые пользователем факты.
struct CyclePredictionInput {
    /// Подтверждённые даты начала менструаций.
    let confirmedStarts: [CalendarDate]
    /// Дата, на которую строится прогноз.
    let today: CalendarDate
    /// Длительность цикла, указанная пользователем при онбординге (если известна).
    let reportedCycleLength: Int?
    /// Обычная длительность кровотечения (если известна).
    let reportedPeriodDuration: Int?
    /// Известные длительности последних кровотечений.
    let knownDurations: [Int]

    init(
        confirmedStarts: [CalendarDate],
        today: CalendarDate = CalendarDate(Date()),
        reportedCycleLength: Int? = nil,
        reportedPeriodDuration: Int? = nil,
        knownDurations: [Int] = []
    ) {
        self.confirmedStarts = confirmedStarts
        self.today = today
        self.reportedCycleLength = reportedCycleLength
        self.reportedPeriodDuration = reportedPeriodDuration
        self.knownDurations = knownDurations
    }
}

struct CyclePrediction {
    let cycleLength: Int
    let cycleLengthSpread: Int
    let sampleCount: Int
    let confidence: PredictionConfidence
    let currentDay: Int
    let nextStart: CalendarDate
    let nextStartRange: ClosedRange<CalendarDate>
    let predictedPeriodEnd: CalendarDate
    let expectedPeriodDuration: Int
    let daysUntilNext: Int
    let delayDays: Int
    let explanation: String
    let irregular: Bool

    var hasDelay: Bool { delayDays > 0 }

    var delayText: String? {
        guard hasDelay else { return nil }
        return "По календарному прогнозу задержка составляет \(delayDays) \(RussianPlural.days(delayDays))"
    }

    var shortForecast: String {
        if hasDelay {
            return "Месячные ожидались \(delayDays) \(RussianPlural.days(delayDays)) назад"
        }
        if daysUntilNext == 0 {
            return "Месячные могут начаться в любой день"
        }
        return "Месячные ожидаются примерно через \(daysUntilNext) \(RussianPlural.days(daysUntilNext))"
    }
}

// MARK: - Engine

/// Тестируемый движок прогнозирования. Не имеет зависимостей от SwiftData и UI.
enum CyclePredictionEngine {

    /// Диапазон правдоподобных длительностей цикла. Всё вне диапазона считается ошибкой записи.
    static let plausibleCycleRange = 15...60

    static func predict(_ input: CyclePredictionInput) -> CyclePrediction {
        let starts = Array(Set(input.confirmedStarts)).sorted()

        let intervals = zip(starts, starts.dropFirst()).compactMap { first, second -> Int? in
            let value = first.days(until: second)
            return plausibleCycleRange.contains(value) ? value : nil
        }

        let medianInterval = median(intervals) ?? input.reportedCycleLength ?? 28
        let cycleLength = min(max(medianInterval, 15), 60)

        let spread = intervals.count >= 2
            ? (intervals.max() ?? cycleLength) - (intervals.min() ?? cycleLength)
            : 0

        let confidence: PredictionConfidence
        switch intervals.count {
        case 6... where spread <= 4:
            confidence = .medium
        case 3...:
            confidence = .low
        default:
            confidence = .insufficient
        }

        let uncertainty: Int
        if intervals.count >= 2 {
            uncertainty = max(2, spread / 2 + 1)
        } else if input.reportedCycleLength != nil {
            uncertainty = 3
        } else {
            uncertainty = 5
        }

        let lastStart = starts.last ?? input.today
        let nextStart = lastStart.adding(days: cycleLength)
        let range = (nextStart.adding(days: -uncertainty))...(nextStart.adding(days: uncertainty))

        let rawDay = lastStart.days(until: input.today) + 1
        let currentDay = max(1, rawDay)

        let durations = input.knownDurations.filter { (1...15).contains($0) }
        let periodDuration = median(durations)
            ?? input.reportedPeriodDuration
            ?? 5

        let daysUntil = input.today.days(until: nextStart)
        let delay = max(0, nextStart.days(until: input.today))

        let explanation: String
        if intervals.isEmpty {
            explanation = "Недостаточно данных для надёжного прогноза. Запишите даты нескольких менструаций — тогда прогноз станет точнее."
        } else {
            explanation = "Прогноз рассчитан на основании \(intervals.count) \(RussianPlural.cycles(intervals.count)). Дата указана ориентировочно."
        }

        return CyclePrediction(
            cycleLength: cycleLength,
            cycleLengthSpread: spread,
            sampleCount: intervals.count,
            confidence: confidence,
            currentDay: currentDay,
            nextStart: nextStart,
            nextStartRange: range,
            predictedPeriodEnd: nextStart.adding(days: max(0, periodDuration - 1)),
            expectedPeriodDuration: periodDuration,
            daysUntilNext: daysUntil,
            delayDays: delay,
            explanation: explanation,
            irregular: confidence == .insufficient && intervals.count >= 2 && spread > 7
        )
    }

    /// Медиана с округлением вверх для чётного количества значений.
    static func median(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[middle - 1] + sorted[middle] + 1) / 2
        }
        return sorted[middle]
    }
}

// MARK: - Missed period guidance

enum MissedPeriodScenario: String {
    case regular, irregular, insufficientHistory, missingEntries
    case prolongedDelay, positiveTest, negativeTest
}

struct MissedPeriodGuidance {
    let scenario: MissedPeriodScenario
    let title: String
    let detail: String
    let action: String?
    let footnote: String
}

/// Осторорожная интерпретация задержки. Никогда не ставит диагноз.
enum MissedPeriodEvaluator {

    static func evaluate(
        prediction: CyclePrediction,
        today: CalendarDate,
        pregnancyTests: [(day: CalendarDate, result: TestResult)],
        hasLoggingGap: Bool
    ) -> MissedPeriodGuidance? {
        guard prediction.hasDelay else { return nil }

        let latestTest = pregnancyTests.max { $0.day < $1.day }

        if latestTest?.result == .positive {
            return MissedPeriodGuidance(
                scenario: .positiveTest,
                title: "Вы записали положительный результат теста",
                detail: "Домашний тест — это важный сигнал, но он не заменяет медицинское подтверждение. Запись в приложении не является диагнозом.",
                action: "При желании оформите информационный сценарий наблюдения и обратитесь к врачу для подтверждения.",
                footnote: "При сильной боли или кровотечении обратитесь за медицинской помощью сразу."
            )
        }

        if prediction.delayDays >= 14 {
            return MissedPeriodGuidance(
                scenario: .prolongedDelay,
                title: "Месячные отсутствуют продолжительное время",
                detail: "По календарному прогнозу прошло больше двух недель с ожидаемой даты. Причины могут быть разными, и оценить их по календарю невозможно.",
                action: "Рекомендуется обратиться к врачу и, при возможности, сделать домашний тест.",
                footnote: "Это информационная подсказка, а не медицинский вывод."
            )
        }

        if prediction.confidence == .insufficient {
            return MissedPeriodGuidance(
                scenario: .insufficientHistory,
                title: "Недостаточно данных для оценки задержки",
                detail: "Прогноз построен на ограниченной истории циклов, поэтому говорить о задержке было бы некорректно.",
                action: "Продолжайте отмечать начала менструаций — после нескольких записей оценка станет информативнее.",
                footnote: "Календарный метод не подходит для определения причин задержки."
            )
        }

        if latestTest?.result == .negative {
            return MissedPeriodGuidance(
                scenario: .negativeTest,
                title: "Тест отрицательный, месячные пока не начались",
                detail: "Отрицательный результат может быть получен слишком рано. Ситуация требует наблюдения, а не вывода по симптомам.",
                action: "Повторите тест через неделю. Если месячные так и не начнутся, обратитесь к врачу.",
                footnote: "Следуйте инструкции конкретного теста."
            )
        }

        if hasLoggingGap {
            return MissedPeriodGuidance(
                scenario: .missingEntries,
                title: "Возможно, записи пропущены",
                detail: "В истории есть интервалы без отметок. Проверьте, не пропущена ли дата начала менструации.",
                action: "При необходимости добавьте пропущенную запись — прогноз пересчитается автоматически.",
                footnote: "Изменение истории сразу обновляет прогноз."
            )
        }

        if prediction.irregular {
            return MissedPeriodGuidance(
                scenario: .irregular,
                title: "Цикл нерегулярный — дата приблизительная",
                detail: "Длительность предыдущих циклов заметно различалась, поэтому календарная оценка неточна.",
                action: "Ориентируйтесь на самочувствие и при сомнениях сделайте домашний тест.",
                footnote: "Нерегулярность сама по себе не позволяет сделать медицинский вывод."
            )
        }

        return MissedPeriodGuidance(
            scenario: .regular,
            title: "Месячные пока не начались",
            detail: "Ожидаемая дата прошла, но возможна обычная вариация цикла.",
            action: "Если месячные не начнутся в течение нескольких дней, можно сделать домашний тест — с первого дня ожидаемой менструации.",
            footnote: "Прогноз — это оценка, а не подтверждение беременности."
        )
    }
}
