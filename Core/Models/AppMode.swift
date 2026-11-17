import Foundation

/// Режим работы приложения
enum AppMode: String, Codable, CaseIterable {
    case cycleTracking = "cycle_tracking"
    case conceptionPlanning = "conception_planning"
    
    var displayName: String {
        switch self {
        case .cycleTracking:
            return "Отслеживание цикла"
        case .conceptionPlanning:
            return "Планирование беременности"
        }
    }
    
    var description: String {
        switch self {
        case .cycleTracking:
            return "Отслеживайте менструальный цикл, симптомы и прогнозируйте следующие месячные"
        case .conceptionPlanning:
            return "Определяйте фертильное окно, отслеживайте овуляцию и планируйте зачатие"
        }
    }
    
    var iconName: String {
        switch self {
        case .cycleTracking:
            return "calendar.circle.fill"
        case .conceptionPlanning:
            return "heart.circle.fill"
        }
    }
}
