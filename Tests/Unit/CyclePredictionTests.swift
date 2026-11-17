import XCTest
@testable import LUNE

/// Тесты для прогнозирования менструального цикла
final class CyclePredictionTests: XCTestCase {
    
    func testBasicCycleCalculation() {
        // Given: типичный 28-дневный цикл
        let calendar = Calendar.current
        let today = Date()
        let lastPeriodStart = calendar.date(byAdding: .day, value: -10, to: today)!
        
        // When: рассчитываем текущий день цикла
        let components = calendar.dateComponents([.day], from: lastPeriodStart, to: today)
        let cycleDay = (components.day ?? 0) + 1
        
        // Then: должен быть 11-й день
        XCTAssertEqual(cycleDay, 11, "Текущий день цикла рассчитан неверно")
    }
    
    func testPeriodDurationCalculation() {
        // Given: период с 1 по 5 число
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2026, month: 11, day: 5))!
        
        // When: создаём период
        let period = MenstrualPeriod(startDate: startDate, endDate: endDate, isConfirmed: true)
        
        // Then: длительность должна быть 5 дней
        XCTAssertEqual(period.duration, 5, "Длительность периода рассчитана неверно")
    }
    
    func testPeriodContainsDate() {
        // Given: период с 1 по 5 число
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2026, month: 11, day: 5))!
        let period = MenstrualPeriod(startDate: startDate, endDate: endDate, isConfirmed: true)
        
        // When/Then: проверяем различные даты
        let day3 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 3))!
        XCTAssertTrue(period.contains(date: day3), "День 3 должен быть в периоде")
        
        let day6 = calendar.date(from: DateComponents(year: 2026, month: 11, day: 6))!
        XCTAssertFalse(period.contains(date: day6), "День 6 не должен быть в периоде")
        
        let dayBefore = calendar.date(from: DateComponents(year: 2026, month: 10, day: 31))!
        XCTAssertFalse(period.contains(date: dayBefore), "День до периода не должен быть в периоде")
    }
    
    func testOngoingPeriod() {
        // Given: период без даты окончания
        let startDate = Date()
        let period = MenstrualPeriod(startDate: startDate, endDate: nil, isConfirmed: true)
        
        // Then: длительность должна быть nil
        XCTAssertNil(period.duration, "Незавершённый период не должен иметь длительности")
        
        // And: сегодняшняя дата должна содержаться
        XCTAssertTrue(period.contains(date: Date()), "Незавершённый период должен содержать сегодня")
    }
    
    func testLeapYear() {
        // Given: високосный год 2024
        let calendar = Calendar.current
        let feb28_2024 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 28))!
        let mar1_2024 = calendar.date(from: DateComponents(year: 2024, month: 3, day: 1))!
        
        // When: считаем разницу
        let components = calendar.dateComponents([.day], from: feb28_2024, to: mar1_2024)
        
        // Then: должно быть 2 дня (29 февраля существует)
        XCTAssertEqual(components.day, 2, "Високосный год обработан неверно")
    }
}
