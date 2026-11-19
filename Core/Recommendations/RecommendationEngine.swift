import Foundation

// MARK: - Domain

enum RecommendationCategory: String, Codable, CaseIterable {
    case menstrualHealth
    case symptomTracking
    case preconception
    case testInterpretation
    case generalWellbeing
    case whenToSeeDoctor

    var displayName: String {
        switch self {
        case .menstrualHealth: return "Менструальное здоровье"
        case .symptomTracking: return "Отслеживание симптомов"
        case .preconception: return "Подготовка к беременности"
        case .testInterpretation: return "Интерпретация тестов"
        case .generalWellbeing: return "Общие рекомендации по самочувствию"
        case .whenToSeeDoctor: return "Когда обратиться к врачу"
        }
    }
}

enum SafetyClassification: String, Codable {
    case informational
    case urgentInformation
}

/// Локальная рекомендация. Никаких персональных медицинских утверждений.
struct Recommendation: Identifiable, Codable {
    let id: String
    let category: RecommendationCategory
    let triggers: [RecommendationTrigger]
    let priority: Int
    let title: String
    let text: String
    let sourceURL: String
    let medicalReviewDate: String
    let safety: SafetyClassification

    enum RecommendationTrigger: String, Codable {
        case always
        case insufficientHistory
        case irregularCycle
        case delay
        case positiveLH
        case positivePregnancyTest
        case negativePregnancyTest
        case frequentPain
        case frequentHeadache
        case planningMode
        case fewSymptomsLogged
    }
}

struct RecommendationContext {
    let mode: AppMode
    let prediction: CyclePrediction
    let delayGuidance: MissedPeriodGuidance?
    let symptomCounts: [SymptomType: Int]
    let hasPositiveLH: Bool
    let hasPositivePregnancyTest: Bool
    let hasNegativePregnancyTest: Bool
    let loggedDayCount: Int

    func has(_ trigger: Recommendation.RecommendationTrigger) -> Bool {
        switch trigger {
        case .always: return true
        case .insufficientHistory: return prediction.confidence == .insufficient
        case .irregularCycle: return prediction.irregular
        case .delay: return delayGuidance != nil
        case .positiveLH: return hasPositiveLH
        case .positivePregnancyTest: return hasPositivePregnancyTest
        case .negativePregnancyTest: return hasNegativePregnancyTest
        case .frequentPain:
            return (symptomCounts[.pain] ?? 0) >= 3 || (symptomCounts[.backPain] ?? 0) >= 3
        case .frequentHeadache: return (symptomCounts[.headache] ?? 0) >= 3
        case .planningMode: return mode == .conceptionPlanning
        case .fewSymptomsLogged: return loggedDayCount < 5
        }
    }
}

struct PresentedRecommendation: Identifiable {
    var id: String { recommendation.id }
    let recommendation: Recommendation
    let matchedTrigger: Recommendation.RecommendationTrigger
}

// MARK: - Engine

/// Полностью локальный движок правил. Не обращается к сети.
enum RecommendationEngine {

    static func recommendations(for context: RecommendationContext) -> [PresentedRecommendation] {
        var result: [PresentedRecommendation] = []

        for item in RecommendationLibrary.all {
            guard let matched = item.triggers.first(where: { context.has($0) }) else { continue }
            result.append(PresentedRecommendation(recommendation: item, matchedTrigger: matched))
        }

        return result.sorted {
            if $0.recommendation.priority != $1.recommendation.priority {
                return $0.recommendation.priority > $1.recommendation.priority
            }
            return $0.recommendation.id < $1.recommendation.id
        }
    }
}

// MARK: - Built-in medical knowledge library

/// Источники — общедоступные проверенные материалы NHS. Тексты адаптированы
/// и не являются медицинским советом. Дата проверки указана для каждой записи.
enum RecommendationLibrary {

