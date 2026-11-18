import Foundation
import UserNotifications
import UIKit

// MARK: - App delegate

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        PrivacyShield.shared.show()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        PrivacyShield.shared.hide()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

// MARK: - Notification service

/// Только локальные уведомления. Текст на экране блокировки нейтральный.
enum NotificationService {

    private static let prefix = "com.lune.notification."

    @MainActor
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }

    @MainActor
    static func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Полностью пересоздаёт уведомления после изменения прогноза или настроек.
    @MainActor
    static func reschedule(
        enabled: Bool,
        prediction: CyclePrediction,
        periodDaysBefore: Int,
        symptomHour: Int?,
        lhHour: Int?,
        pregnancyHour: Int?
    ) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard enabled else { return }
        let granted = await requestAuthorization()
        guard granted else { return }

        var requests: [UNNotificationRequest] = []

        // Менструация — одноразовое напоминание перед ожидаемой датой.
        // Прошедшую дату не планируем: такое уведомление никогда не сработает
        // и только создаст «зависшее» напоминание после редактирования цикла.
        let reminderDay = prediction.nextStart.adding(days: -max(0, periodDaysBefore))
        let today = CalendarDate(Date())
        if reminderDay >= today,
           let date = reminderDay.localDate(),
           let components = hourComponents(from: date, hour: 9) {
            requests.append(makeRequest(
                id: "period",
                title: "Напоминание из LUNÉ",
                body: "Пора заглянуть в календарь и отметить самочувствие.",
                components: components,
                repeats: false
            ))
        }

        if let hour = symptomHour, let components = dailyComponents(hour: hour) {
            requests.append(makeRequest(
                id: "symptom",
                title: "Напоминание из LUNÉ",
                body: "Если хотите, внесите сегодняшние наблюдения в дневник.",
                components: components,
                repeats: true
            ))
        }

        if let hour = lhHour, let components = dailyComponents(hour: hour) {
            requests.append(makeRequest(
                id: "lh",
                title: "Напоминание из LUNÉ",
                body: "Сегодня день для запланированной записи теста.",
                components: components,
                repeats: true
            ))
        }

        if let hour = pregnancyHour, let components = dailyComponents(hour: hour) {
            requests.append(makeRequest(
                id: "pregnancy",
                title: "Напоминание из LUNÉ",
                body: "Если вы запланировали тест, сегодня подходящий день.",
                components: components,
                repeats: true
            ))
        }

        for request in requests {
            try? await center.add(request)
        }
    }

    @MainActor
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static func makeRequest(
        id: String,
        title: String,
        body: String,
        components: DateComponents,
        repeats: Bool
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = prefix + id

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        return UNNotificationRequest(
            identifier: prefix + id,
            content: content,
            trigger: trigger
        )
    }

    private static func dailyComponents(hour: Int) -> DateComponents? {
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        return components
    }

    private static func hourComponents(from date: Date, hour: Int) -> DateComponents? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = 0
        return components
    }
}
