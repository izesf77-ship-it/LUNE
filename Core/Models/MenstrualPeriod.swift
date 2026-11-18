import Foundation
import SwiftData

/// Подтверждённая пользователем менструация.
/// Прогнозы в этой модели НЕ хранятся — они вычисляются CyclePredictionEngine.
@Model
final class MenstrualPeriod {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    /// Момент записи (для сортировки) и стабильный календарный день.
    var startDate: Date
    var startDayKey: String
    var endDate: Date?
    var endDayKey: String?

    /// Длительность кровотечения, выбранная пользователем (если известна).
    var userReportedDuration: Int?
    var notes: String?

    init(
        id: UUID = UUID(),
        startDay: CalendarDate,
        endDay: CalendarDate? = nil,
        userReportedDuration: Int? = nil,
        notes: String? = nil
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.startDate = startDay.localDate() ?? startDay.utcDate
        self.startDayKey = startDay.key
        self.endDate = endDay?.localDate()
        self.endDayKey = endDay?.key
        self.userReportedDuration = userReportedDuration
        self.notes = notes
    }

    var startDay: CalendarDate {
        CalendarDate(key: startDayKey) ?? CalendarDate(startDate)
    }

    var endDay: CalendarDate? {
        guard let endDayKey else { return nil }
        return CalendarDate(key: endDayKey)
    }

    /// Длительность в календарных днях, включительно.
    var duration: Int? {
        guard let endDay else {
            guard let reported = userReportedDuration else { return nil }
            return max(1, min(reported, 15))
        }
        return max(1, startDay.days(until: endDay) + 1)
    }

    func contains(_ day: CalendarDate) -> Bool {
        if let endDay {
            return day >= startDay && day <= endDay
        }
        return day == startDay
    }

    func touch() { updatedAt = Date() }
}

/// Отдельная запись дня кровотечения — позволяет хранить историю
/// интенсивности и корректно удалять/редактировать отдельные дни.
@Model
final class BleedingDayEntry {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String
    var flow: Int // 1 = скудно, 2 = умеренно, 3 = обильно
    var notes: String?

    init(id: UUID = UUID(), day: CalendarDate, flow: Int = 2, notes: String? = nil) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.flow = min(max(flow, 1), 3)
        self.notes = notes
    }

    var day: CalendarDate { CalendarDate(key: dayKey) ?? CalendarDate(createdAt) }
    var flowName: String {
        switch flow {
        case 1: return "Скудно"
        case 3: return "Обильно"
        default: return "Умеренно"
        }
    }

    func touch() { updatedAt = Date() }
}