    static let all: [Recommendation] = [
        Recommendation(
            id: "period-basics",
            category: .menstrualHealth,
            triggers: [.always],
            priority: 10,
            title: "Как меняется менструальный цикл",
            text: "Длительность цикла может немного различаться от месяца к месяцу. Прогноз в LUNE основан на ваших предыдущих датах и показывает ориентировочный диапазон, а не точную дату.",
            sourceURL: "https://www.nhs.uk/conditions/menstruation/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "track-consistently",
            category: .symptomTracking,
            triggers: [.fewSymptomsLogged],
            priority: 20,
            title: "Важность регулярных записей",
            text: "Чем больше дней вы отмечаете, тем нагляднее становится ваша личная картина самочувствия. Пропущенные дни можно добавить позже.",
            sourceURL: "https://www.nhs.uk/conditions/menstruation/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "history-needed",
            category: .menstrualHealth,
            triggers: [.insufficientHistory],
            priority: 60,
            title: "Пока мало данных цикла",
            text: "Для оценки регулярности обычно нужно несколько записанных циклов. Прогноз станет информативнее после новых отметок о начале менструаций.",
            sourceURL: "https://www.nhs.uk/conditions/menstruation/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "irregular-cycle",
            category: .menstrualHealth,
            triggers: [.irregularCycle],
            priority: 55,
            title: "Если циклы сильно различаются",
            text: "Разброс длительности циклов делает календарную оценку менее точной. Если это постоянно вас беспокоит, обсудите особенности цикла со специалистом.",
            sourceURL: "https://www.nhs.uk/conditions/irregular-periods/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "test-from-expected-day",
            category: .testInterpretation,
            triggers: [.delay],
            priority: 65,
            title: "Когда делать домашний тест",
            text: "Домашний тест на беременность обычно можно сделать с первого дня ожидаемой менструации. Если результат отрицательный, а месячные не начались, повторите тест через неделю.",
            sourceURL: "https://www.nhs.uk/pregnancy/trying-for-a-baby/testing-for-pregnancy/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "negative-test-followup",
            category: .testInterpretation,
            triggers: [.negativePregnancyTest, .delay],
            priority: 70,
            title: "Отрицательный результат и отсутствие месячных",
            text: "Отрицательный тест может быть получен слишком рано. Если месячные не начались, повторите тест позже или обратитесь к врачу — по симптомам сделать вывод нельзя.",
            sourceURL: "https://www.nhs.uk/pregnancy/trying-for-a-baby/testing-for-pregnancy/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "positive-test-confirmation",
            category: .testInterpretation,
            triggers: [.positivePregnancyTest],
            priority: 90,
            title: "После положительного результата",
            text: "Положительный домашний тест требует медицинского подтверждения и наблюдения. Запись в приложении не является диагнозом и не заменяет визит к врачу.",
            sourceURL: "https://www.nhs.uk/pregnancy/trying-for-a-baby/testing-for-pregnancy/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "lh-test-interpretation",
            category: .testInterpretation,
            triggers: [.positiveLH],
            priority: 50,
            title: "Что означает положительный ЛГ-тест",
            text: "Положительный результат может указывать на приближение овуляции, но не доказывает, что она произошла. Календарная оценка и тест — разные источники информации.",
            sourceURL: "https://www.nhs.uk/conditions/ovulation/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "pain-selfcare",
            category: .symptomTracking,
            triggers: [.frequentPain],
            priority: 45,
            title: "Частые болевые ощущения",
            text: "Отмечайте интенсивность боли и сопутствующие симптомы — это поможет обсудить картину со специалистом. Не начинайте приём препаратов без консультации.",
            sourceURL: "https://www.nhs.uk/conditions/period-pain/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "headache-tracking",
            category: .symptomTracking,
            triggers: [.frequentHeadache],
            priority: 40,
            title: "Головные боли в дневнике",
            text: "Записывайте частоту и интенсивность головной боли вместе с другими симптомами. Это не заменяет медицинскую оценку, но делает наблюдение полезнее.",
            sourceURL: "https://www.nhs.uk/conditions/headaches/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "preconception-folic",
            category: .preconception,
            triggers: [.planningMode],
            priority: 58,
            title: "Подготовка к беременности",
            text: "При планировании беременности полезно заранее обсудить с врачом образ жизни и необходимые обследования. Следуйте рекомендациям специалиста, а не универсальным советам из приложения.",
            sourceURL: "https://www.nhs.uk/pregnancy/trying-for-a-baby/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "fertility-window-caution",
            category: .preconception,
            triggers: [.planningMode],
            priority: 35,
            title: "Оценка фертильного окна",
            text: "Фертильное окно в LUNE — ориентировочная календарная оценка вместе с вашими наблюдениями. Она не подтверждает овуляцию и не является методом предотвращения беременности.",
            sourceURL: "https://www.nhs.uk/conditions/ovulation/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        ),
        Recommendation(
            id: "seek-care-heavy-bleeding",
            category: .whenToSeeDoctor,
            triggers: [.always],
            priority: 5,
            title: "Когда нужна медицинская помощь",
            text: "Обильное кровотечение, сильная боль, головокружение или обморочное состояние — поводы обратиться за медицинской помощью. При выраженных симптомах не откладывайте визит.",
            sourceURL: "https://www.nhs.uk/conditions/heavy-periods/",
            medicalReviewDate: "2025-03-01",
            safety: .urgentInformation
        ),
        Recommendation(
            id: "seek-care-prolonged-delay",
            category: .whenToSeeDoctor,
            triggers: [.delay],
            priority: 75,
            title: "Продолжительное отсутствие месячных",
            text: "Если месячные не начинаются в течение нескольких недель, обратитесь к врачу, чтобы обсудить возможные причины. Календарь не может объяснить задержку.",
            sourceURL: "https://www.nhs.uk/conditions/irregular-periods/",
            medicalReviewDate: "2025-03-01",
            safety: .informational
        )
    ]
}
