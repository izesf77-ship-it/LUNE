import SwiftUI

/// Дизайн-система LUNÉ: Анимации и transitions
struct AnimationTokens {
    
    // MARK: - Duration
    
    static let instant: Double = 0.1
    static let fast: Double = 0.2
    static let normal: Double = 0.3
    static let slow: Double = 0.4
    static let verySlow: Double = 0.6
    
    // MARK: - Easing
    
    static let easeOut = Animation.easeOut(duration: normal)
    static let easeInOut = Animation.easeInOut(duration: normal)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    
    // MARK: - Preset Animations
    
    /// Анимация для selection
    static let selection = Animation.easeOut(duration: fast)
    
    /// Анимация для card transitions
    static let cardTransition = Animation.easeInOut(duration: normal)
    
    /// Анимация для progress changes
    static let progressChange = Animation.easeInOut(duration: slow)
    
    /// Анимация для modal presentation
    static let modalPresentation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    /// Анимация для tab switching
    static let tabSwitch = Animation.easeOut(duration: fast)
    
    // MARK: - Haptic Feedback
    
    static func hapticLight() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func hapticMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func hapticSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Accessibility Support

extension AnimationTokens {
    
    /// Проверяет настройку Reduce Motion
    static var respectsReduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Возвращает анимацию с учётом Reduce Motion
    static func animation(_ animation: Animation) -> Animation? {
        respectsReduceMotion ? nil : animation
    }
}
