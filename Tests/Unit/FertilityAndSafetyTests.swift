import XCTest
@testable import LUNE

final class FertilityAndSafetyTests: XCTestCase {

    private func day(_ y: Int, _ m: Int, _ d: Int) -> CalendarDate {
        CalendarDate(year: y, month: m, day: d)
    }

    private func basePrediction(today: CalendarDate) -> CyclePrediction {
        CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: [day(2026, 1, 1), day(2026, 1, 29), day(2026, 2, 26), day(2026, 3, 26)],
            today: today
        ))
    }

    func testCalendarEstimateIsSeparatedFromObservations() {
        let snapshot = FertilityInsightsEngine.makeSnapshot(FertilityInput(
            prediction: basePrediction(today: day(2026, 4, 5)),
            today: day(2026, 4, 5)
        ))
        XCTAssertTrue(snapshot.insights.contains { $0.kind == .calendarEstimate })
        XCTAssertTrue(snapshot.disclaimers.contains { $0.contains("не подтверждает") })
        XCTAssertFalse(snapshot.insights.contains { $0.title.contains("подтверждена") })
    }

    func testPositiveLHIsObservedSignNotProof() {
        let snapshot = FertilityInsightsEngine.makeSnapshot(FertilityInput(
            prediction: basePrediction(today: day(2026, 4, 5)),
            today: day(2026, 4, 5),
            lhTests: [(day(2026, 4, 4), .positive)]
        ))
        let lh = snapshot.insights.first { $0.id == "lh-positive" }
        XCTAssertNotNil(lh)
        XCTAssertEqual(lh?.kind, .observedSign)
        XCTAssertTrue(lh?.caution?.contains("не доказывает") == true)
    }

    func testNegativeLHGivesNoPositiveClaim() {
        let snapshot = FertilityInsightsEngine.makeSnapshot(FertilityInput(
            prediction: basePrediction(today: day(2026, 4, 5)),
            today: day(2026, 4, 5),
            lhTests: [(day(2026, 4, 4), .negative)]
        ))
        XCTAssertNil(snapshot.insights.first { $0.id == "lh-positive" })
    }

    func testTemperatureTrendRequiresEnoughData() {
        let few = FertilityInsightsEngine.temperatureTrend(
            [(day(2026, 4, 1), 36.5), (day(2026, 4, 2), 36.6)],
            today: day(2026, 4, 5)
        )
        XCTAssertEqual(few, .insufficientData)

        let rising = (1...6).map { (day(2026, 4, $0), $0 <= 3 ? 36.4 : 36.8) }
        XCTAssertEqual(FertilityInsightsEngine.temperatureTrend(rising, today: day(2026, 4, 6)), .possibleRetrospectiveRise)

        let flat = (1...6).map { (day(2026, 4, $0), 36.5) }
        XCTAssertEqual(FertilityInsightsEngine.temperatureTrend(flat, today: day(2026, 4, 6)), .noClearPattern)
    }

    func testPositivePregnancyTestScenario() {
        let prediction = CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: [day(2026, 1, 1), day(2026, 1, 29), day(2026, 2, 26)],
            today: day(2026, 4, 7)
        ))
        let guidance = MissedPeriodEvaluator.evaluate(
            prediction: prediction,
            today: day(2026, 4, 7),
            pregnancyTests: [(day(2026, 4, 5), .positive)],
            hasLoggingGap: false
        )
        XCTAssertEqual(guidance?.scenario, .positiveTest)
        XCTAssertTrue(guidance?.detail.contains("не является диагнозом") == true)
    }

    func testNegativeTestAndProlongedDelayScenarios() {
        let prediction = CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: [day(2026, 1, 1), day(2026, 1, 29), day(2026, 2, 26)],
            today: day(2026, 4, 7)
        ))
        let negative = MissedPeriodEvaluator.evaluate(
            prediction: prediction,
            today: day(2026, 4, 7),
            pregnancyTests: [(day(2026, 4, 5), .negative)],
            hasLoggingGap: false
        )
        XCTAssertEqual(negative?.scenario, .negativeTest)

        let longDelay = CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: [day(2026, 1, 1), day(2026, 1, 29), day(2026, 2, 26)],
            today: day(2026, 4, 20)
        ))
        let prolonged = MissedPeriodEvaluator.evaluate(
            prediction: longDelay,
            today: day(2026, 4, 20),
            pregnancyTests: [],
            hasLoggingGap: false
        )
        XCTAssertEqual(prolonged?.scenario, .prolongedDelay)

        let gap = MissedPeriodEvaluator.evaluate(
            prediction: prediction,
            today: day(2026, 4, 7),
            pregnancyTests: [],
            hasLoggingGap: true
        )
        XCTAssertEqual(gap?.scenario, .missingEntries)
    }

    func testNoDiagnosisWording() {
        let prediction = basePrediction(today: day(2026, 4, 7))
        let guidance = MissedPeriodEvaluator.evaluate(
            prediction: prediction,
            today: day(2026, 4, 7),
            pregnancyTests: [],
            hasLoggingGap: false
        )
        let all = (guidance?.title ?? "") + (guidance?.detail ?? "") + (guidance?.action ?? "")
        XCTAssertFalse(all.contains("овуляция подтверждена"))
        XCTAssertFalse(all.contains("беременность подтверждена"))
        XCTAssertFalse(all.contains("безопасный день"))
    }
}
