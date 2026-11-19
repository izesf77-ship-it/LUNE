import SwiftUI
import UIKit

/// LUNE Design System — длительности, кривые и тактильная обратная связь.
enum AnimationTokens {

    static let instant: Double = 0.1
    static let fast: Double = 0.2
    static let normal: Double = 0.3
    static let slow: Double = 0.4

    static let selection = Animation.easeOut(duration: fast)
    static let card = Animation.easeInOut(duration: normal)
    static let progress = Animation.easeInOut(duration: slow)
    static let modeSwitch = Animation.easeInOut(duration: normal)

    /// Возвращает nil при включённом Reduce Motion — SwiftUI корректно отключит анимацию.
    static func resolved(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }

    static func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func mediumHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func successHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func selectionHaptic() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func errorHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
