import Foundation
import SwiftUI
import SwiftData

/// Глобальное состояние приложения. Единственный профиль на оба режима.
@MainActor
final class AppState: ObservableObject {

    @Published var isLoading = true
    @Published var isLocked = false
    @Published var profile: UserProfile?
    @Published var revision = 0
    @Published var toast: String?
    @Published var appearance: Int = UserDefaults.standard.integer(forKey: "lune.appearance") {
        didSet { UserDefaults.standard.set(appearance, forKey: "lune.appearance") }
    }

    private let database = DatabaseManager.shared
    private var toastTask: Task<Void, Never>?

    var colorScheme: ColorScheme? {
        switch appearance {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var mode: AppMode { profile?.mode ?? .cycleTracking }

    func initialize() async {
        profile = database.fetchOrCreateProfile()
        try? await Task.sleep(nanoseconds: 450_000_000)

        if profile?.faceIDEnabled == true {
            isLocked = !(await BiometricAuth.authenticate(
                reason: "Подтвердите доступ к вашим данным LUNÉ"
            ))
        }
        isLoading = false
    }

    func unlock() async {
        if await BiometricAuth.authenticate() {
            isLocked = false
        }
    }

    // MARK: - Data

    var prediction: CyclePrediction {
        let periods = database.all(MenstrualPeriod.self)
        return CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: periods.map(\.startDay),
            today: CalendarDate(Date()),
            reportedCycleLength: profile?.typicalCycleLength,
            reportedPeriodDuration: profile?.typicalPeriodDuration,
            knownDurations: periods.compactMap(\.duration)
        ))
    }

    var hasLoggingGap: Bool {
        let days = Set(database.all(DailySymptomEntry.self).map(\.dayKey))
            .union(database.all(DailyMoodEntry.self).map(\.dayKey))
        let last = database.periods().first?.startDay ?? CalendarDate(Date())
        let span = last.days(until: CalendarDate(Date()))
        return span > 10 && days.count < max(2, span / 4)
    }

    var pregnancyTests: [(day: CalendarDate, result: TestResult)] {
        database.all(PregnancyTestEntry.self)
            .map { ($0.day, $0.result) }
            .sorted { $0.0 < $1.0 }
    }

    var delayGuidance: MissedPeriodGuidance? {
        MissedPeriodEvaluator.evaluate(
            prediction: prediction,
            today: CalendarDate(Date()),
            pregnancyTests: pregnancyTests,
            hasLoggingGap: hasLoggingGap
        )
    }

    var fertilitySnapshot: FertilitySnapshot {
        FertilityInsightsEngine.makeSnapshot(FertilityInput(
            prediction: prediction,
            today: CalendarDate(Date()),
            lhTests: database.all(LHTestEntry.self).map { ($0.day, $0.result) },
            temperatures: database.all(BasalTemperatureEntry.self).map { ($0.day, $0.celsius) },
            mucus: database.all(CervicalMucusEntry.self).map { ($0.day, $0.type) }
        ))
    }

    var recommendationContext: RecommendationContext {
        let symptoms = database.all(DailySymptomEntry.self)
        var counts: [SymptomType: Int] = [:]
        for entry in symptoms { counts[entry.symptom, default: 0] += 1 }
        let loggedDays = Set(symptoms.map(\.dayKey))
            .union(database.all(DailyMoodEntry.self).map(\.dayKey))
            .union(database.all(DailyWellbeingEntry.self).map(\.dayKey))

        return RecommendationContext(
            mode: mode,
            prediction: prediction,
            delayGuidance: delayGuidance,
            symptomCounts: counts,
            hasPositiveLH: database.all(LHTestEntry.self).contains { $0.result == .positive },
            hasPositivePregnancyTest: database.all(PregnancyTestEntry.self).contains { $0.result == .positive },
            hasNegativePregnancyTest: database.all(PregnancyTestEntry.self).contains { $0.result == .negative },
            loggedDayCount: loggedDays.count
        )
    }

    func refresh() {
        profile?.touch()
        database.save()
        revision += 1
    }

    // MARK: - Actions

    func switchMode(to mode: AppMode) {
        profile?.mode = mode
        refresh()
        AnimationTokens.successHaptic()
    }

    func completeOnboarding() {
        profile?.hasCompletedOnboarding = true
        refresh()
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        toast = message
        AnimationTokens.successHaptic()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else { return }
            toast = nil
        }
    }

    func requestNotificationAuthorizationIfNeeded() async {
        guard profile?.notificationsEnabled == true else { return }
        _ = await NotificationService.authorizationStatus()
    }
}
