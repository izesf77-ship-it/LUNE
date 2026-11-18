import Foundation
import SwiftData

/// Единый профиль пользователя для обоих режимов.
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    var currentModeRaw: String
    var hasCompletedOnboarding: Bool
    var onboardingVersion: Int

    var userName: String?
    var typicalCycleLength: Int?
    var typicalPeriodDuration: Int?

    var trackingBasalTemperature: Bool
    var trackingCervicalMucus: Bool
    var trackingLHTests: Bool
    var trackingIntimacy: Bool

    var faceIDEnabled: Bool
    var hideNotificationPreviews: Bool
    var hideSensitiveOnHome: Bool

    var notificationsEnabled: Bool
    var periodReminderDaysBefore: Int
    var symptomReminderEnabled: Bool
    var symptomReminderHour: Int
    var lhTestReminderEnabled: Bool
    var lhTestReminderHour: Int
    var pregnancyTestReminderEnabled: Bool
    var pregnancyTestReminderHour: Int

    init(
        id: UUID = UUID(),
        currentMode: AppMode = .cycleTracking,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.currentModeRaw = currentMode.rawValue
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.onboardingVersion = 1
        self.userName = nil
        self.typicalCycleLength = nil
        self.typicalPeriodDuration = nil
        self.trackingBasalTemperature = false
        self.trackingCervicalMucus = false
        self.trackingLHTests = false
        self.trackingIntimacy = false
        self.faceIDEnabled = false
        self.hideNotificationPreviews = true
        self.hideSensitiveOnHome = true
        self.notificationsEnabled = false
        self.periodReminderDaysBefore = 2
        self.symptomReminderEnabled = false
        self.symptomReminderHour = 20
        self.lhTestReminderEnabled = false
        self.lhTestReminderHour = 9
        self.pregnancyTestReminderEnabled = false
        self.pregnancyTestReminderHour = 9
    }

    var mode: AppMode {
        get { AppMode(rawValue: currentModeRaw) ?? .cycleTracking }
        set {
            currentModeRaw = newValue.rawValue
            touch()
        }
    }

    func touch() {
        updatedAt = Date()
    }
}
