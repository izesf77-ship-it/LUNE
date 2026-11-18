import SwiftUI
import UIKit

/// LUNÉ Design System — семантические цветовые токены.
/// Каждый токен — динамический UIColor, поэтому light/dark variant
/// выбирается системой автоматически, без жёстко заданных светлых значений.
enum ColorTokens {

    // MARK: - Base palette

    /// Фон экрана: #FFF9FB / тёмный #1B1619
    static let background = dynamic(light: 0xFFF9FB, dark: 0x1B1619)
    /// Поверхность карточки: #FFFFFF / тёмный #292328
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x292328)
    /// Вторичная поверхность: #FCE8EF / тёмный #352D33
    static let surfaceSecondary = dynamic(light: 0xFCE8EF, dark: 0x352D33)

    static let rosePrimary = dynamic(light: 0xF4A6BE, dark: 0xD993AC)
    static let roseDeep = dynamic(light: 0xA64D72, dark: 0xE09AB5)
    static let blush = dynamic(light: 0xFCE8EF, dark: 0x3E2E37)
    static let lavender = dynamic(light: 0xEDE5FA, dark: 0x443C52)

    static let textPrimary = dynamic(light: 0x352C35, dark: 0xF7F0F4)
    static let textSecondary = dynamic(light: 0x836E7B, dark: 0xC8B9C3)
    static let textTertiary = dynamic(light: 0xA89BA5, dark: 0x93838F)

    // MARK: - Semantic calendar colors

    static let periodActive = dynamic(light: 0xD97396, dark: 0xE38AA8)
    static let periodPredicted = dynamic(light: 0xF3B9CB, dark: 0x9A5D74)
    static let fertilityWindow = dynamic(light: 0xB49ADC, dark: 0xC4ACE8)
    static let ovulation = dynamic(light: 0x8E6FBF, dark: 0xD0B8F2)
    static let todayRing = dynamic(light: 0xA64D72, dark: 0xE09AB5)
    static let selectedRing = dynamic(light: 0x352C35, dark: 0xF7F0F4)

    // MARK: - Symptom intensity

    static let symptomLow = dynamic(light: 0xF6C9D8, dark: 0x8A5D70)
    static let symptomMedium = dynamic(light: 0xE592B1, dark: 0xC87B9C)
    static let symptomHigh = dynamic(light: 0xB85278, dark: 0xF0ACC5)

    // MARK: - Status

    static let success = dynamic(light: 0x4E9A77, dark: 0x7DD0AA)
    static let warning = dynamic(light: 0xC8913F, dark: 0xE8BC74)
    static let error = dynamic(light: 0xC0505F, dark: 0xF0919D)
    static let info = dynamic(light: 0x6E86B8, dark: 0xA9BCE4)

    // MARK: - Test results

    static let testPositive = success
    static let testNegative = dynamic(light: 0x8E8790, dark: 0xB4AAB3)
    static let testInvalid = warning

    // MARK: - Separators and fills

    static let separator = dynamic(light: 0xECDDE4, dark: 0x453B42)
    static let shimmer = dynamic(light: 0xF6EAEF, dark: 0x332A30)

    // MARK: - Factory

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }
}

// MARK: - UIColor hex helper

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Color hex helper (для stateless превью)

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

// MARK: - Legacy names used by early previews

extension ColorTokens {
    enum Light {
        static let background = Color(hex: 0xFFF9FB)
        static let surface = Color(hex: 0xFFFFFF)
        static let rosePrimary = Color(hex: 0xF4A6BE)
        static let roseDeep = Color(hex: 0xA64D72)
        static let blush = Color(hex: 0xFCE8EF)
        static let lavender = Color(hex: 0xEDE5FA)
        static let textPrimary = Color(hex: 0x352C35)
        static let textSecondary = Color(hex: 0x836E7B)
    }
}
