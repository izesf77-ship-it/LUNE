import Foundation
import SwiftData

/// Профиль пользователя
@Model
final class UserProfile {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    // Основные настройки
    var currentMode: String // AppMode raw value
    var hasCompletedOnboarding: Bool
    
    // Персонализация
    var userName: String?
    
    // Цикл
    var typicalCycleLength: Int? // Обычная длина цикла (дни)
    var typicalPeriodDuration: Int? // Обычная длительность месячных (дни)
    
    // Fertility tracking
    var trackingBasalTemperature: Bool
    var trackingCervicalMucus: Bool
    var trackingLHTests: Bool
    
    // Приватность
    var faceIDEnabled: Bool
    var hideNotificationPreviews: Bool
    
    // Уведомления
    var notificationsEnabled: Bool
    var periodReminderDaysBefore: Int
    var dailyLogReminderTime: Date?
    
    init(
        id: UUID = UUID(),
        currentMode: AppMode = .cycleTracking,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.currentMode = currentMode.rawValue
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.userName = nil
        self.typicalCycleLength = nil
        self.typicalPeriodDuration = nil
        self.trackingBasalTemperature = false
        self.trackingCervicalMucus = false
        self.trackingLHTests = false
        self.faceIDEnabled = false
        self.hideNotificationPreviews = true
        self.notificationsEnabled = false
        self.periodReminderDaysBefore = 2
        self.dailyLogReminderTime = nil
    }
    
    var mode: AppMode {
        get { AppMode(rawValue: currentMode) ?? .cycleTracking }
        set { currentMode = newValue.rawValue }
    }
    
    func updateTimestamp() {
        updatedAt = Date()
    }
}
