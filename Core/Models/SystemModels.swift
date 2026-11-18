import Foundation
import SwiftData

/// Произвольные пользовательские настройки, сохраняемые как пары ключ-значение.
@Model
final class AppPreferences {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var key: String
    var value: String

    init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.key = key
        self.value = value
    }
}

/// Ручная пометка на календаре (не является прогнозом).
@Model
final class CycleAnnotation: DayKeyedRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var dayKey: String
    var title: String
    var notes: String?

    init(id: UUID = UUID(), day: CalendarDate, title: String, notes: String? = nil) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.dayKey = day.key
        self.title = title
        self.notes = notes
    }

    func touch() { updatedAt = Date() }
}

/// Описание запланированного локального уведомления.
@Model
final class NotificationConfiguration {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var identifier: String
    var kindRaw: String
    var hour: Int
    var isEnabled: Bool
    var dayOffset: Int

    init(
        id: UUID = UUID(),
        identifier: String,
        kind: LocalNotificationKind,
        hour: Int = 9,
        isEnabled: Bool = true,
        dayOffset: Int = 0
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.identifier = identifier
        self.kindRaw = kind.rawValue
        self.hour = min(max(hour, 0), 23)
        self.isEnabled = isEnabled
        self.dayOffset = dayOffset
    }

    var kind: LocalNotificationKind {
        get { LocalNotificationKind(rawValue: kindRaw) ?? .period }
        set { kindRaw = newValue.rawValue; updatedAt = Date() }
    }
}

enum LocalNotificationKind: String, Codable, CaseIterable {
    case period, symptomLog, lhTest, pregnancyTest
}

/// Метаданные последней резервной копии (без самих данных).
@Model
final class BackupMetadata {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var backupVersion: Int
    var recordCount: Int
    var fileName: String

    init(
        id: UUID = UUID(),
        backupVersion: Int,
        recordCount: Int,
        fileName: String
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.backupVersion = backupVersion
        self.recordCount = recordCount
        self.fileName = fileName
    }
}
