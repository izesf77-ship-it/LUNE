import Foundation
import SwiftData

/// Менструальный период
@Model
final class MenstrualPeriod {
    
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    /// Дата начала менструации
    var startDate: Date
    
    /// Дата окончания менструации (nil если ещё не закончилась)
    var endDate: Date?
    
    /// Является ли подтверждённой (true) или прогнозируемой (false)
    var isConfirmed: Bool
    
    /// Заметки
    var notes: String?
    
    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        isConfirmed: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.startDate = startDate
        self.endDate = endDate
        self.isConfirmed = isConfirmed
        self.notes = notes
    }
    
    /// Длительность периода в днях
    var duration: Int? {
        guard let endDate = endDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1
    }
    
    /// Проверяет, содержится ли дата в периоде
    func contains(date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        let startOfPeriod = calendar.startOfDay(for: startDate)
        
        if let endDate = endDate {
            let endOfPeriod = calendar.startOfDay(for: endDate)
            return startOfDate >= startOfPeriod && startOfDate <= endOfPeriod
        } else {
            return startOfDate == startOfPeriod
        }
    }
    
    func updateTimestamp() {
        updatedAt = Date()
    }
}
