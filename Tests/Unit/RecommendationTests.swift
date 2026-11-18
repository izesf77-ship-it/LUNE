import XCTest
@testable import LUNE

final class RecommendationTests: XCTestCase {

    private func day(_ y: Int, _ m: Int, _ d: Int) -> CalendarDate {
        CalendarDate(year: y, month: m, day: d)
    }

    private func prediction(confidence: PredictionConfidence, hasDelay: Bool) -> CyclePrediction {
        CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: confidence == .insufficient
                ? [day(2026, 3, 1)]
                : [day(2026, 1, 1), day(2026, 1, 29), day(2026, 2, 26)],
            today: hasDelay ? day(2026, 4, 7) : day(2026, 3, 10)
        ))
    }

    private func context(
        mode: AppMode = .cycleTracking,
        confidence: PredictionConfidence = .low,
        delay: Bool = false,
        positiveLH: Bool = false,
        positivePregnancy: Bool = false,
        negativePregnancy: Bool = false,
        symptomCounts: [SymptomType: Int] = [:],
        loggedDays: Int = 10
    ) -> RecommendationContext {
        RecommendationContext(
            mode: mode,
            prediction: prediction(confidence: confidence, hasDelay: delay),
            delayGuidance: delay ? MissedPeriodGuidance(
                scenario: .regular, title: "", detail: "", action: nil, footnote: ""
            ) : nil,
            symptomCounts: symptomCounts,
            hasPositiveLH: positiveLH,
            hasPositivePregnancyTest: positivePregnancy,
            hasNegativePregnancyTest: negativePregnancy,
            loggedDayCount: loggedDays
        )
    }

    func testEveryRecommendationHasRequiredMetadata() {
        for item in RecommendationLibrary.all {
            XCTAssertFalse(item.id.isEmpty)
            XCTAssertFalse(item.title.isEmpty)
            XCTAssertFalse(item.text.isEmpty)
            XCTAssertTrue(item.sourceURL.hasPrefix("https://"))
            XCTAssertFalse(item.medicalReviewDate.isEmpty)
            XCTAssertFalse(item.triggers.isEmpty)
        }
        XCTAssertEqual(Set(RecommendationLibrary.all.map(\.id)).count, RecommendationLibrary.all.count)
    }

    func testPlanningModeAddsPreconceptionRecommendations() {
        let items = RecommendationEngine.recommendations(for: context(mode: .conceptionPlanning))
        XCTAssertTrue(items.contains { $0.recommendation.category == .preconception })
    }

    func testPositivePregnancyTestHasHighestPriority() {
        let items = RecommendationEngine.recommendations(for: context(positivePregnancy: true, delay: true))
        XCTAssertEqual(items.first?.recommendation.id, "positive-test-confirmation")
    }

    func testUrgentInformationAlwaysPresent() {
        let items = RecommendationEngine.recommendations(for: context())
        XCTAssertTrue(items.contains { $0.recommendation.safety == .urgentInformation })
    }

    func testNoMedicationNamesOrDiagnosesInLibrary() {
        for item in RecommendationLibrary.all {
            XCTAssertFalse(item.text.localizedCaseInsensitiveContains("примите "))
            XCTAssertFalse(item.text.localizedCaseInsensitiveContains("диагноз:"))
        }
    }

    func testInsufficientHistoryRecommendation() {
        let items = RecommendationEngine.recommendations(for: context(confidence: .insufficient))
        XCTAssertTrue(items.contains { $0.recommendation.id == "history-needed" })
    }
}
