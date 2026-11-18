import Foundation
import SwiftData
import SwiftUI

/// Общий контракт для записей, привязанных к календарному дню.
protocol DayKeyedRecord {
    var id: UUID { get }
    var dayKey: String { get }
    var createdAt: Date { get }
    var updatedAt: Date { get set }
}

extension DayKeyedRecord {
    var day: CalendarDate { CalendarDate(key: dayKey) ?? CalendarDate(createdAt) }
}

// MARK: - Симптом

@Model
final class DailySymptomEntry: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String

    var symptomRaw: String
    var intensity: Int // 1..3
    var notes: String?

    init(
        id: UUID = UUID(),
        day: CalendarDate,
        symptom: SymptomType,
        intensity: Int = 2,
        notes: String? = nil
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.symptomRaw = symptom.rawValue
        self.intensity = min(max(intensity, 1), 3)
        self.notes = notes
    }

    var symptom: SymptomType {
        get { SymptomType(rawValue: symptomRaw) ?? .other }
        set { symptomRaw = newValue.rawValue; updatedAt = Date() }
    }

    func touch() { updatedAt = Date() }
}

enum SymptomType: String, Codable, CaseIterable, Identifiable {
    case pain = "pain"
    case headache = "headache"
    case bloating = "bloating"
    case acne = "acne"
    case breastTenderness = "breast_tenderness"
    case fatigue = "fatigue"
    case nausea = "nausea"
    case backPain = "back_pain"
    case sleepIssues = "sleep_issues"
    case appetite = "appetite"
    case skin = "skin"
    case libido = "libido"
    case discharge = "discharge"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pain: return "Боль"
        case .headache: return "Головная боль"
        case .bloating: return "Вздутие"
        case .acne: return "Акне"
        case .breastTenderness: return "Чувствительность груди"
        case .fatigue: return "Усталость"
        case .nausea: return "Тошнота"
        case .backPain: return "Боль в спине"
        case .sleepIssues: return "Сон"
        case .appetite: return "Аппетит"
        case .skin: return "Кожа"
        case .libido: return "Либидо"
        case .discharge: return "Выделения"
        case .other: return "Другое"
        }
    }

    var iconName: String {
        switch self {
        case .pain: return "bolt.heart"
        case .headache: return "brain.head.profile"
        case .bloating: return "circle.hexagongrid"
        case .acne: return "face.dashed"
        case .breastTenderness: return "heart.circle"
        case .fatigue: return "battery.25"
        case .nausea: return "waveform.path.ecg"
        case .backPain: return "figure.walk"
        case .sleepIssues: return "bed.double"
        case .appetite: return "leaf"
        case .skin: return "sparkles"
        case .libido: return "heart"
        case .discharge: return "drop"
        case .other: return "ellipsis.circle"
        }
    }

    var intensityColor: Color {
        ColorTokens.symptomLow
    }
}

// MARK: - Настроение

@Model
final class DailyMoodEntry: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String

    var moodRaw: String
    var note: String?

    init(id: UUID = UUID(), day: CalendarDate, mood: MoodType, note: String? = nil) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.moodRaw = mood.rawValue
        self.note = note
    }

    var mood: MoodType {
        get { MoodType(rawValue: moodRaw) ?? .neutral }
        set { moodRaw = newValue.rawValue; updatedAt = Date() }
    }

    func touch() { updatedAt = Date() }
}

enum MoodType: String, Codable, CaseIterable, Identifiable {
    case happy, energetic, calm, neutral, anxious, irritable, sad, low

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .happy: return "Счастлива"
        case .energetic: return "Энергична"
        case .calm: return "Спокойна"
        case .neutral: return "Нормально"
        case .anxious: return "Тревожна"
        case .irritable: return "Раздражена"
        case .sad: return "Грустна"
        case .low: return "Уныла"
        }
    }

    var symbolName: String {
        switch self {
        case .happy: return "face.smiling"
        case .energetic: return "bolt"
        case .calm: return "leaf"
        case .neutral: return "minus.circle"
        case .anxious: return "wind"
        case .irritable: return "exclamationmark.circle"
        case .sad: return "cloud.rain"
        case .low: return "cloud"
        }
    }
}

// MARK: - Самочувствие (энергия, сон, боль по шкале)

@Model
final class DailyWellbeingEntry: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String

    var energy: Int       // 1..5
    var sleepHours: Double // 0..14
    var painLevel: Int    // 0..10
    var bloating: Int     // 0..3
    var notes: String?

    init(
        id: UUID = UUID(),
        day: CalendarDate,
        energy: Int = 3,
        sleepHours: Double = 7,
        painLevel: Int = 0,
        bloating: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.energy = min(max(energy, 1), 5)
        self.sleepHours = min(max(sleepHours, 0), 14)
        self.painLevel = min(max(painLevel, 0), 10)
        self.bloating = min(max(bloating, 0), 3)
        self.notes = notes
    }

    func touch() { updatedAt = Date() }
}

// MARK: - Свободная заметка

@Model
final class DailyNote: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String
    var text: String

    init(id: UUID = UUID(), day: CalendarDate, text: String) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.text = text
    }

    func touch() { updatedAt = Date() }
}

// MARK: - Лекарства

@Model
final class MedicationEntry: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String
    var name: String
    var dose: String?
    var time: Date?
    var notes: String?

    init(
        id: UUID = UUID(),
        day: CalendarDate,
        name: String,
        dose: String? = nil,
        time: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.name = name
        self.dose = dose
        self.time = time
        self.notes = notes
    }

    func touch() { updatedAt = Date() }
}

// MARK: - Обратная совместимость с ранними именами моделей

typealias SymptomEntry = DailySymptomEntry
typealias MoodEntry = DailyMoodEntry
