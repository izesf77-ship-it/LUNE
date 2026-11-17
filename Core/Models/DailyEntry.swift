import Foundation
import SwiftData

/// Базовая модель для ежедневных записей
protocol DailyEntry {
    var id: UUID { get }
    var date: Date { get set }
    var createdAt: Date { get }
    var updatedAt: Date { get }
}

// MARK: - Симптом

@Model
final class SymptomEntry {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var date: Date
    
    var symptomType: String // SymptomType raw value
    var intensity: Int // 1-3 (low, medium, high)
    var notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date,
        symptomType: SymptomType,
        intensity: Int = 2,
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.date = date
        self.symptomType = symptomType.rawValue
        self.intensity = min(max(intensity, 1), 3)
        self.notes = notes
    }
    
    var type: SymptomType {
        get { SymptomType(rawValue: symptomType) ?? .other }
        set { symptomType = newValue.rawValue }
    }
}

enum SymptomType: String, Codable, CaseIterable {
    case cramps = "cramps"
    case headache = "headache"
    case bloating = "bloating"
    case acne = "acne"
    case breastTenderness = "breast_tenderness"
    case fatigue = "fatigue"
    case nausea = "nausea"
    case backPain = "back_pain"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .cramps: return "Спазмы"
        case .headache: return "Головная боль"
        case .bloating: return "Вздутие"
        case .acne: return "Акне"
        case .breastTenderness: return "Чувствительность груди"
        case .fatigue: return "Усталость"
        case .nausea: return "Тошнота"
        case .backPain: return "Боль в спине"
        case .other: return "Другое"
        }
    }
    
    var iconName: String {
        switch self {
        case .cramps: return "bolt.circle"
        case .headache: return "head.profile"
        case .bloating: return "circle.hexagonpath"
        case .acne: return "face.dashed"
        case .breastTenderness: return "heart.circle"
        case .fatigue: return "battery.25"
        case .nausea: return "waveform.path.ecg"
        case .backPain: return "figure.stand"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Настроение

@Model
final class MoodEntry {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var date: Date
    
    var mood: String // MoodType raw value
    var notes: String?
    
    init(
        id: UUID = UUID(),
        date: Date,
        mood: MoodType,
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.date = date
        self.mood = mood.rawValue
        self.notes = notes
    }
    
    var moodType: MoodType {
        get { MoodType(rawValue: mood) ?? .neutral }
        set { mood = newValue.rawValue }
    }
}

enum MoodType: String, Codable, CaseIterable {
    case happy = "happy"
    case energetic = "energetic"
    case calm = "calm"
    case neutral = "neutral"
    case anxious = "anxious"
    case irritable = "irritable"
    case sad = "sad"
    case depressed = "depressed"
    
    var displayName: String {
        switch self {
        case .happy: return "Счастлива"
        case .energetic: return "Энергична"
        case .calm: return "Спокойна"
        case .neutral: return "Нормально"
        case .anxious: return "Тревожна"
        case .irritable: return "Раздражена"
        case .sad: return "Грустна"
        case .depressed: return "Подавлена"
        }
    }
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .energetic: return "⚡️"
        case .calm: return "😌"
        case .neutral: return "😐"
        case .anxious: return "😰"
        case .irritable: return "😤"
        case .sad: return "😢"
        case .depressed: return "😞"
        }
    }
}

// MARK: - Заметка дня

@Model
final class DailyNote {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var date: Date
    
    var note: String
    
    init(
        id: UUID = UUID(),
        date: Date,
        note: String
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.date = date
        self.note = note
    }
}
