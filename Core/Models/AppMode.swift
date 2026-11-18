import Foundation

/// Режим работы приложения. Переключение не создаёт второй профиль
/// и никогда не удаляет историю — меняется только главный экран и набор действий.
enum AppMode: String, Codable, CaseIterable, Identifiable {
    case cycleTracking = "cycle_tracking"
    case conceptionPlanning = "conception_planning"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cycleTracking: return "Отслеживание цикла"
        case .conceptionPlanning: return "Планирование беременности"
        }
    }

    var shortName: String {
        switch self {
        case .cycleTracking: return "Цикл"
        case .conceptionPlanning: return "Планирование"
        }
    }

    var description: String {
        switch self {
        case .cycleTracking:
            return "Месячные, симптомы, самочувствие и прогноз цикла"
        case .conceptionPlanning:
            return "Фертильное окно, тесты, температура и наблюдения"
        }
    }

    var iconName: String {
        switch self {
        case .cycleTracking: return "circle.circle"
        case .conceptionPlanning: return "heart.circle"
        }
    }
}

/// Уверенность прогноза. Не является медицинской оценкой.
enum PredictionConfidence: String, Codable {
    case insufficient
    case low
    case medium

    var displayName: String {
        switch self {
        case .insufficient: return "Недостаточно данных"
        case .low: return "Низкая"
        case .medium: return "Умеренная"
        }
    }
}
