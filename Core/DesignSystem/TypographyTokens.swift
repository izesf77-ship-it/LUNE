import SwiftUI

/// Дизайн-система LUNE: Типографические токены
/// SF Pro с поддержкой Dynamic Type и кириллицы
struct TypographyTokens {
    
    // MARK: - Display
    
    /// Большой заголовок (например, на Welcome экране)
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    
    /// Средний display
    static let displayMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
    
    // MARK: - Titles
    
    /// Заголовок экрана
    static let titleLarge = Font.system(size: 24, weight: .bold, design: .rounded)
    
    /// Заголовок секции
    static let titleMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
    
    /// Подзаголовок
    static let titleSmall = Font.system(size: 17, weight: .semibold, design: .default)
    
    // MARK: - Body
    
    /// Основной текст
    static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Вторичный текст
    static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    
    /// Мелкий текст
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: - Label
    
    /// Кнопки и важные действия
    static let labelLarge = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// Стандартные label
    static let labelMedium = Font.system(size: 15, weight: .medium, design: .default)
    
    /// Мелкие label (подписи к иконкам)
    static let labelSmall = Font.system(size: 13, weight: .medium, design: .default)
    
    /// Caption
    static let caption = Font.system(size: 11, weight: .regular, design: .default)
    
    // MARK: - Numbers
    
    /// Большие числовые значения (день цикла)
    static let numberLarge = Font.system(size: 48, weight: .bold, design: .rounded)
        .monospacedDigit()
    
    /// Средние числа
    static let numberMedium = Font.system(size: 32, weight: .semibold, design: .rounded)
        .monospacedDigit()
    
    /// Календарные числа
    static let numberCalendar = Font.system(size: 16, weight: .medium, design: .rounded)
        .monospacedDigit()
}

// MARK: - Dynamic Type Support

extension TypographyTokens {
    
    /// Адаптивные шрифты с поддержкой Dynamic Type
    struct Dynamic {
        static let displayLarge = Font.system(.largeTitle, design: .rounded, weight: .bold)
        static let titleLarge = Font.system(.title, design: .rounded, weight: .bold)
        static let titleMedium = Font.system(.title2, design: .rounded, weight: .semibold)
        static let titleSmall = Font.system(.title3, design: .default, weight: .semibold)
        static let bodyLarge = Font.system(.body, design: .default, weight: .regular)
        static let bodyMedium = Font.system(.callout, design: .default, weight: .regular)
        static let bodySmall = Font.system(.footnote, design: .default, weight: .regular)
        static let caption = Font.system(.caption, design: .default, weight: .regular)
    }
}

// MARK: - Text Styles

extension Text {
    
    func luneDisplayLarge() -> some View {
        self.font(TypographyTokens.Dynamic.displayLarge)
            .foregroundStyle(ColorTokens.textPrimary)
    }
    
    func luneTitleLarge() -> some View {
        self.font(TypographyTokens.Dynamic.titleLarge)
            .foregroundStyle(ColorTokens.textPrimary)
    }
    
    func luneTitleMedium() -> some View {
        self.font(TypographyTokens.Dynamic.titleMedium)
            .foregroundStyle(ColorTokens.textPrimary)
    }
    
    func luneBodyLarge() -> some View {
        self.font(TypographyTokens.Dynamic.bodyLarge)
            .foregroundStyle(ColorTokens.textPrimary)
    }
    
    func luneBodyMedium() -> some View {
        self.font(TypographyTokens.Dynamic.bodyMedium)
            .foregroundStyle(ColorTokens.textSecondary)
    }
    
    func luneBodySmall() -> some View {
        self.font(TypographyTokens.Dynamic.bodySmall)
            .foregroundStyle(ColorTokens.textSecondary)
    }
    
    func luneCaption() -> some View {
        self.font(TypographyTokens.Dynamic.caption)
            .foregroundStyle(ColorTokens.textTertiary)
    }
}
