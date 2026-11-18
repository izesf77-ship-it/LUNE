import XCTest
@testable import LUNE

final class OnboardingTests: XCTestCase {

    private func day(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            year: y, month: m, day: d, hour: hour, minute: 0
        ))!
    }

    func testFutureDatesAreClampedToToday() {
        let today = CalendarDate(year: 2026, month: 11, day: 18)
        var draft = OnboardingDraft()
        draft.lastPeriodConfirmed = true
        draft.hasLastPeriod = true
        draft.lastPeriodDate = day(2026, 11, 25)
        draft.historyDates = [day(2026, 11, 24), day(2026, 11, 10)]

        let starts = OnboardingDataNormalizer.periodStarts(from: draft, today: today)

        XCTAssertEqual(starts, [day(2026, 11, 10).calendarDate, today])
    }

    func testHistoryIsDeduplicatedAndSorted() {
        let today = CalendarDate(year: 2026, month: 11, day: 18)
        var draft = OnboardingDraft()
        // Один и тот же календарный день с разным временем — не две записи.
        draft.historyDates = [
            day(2026, 10, 2, hour: 9),
            day(2026, 9, 4),
            day(2026, 10, 2, hour: 22),
            day(2026, 9, 4, hour: 18)
        ]

        let starts = OnboardingDataNormalizer.periodStarts(from: draft, today: today)

        XCTAssertEqual(starts.count, 2)
        XCTAssertEqual(starts, [CalendarDate(year: 2026, month: 9, day: 4),
                                CalendarDate(year: 2026, month: 10, day: 2)])
    }

    func testUnconfirmedLastPeriodIsNotSaved() {
        let today = CalendarDate(year: 2026, month: 11, day: 18)
        var draft = OnboardingDraft()
        draft.hasLastPeriod = true
        draft.lastPeriodDate = day(2026, 11, 12)
        // Пользователь не подтверждал шаг — дата не становится фактом.
        XCTAssertTrue(OnboardingDataNormalizer.periodStarts(from: draft, today: today).isEmpty)
    }

    func testSkipKeepsAlreadyEnteredValues() {
        var draft = OnboardingDraft()
        draft.mode = .conceptionPlanning
        draft.cycleLength = 30
        draft.periodDuration = 5
        draft.notificationsOn = true
        draft.faceIDOn = true
        draft.historyDates = [day(2026, 10, 1)]

        // Нет никакого флага «пропустить»: все введённые значения сохраняются.
        let values = OnboardingDataNormalizer.profileValues(from: draft)

        XCTAssertEqual(values.mode, .conceptionPlanning)
        XCTAssertEqual(values.typicalCycleLength, 30)
        XCTAssertEqual(values.typicalPeriodDuration, 5)
        XCTAssertTrue(values.notificationsEnabled)
        XCTAssertTrue(values.faceIDRequested)
        XCTAssertEqual(OnboardingDataNormalizer.periodStarts(from: draft, today: CalendarDate(year: 2026, month: 11, day: 18)).count, 1)
    }

    func testInvalidDurationsAreRejected() {
        XCTAssertEqual(OnboardingDataNormalizer.validatedCycleLength(28), 28)
        XCTAssertNil(OnboardingDataNormalizer.validatedCycleLength(3))
        XCTAssertNil(OnboardingDataNormalizer.validatedCycleLength(400))
        XCTAssertEqual(OnboardingDataNormalizer.validatedPeriodDuration(5), 5)
        XCTAssertNil(OnboardingDataNormalizer.validatedPeriodDuration(0))
    }

    func testMonthLengthIsIndependentOfTimeZone() {
        XCTAssertEqual(CalendarDate.daysInMonth(year: 2024, month: 2), 29)
        XCTAssertEqual(CalendarDate.daysInMonth(year: 2025, month: 2), 28)
        XCTAssertEqual(CalendarDate.daysInMonth(year: 2026, month: 11), 30)

        let utc = ISO8601DateFormatter()
        utc.timeZone = TimeZone(secondsFromGMT: 0)
        let instant = utc.date(from: "2026-11-01T00:00:00Z")!
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(secondsFromGMT: 9 * 3600)!
        let localDay = CalendarDate(instant, calendar: tokyo)
        XCTAssertEqual(localDay.key, "2026-11-01")
        XCTAssertEqual(CalendarDate.daysInMonth(year: localDay.year, month: localDay.month), 30)
    }
}

private extension Date {
    var calendarDate: CalendarDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return CalendarDate(self, calendar: calendar)
    }
}
