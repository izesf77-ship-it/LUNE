import XCTest
import SwiftData
@testable import LUNE

final class PersistenceIntegrationTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: LuneSchemaV2.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    func testModeSwitchKeepsWholeHistory() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let profile = UserProfile()
        context.insert(profile)
        let first = MenstrualPeriod(startDay: CalendarDate(year: 2026, month: 1, day: 1))
        let second = MenstrualPeriod(startDay: CalendarDate(year: 2026, month: 1, day: 29))
        context.insert(first)
        context.insert(second)
        context.insert(DailySymptomEntry(
            day: CalendarDate(year: 2026, month: 1, day: 3),
            symptom: .pain,
            intensity: 2
        ))
        try context.save()

        profile.mode = .conceptionPlanning
        try context.save()
        XCTAssertEqual(profile.mode, .conceptionPlanning)

        let periods = try context.fetch(FetchDescriptor<MenstrualPeriod>())
        XCTAssertEqual(periods.count, 2)

        profile.mode = .cycleTracking
        try context.save()

        let periodsAgain = try context.fetch(FetchDescriptor<MenstrualPeriod>())
        let symptoms = try context.fetch(FetchDescriptor<DailySymptomEntry>())
        let profiles = try context.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(periodsAgain.count, 2)
        XCTAssertEqual(symptoms.count, 1)
        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.mode, .cycleTracking)
    }

    func testDayKeyedRecordsAreFetchedByCalendarKey() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let day = CalendarDate(year: 2026, month: 2, day: 28)
        context.insert(DailyMoodEntry(day: day, mood: .calm))
        context.insert(DailyMoodEntry(day: day.adding(days: 1), mood: .happy))
        try context.save()

        let all = try context.fetch(FetchDescriptor<DailyMoodEntry>())
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all.filter { $0.dayKey == day.key }.count, 1)
    }

    func testDeleteAllModelsLeavesCleanStore() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(UserProfile())
        context.insert(DailyNote(day: CalendarDate(year: 2026, month: 3, day: 1), text: "Заметка"))
        context.insert(MenstrualPeriod(startDay: CalendarDate(year: 2026, month: 3, day: 1)))
        try context.save()

        try context.delete(model: UserProfile.self)
        try context.delete(model: DailyNote.self)
        try context.delete(model: MenstrualPeriod.self)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<UserProfile>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<DailyNote>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MenstrualPeriod>()), 0)
    }

    func testMigrationPlanContainsTwoSchemas() {
        XCTAssertEqual(LuneMigrationPlan.schemas.count, 2)
        XCTAssertEqual(LuneMigrationPlan.stages.count, 1)
        XCTAssertEqual(LuneSchemaV2.models.count, 17)
    }

    func testModelValidationClampsInvalidValues() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let symptom = DailySymptomEntry(
            day: CalendarDate(year: 2026, month: 4, day: 1),
            symptom: .pain,
            intensity: 999
        )
        let temperature = BasalTemperatureEntry(
            day: CalendarDate(year: 2026, month: 4, day: 1),
            celsius: 60
        )
        let note = DailyNote(day: CalendarDate(year: 2026, month: 4, day: 1), text: "")
        context.insert(symptom)
        context.insert(temperature)
        context.insert(note)
        try context.save()

        XCTAssertEqual(symptom.intensity, 3)
        XCTAssertEqual(temperature.celsius, 42)
        XCTAssertEqual(temperature.isValid, false)
        XCTAssertEqual(note.text, "")
    }
}
