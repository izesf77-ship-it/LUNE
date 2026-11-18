import Foundation
import SwiftData

// MARK: - Базальная температура

@Model
final class BasalTemperatureEntry: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String

    var celsius: Double
    var measuredAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        day: CalendarDate,
        celsius: Double,
        measuredAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.celsius = min(max(celsius, 34), 42)
        self.measuredAt = measuredAt
        self.notes = notes
    }

    var isValid: Bool { celsius >= 35 && celsius <= 39 }
    func touch() { updatedAt = Date() }
}

// MARK: - Цервикальная слизь

@Model
final class CervicalMucusEntry: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String
    var typeRaw: String
    var notes: String?

    init(id: UUID = UUID(), day: CalendarDate, type: CervicalMucusType, notes: String? = nil) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.typeRaw = type.rawValue
        self.notes = notes
    }

    var type: CervicalMucusType {
        get { CervicalMucusType(rawValue: typeRaw) ?? .unknown }
        set { typeRaw = newValue.rawValue; updatedAt = Date() }
    }

    func touch() { updatedAt = Date() }
}

enum CervicalMucusType: String, Codable, CaseIterable, Identifiable {
    case unknown, dry, sticky, creamy, watery, eggWhite

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unknown: return "Не отслеживала"
        case .dry: return "Сухая"
        case .sticky: return "Липкая"
        case .creamy: return "Кремовая"
        case .watery: return "Водянистая"
        case .eggWhite: return "Как яичный белок"
        }
    }

    /// Наблюдаемый признак, а не подтверждение овуляции.
    var isMoreFertileSign: Bool {
        self == .watery || self == .eggWhite
    }
}

// MARK: - ЛГ-тест

@Model
final class LHTestEntry: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String
    var resultRaw: String
    var testedAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        day: CalendarDate,
        result: TestResult,
        testedAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.resultRaw = result.rawValue
        self.testedAt = testedAt
        self.notes = notes
    }

    var result: TestResult {
        get { TestResult(rawValue: resultRaw) ?? .invalid }
        set { resultRaw = newValue.rawValue; updatedAt = Date() }
    }

    func touch() { updatedAt = Date() }
}

// MARK: - Тест на беременность

@Model
final class PregnancyTestEntry: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String
    var resultRaw: String
    var testedAt: Date
    var notes: String?
    /// Отдельное согласие пользователя на информационный сценарий наблюдения.
    var wantsObservationScenario: Bool

    init(
        id: UUID = UUID(),
        day: CalendarDate,
        result: TestResult,
        testedAt: Date = Date(),
        notes: String? = nil,
        wantsObservationScenario: Bool = false
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.resultRaw = result.rawValue
        self.testedAt = testedAt
        self.notes = notes
        self.wantsObservationScenario = wantsObservationScenario
    }

    var result: TestResult {
        get { TestResult(rawValue: resultRaw) ?? .invalid }
        set { resultRaw = newValue.rawValue; updatedAt = Date() }
    }

    func touch() { updatedAt = Date() }
}

enum TestResult: String, Codable, CaseIterable, Identifiable {
    case positive, negative, invalid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .positive: return "Положительный"
        case .negative: return "Отрицательный"
        case .invalid: return "Недействительный"
        }
    }

    var symbolName: String {
        switch self {
        case .positive: return "checkmark.circle.fill"
        case .negative: return "xmark.circle"
        case .invalid: return "questionmark.circle"
        }
    }
}

// MARK: - Половая близость (добровольная запись)

@Model
final class IntimacyEntry: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String
    var protectionUsed: Bool
    var notes: String?

    init(id: UUID = UUID(), day: CalendarDate, protectionUsed: Bool = false, notes: String? = nil) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.protectionUsed = protectionUsed
        self.notes = notes
    }

    func touch() { updatedAt = Date() }
}
