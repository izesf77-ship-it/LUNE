import Foundation
import SwiftData

// MARK: - Базальная температура

@Model
final class BasalTemperatureEntry {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var date: Date
    
    /// Температура в градусах Цельсия (обычно 36.0-37.5)
    var temperature: Double
    
    /// Время измерения
    var measurementTime: Date
    
    var notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date,
        temperature: Double,
        measurementTime: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.date = date
        self.temperature = temperature
        self.measurementTime = measurementTime
        self.notes = notes
    }
    
    /// Валидация температуры
    var isValid: Bool {
        temperature >= 35.0 && temperature <= 39.0
    }
}

// MARK: - Цервикальная слизь

@Model
final class CervicalMucusEntry {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var date: Date
    
    var type: String // CervicalMucusType raw value
    var notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date,
        type: CervicalMucusType,
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.date = date
        self.type = type.rawValue
        self.notes = notes
    }
    
    var mucusType: CervicalMucusType {
        get { CervicalMucusType(rawValue: type) ?? .none }
        set { type = newValue.rawValue }
    }
}

enum CervicalMucusType: String, Codable, CaseIterable {
    case none = "none"
    case dry = "dry"
    case sticky = "sticky"
    case creamy = "creamy"
    case watery = "watery"
    case eggWhite = "egg_white"
    
    var displayName: String {
        switch self {
        case .none: return "Нет"
        case .dry: return "Сухая"
        case .sticky: return "Липкая"
        case .creamy: return "Кремовая"
        case .watery: return "Водянистая"
        case .eggWhite: return "Как яичный белок"
        }
    }
    
    var fertilityIndicator: FertilityLevel {
        switch self {
        case .none, .dry: return .low
        case .sticky, .creamy: return .medium
        case .watery, .eggWhite: return .high
        }
    }
}

// MARK: - ЛГ-тест

@Model
final class LHTestEntry {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var date: Date
    
    var result: String // TestResult raw value
    var testTime: Date
    var notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date,
        result: TestResult,
        testTime: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.date = date
        self.result = result.rawValue
        self.testTime = testTime
        self.notes = notes
    }
    
    var testResult: TestResult {
        get { TestResult(rawValue: result) ?? .negative }
        set { result = newValue.rawValue }
    }
}

// MARK: - Тест на беременность

@Model
final class PregnancyTestEntry {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var date: Date
    
    var result: String // TestResult raw value
    var testTime: Date
    var notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date,
        result: TestResult,
        testTime: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.date = date
        self.result = result.rawValue
        self.testTime = testTime
        self.notes = notes
    }
    
    var testResult: TestResult {
        get { TestResult(rawValue: result) ?? .negative }
        set { result = newValue.rawValue }
    }
}

enum TestResult: String, Codable, CaseIterable {
    case positive = "positive"
    case negative = "negative"
    case invalid = "invalid"
    
    var displayName: String {
        switch self {
        case .positive: return "Положительный"
        case .negative: return "Отрицательный"
        case .invalid: return "Недействительный"
        }
    }
}

// MARK: - Интимность (добровольная регистрация)

@Model
final class IntimacyEntry {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var date: Date
    
    var protectionUsed: Bool
    var notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date,
        protectionUsed: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.date = date
        self.protectionUsed = protectionUsed
        self.notes = notes
    }
}

// MARK: - Вспомогательные типы

enum FertilityLevel {
    case low
    case medium
    case high
    
    var displayName: String {
        switch self {
        case .low: return "Низкая"
        case .medium: return "Средняя"
        case .high: return "Высокая"
        }
    }
}
