import Foundation

/// Чистое, тестируемое состояние ответов онбординга.
/// Используется и экранами, и финализацией — поэтому «Пропустить» не может
/// незаметно выбросить уже введённые пользователем данные.
struct OnboardingDraft {
    var mode: AppMode = .cycleTracking
    var hasLastPeriod: Bool = false
    var lastPeriodConfirmed: Bool = false
    var lastPeriodDate: Date = Date()
    var cycleLength: Int?
    var periodDuration: Int?
    var historyDates: [Date] = []
    var notificationsOn: Bool = false
    var faceIDOn: Bool = false
}

/// Нормализация ответов перед сохранением в SwiftData.
enum OnboardingDataNormalizer {

    /// Диапазон длительности цикла, совпадающий с CyclePredictionEngine.
    static let validCycleLengthRange = 15...60
    static let validPeriodDurationRange = 1...15

    /// Даты начал менструаций: только подтверждённые пользователем,
    /// не в будущем, без дубликатов и в хронологическом порядке.
    static func periodStarts(
        from draft: OnboardingDraft,
        today: CalendarDate = CalendarDate(Date())
    ) -> [CalendarDate] {
        var starts: [CalendarDate] = []

        if draft.lastPeriodConfirmed && draft.hasLastPeriod {
            starts.append(clamped(CalendarDate(draft.lastPeriodDate), to: today))
        }

        for date in draft.historyDates {
            let day = clamped(CalendarDate(date), to: today)
            if !starts.contains(day) { starts.append(day) }
        }

        return starts.sorted()
    }

    static func validatedCycleLength(_ value: Int?) -> Int? {
        guard let value, validCycleLengthRange.contains(value) else { return nil }
        return value
    }

    static func validatedPeriodDuration(_ value: Int?) -> Int? {
        guard let value, validPeriodDurationRange.contains(value) else { return nil }
        return value
    }

    /// Все введённые значения, которые нужно сохранить.
    /// Эта функция намеренно не имеет параметра «пропустить»: пропуск необязательного
    /// шага сохраняет то, что пользователь уже успел выбрать.
    static func profileValues(from draft: OnboardingDraft) -> OnboardingProfileValues {
        OnboardingProfileValues(
            mode: draft.mode,
            typicalCycleLength: validatedCycleLength(draft.cycleLength),
            typicalPeriodDuration: validatedPeriodDuration(draft.periodDuration),
            notificationsEnabled: draft.notificationsOn,
            faceIDRequested: draft.faceIDOn
        )
    }

    private static func clamped(_ day: CalendarDate, to today: CalendarDate) -> CalendarDate {
        day > today ? today : day
    }
}

struct OnboardingProfileValues {
    let mode: AppMode
    let typicalCycleLength: Int?
    let typicalPeriodDuration: Int?
    let notificationsEnabled: Bool
    let faceIDRequested: Bool
}
