import XCTest
@testable import LUNE

final class CyclePredictionTests: XCTestCase {

    private func day(_ y: Int, _ m: Int, _ d: Int) -> CalendarDate {
        CalendarDate(year: y, month: m, day: d)
    }

    func testPeriodStartAndDuration() {
        let start = day(2026, 11, 1)
        let end = day(2026, 11, 5)
        let period = MenstrualPeriod(startDay: start, endDay: end)
        XCTAssertEqual(period.duration, 5)
        XCTAssertTrue(period.contains(day(2026, 11, 3)))
        XCTAssertFalse(period.contains(day(2026, 11, 6)))
        XCTAssertFalse(period.contains(day(2026, 10, 31)))
    }

    func testOngoingPeriodAndReportedDuration() {
        let start = day(2026, 11, 1)
        let open = MenstrualPeriod(startDay: start)
        XCTAssertNil(open.duration)
        XCTAssertTrue(open.contains(start))

        let reported = MenstrualPeriod(startDay: start, userReportedDuration: 5)
        XCTAssertEqual(reported.duration, 5)
    }

    func testSeveralCyclesProduceMedian() {
        let starts = [day(2026, 5, 1), day(2026, 5, 29), day(2026, 6, 26), day(2026, 7, 24)]
        let prediction = CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: starts,
            today: day(2026, 7, 28)
        ))
        XCTAssertEqual(prediction.cycleLength, 28)
        XCTAssertEqual(prediction.sampleCount, 3)
        XCTAssertEqual(prediction.currentDay, 5)
        XCTAssertFalse(prediction.hasDelay)
    }

    func testIrregularCycleIncreasesSpread() {
        let starts = [day(2026, 1, 1), day(2026, 1, 30), day(2026, 3, 5), day(2026, 3, 20)]
        let prediction = CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: starts,
            today: day(2026, 3, 22)
        ))
        XCTAssertGreaterThan(prediction.cycleLengthSpread, 5)
        XCTAssertGreaterThan(prediction.nextStartRange.lowerBound.days(until: prediction.nextStartRange.upperBound), 4)
    }

    func testDelayIsDetectedWithoutPregnancyConclusion() {
        let starts = [day(2026, 1, 1), day(2026, 1, 29), day(2026, 2, 26)]
        let prediction = CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: starts,
            today: day(2026, 4, 7)
        ))
        XCTAssertEqual(prediction.delayDays, 12)
        XCTAssertTrue(prediction.hasDelay)
        XCTAssertTrue(prediction.shortForecast.contains("назад"))

        let guidance = MissedPeriodEvaluator.evaluate(
            prediction: prediction,
            today: day(2026, 4, 7),
            pregnancyTests: [],
            hasLoggingGap: false
        )
        XCTAssertNotNil(guidance)
        XCTAssertNotEqual(guidance?.scenario, .positiveTest)
    }

    func testInsufficientHistoryDoesNotFakePrecision() {
        let prediction = CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: [day(2026, 3, 1)],
            today: day(2026, 3, 20)
        ))
        XCTAssertEqual(prediction.confidence, .insufficient)
        XCTAssertGreaterThan(prediction.nextStartRange.lowerBound.days(until: prediction.nextStartRange.upperBound), 8)
        XCTAssertTrue(prediction.explanation.contains("Недостаточно"))
    }

    func testEditingPastRecordUpdatesPrediction() {
        let original = [day(2026, 1, 1), day(2026, 1, 29), day(2026, 2, 26)]
        let before = CyclePredictionEngine.predict(CyclePredictionInput(confirmedStarts: original, today: day(2026, 3, 5)))

        var edited = original
        edited[2] = day(2026, 3, 5) // исправлена ошибочная запись
        let after = CyclePredictionEngine.predict(CyclePredictionInput(confirmedStarts: edited, today: day(2026, 3, 5)))

        XCTAssertNotEqual(before.cycleLength, after.cycleLength)
        XCTAssertNotEqual(before.nextStart, after.nextStart)
    }

    func testErroneousIntervalsAreIgnored() {
        let starts = [day(2026, 1, 1), day(2026, 1, 29), day(2026, 1, 31), day(2026, 2, 26)]
        let prediction = CyclePredictionEngine.predict(CyclePredictionInput(
            confirmedStarts: starts,
            today: day(2026, 3, 1)
        ))
        XCTAssertEqual(prediction.sampleCount, 2)
        XCTAssertEqual(prediction.cycleLength, 27)
    }

    func testMonthAndLeapYearTransitions() {
        XCTAssertEqual(day(2024, 2, 28).days(until: day(2024, 3, 1)), 2)
        XCTAssertEqual(day(2025, 2, 28).days(until: day(2025, 3, 1)), 1)
        XCTAssertEqual(day(2026, 12, 31).adding(days: 1).key, "2027-01-01")
        XCTAssertEqual(day(2024, 2, 29).adding(days: 365).key, "2025-02-28")
    }

    func testTimeZoneIndependenceOfCalendarDate() {
        let utc = ISO8601DateFormatter()
        utc.timeZone = TimeZone(secondsFromGMT: 0)
        let date = utc.date(from: "2026-11-18T23:30:00Z")!

        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(secondsFromGMT: 9 * 3600)!
        var la = Calendar(identifier: .gregorian)
        la.timeZone = TimeZone(secondsFromGMT: -8 * 3600)!

        let inTokyo = CalendarDate(date, calendar: tokyo)
        let inLA = CalendarDate(date, calendar: la)
        XCTAssertEqual(inTokyo.key, "2026-11-19")
        XCTAssertEqual(inLA.key, "2026-11-18")

        // Ключ дня стабилен и не зависит от часового пояса при сохранении.
        XCTAssertEqual(CalendarDate(key: inTokyo.key)?.key, "2026-11-19")
        XCTAssertEqual(CalendarDate(key: inLA.key)?.key, "2026-11-18")
    }

    func testMedianWithEvenCount() {
        XCTAssertEqual(CyclePredictionEngine.median([28, 30]), 29)
        XCTAssertEqual(CyclePredictionEngine.median([26, 28, 30]), 28)
        XCTAssertNil(CyclePredictionEngine.median([]))
    }
}
