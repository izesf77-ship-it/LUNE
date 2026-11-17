import SwiftUI

/// Дизайн-система LUNÉ: Отступы и размеры
struct SpacingTokens {
    
    // MARK: - Spacing Scale
    
    static let xxxs: CGFloat = 4
    static let xxs: CGFloat = 8
    static let xs: CGFloat = 12
    static let sm: CGFloat = 16
    static let md: CGFloat = 20
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
    
    // MARK: - Corner Radius
    
    static let radiusXs: CGFloat = 8
    static let radiusSm: CGFloat = 12
    static let radiusMd: CGFloat = 16
    static let radiusLg: CGFloat = 22
    static let radiusXl: CGFloat = 26
    static let radiusXxl: CGFloat = 28
    static let radiusFull: CGFloat = 999
    
    // MARK: - Touch Targets
    
    /// Минимальный размер touch target (44x44 pt)
    static let touchMinimum: CGFloat = 44
    
    /// Стандартная высота кнопки
    static let buttonHeight: CGFloat = 54
    
    /// Высота текстового поля
    static let textFieldHeight: CGFloat = 48
    
    /// Высота chip/tag
    static let chipHeight: CGFloat = 36
    
    // MARK: - Icon Sizes
    
    static let iconXs: CGFloat = 16
    static let iconSm: CGFloat = 20
    static let iconMd: CGFloat = 24
    static let iconLg: CGFloat = 32
    static let iconXl: CGFloat = 40
    static let iconXxl: CGFloat = 48
    
    // MARK: - Calendar
    
    static let calendarDaySize: CGFloat = 40
    static let calendarSpacing: CGFloat = 8
    
    // MARK: - Card
    
    static let cardPadding: CGFloat = 20
    static let cardRadius: CGFloat = 22
    
    // MARK: - Screen Padding
    
    static let screenHorizontal: CGFloat = 20
    static let screenVertical: CGFloat = 16
    
    // MARK: - Safe Area Insets (approximate для iPhone 16)
    
    static let safeAreaTop: CGFloat = 59
    static let safeAreaBottom: CGFloat = 34
}

// MARK: - Layout Helpers

extension View {
    
    /// Стандартные горизонтальные отступы экрана
    func luneScreenPadding() -> some View {
        self.padding(.horizontal, SpacingTokens.screenHorizontal)
    }
    
    /// Полные отступы экрана
    func luneFullScreenPadding() -> some View {
        self.padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.screenVertical)
    }
}
