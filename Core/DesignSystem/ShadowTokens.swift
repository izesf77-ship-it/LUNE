import SwiftUI

/// Дизайн-система LUNE: Тени и elevation
struct ShadowTokens {
    
    // MARK: - Shadow Styles
    
    /// Минимальная тень для карточек
    static let shadowSm = ShadowStyle(
        color: Color.black.opacity(0.04),
        radius: 4,
        x: 0,
        y: 2
    )
    
    /// Средняя тень
    static let shadowMd = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 12,
        x: 0,
        y: 4
    )
    
    /// Большая тень для модальных окон
    static let shadowLg = ShadowStyle(
        color: Color.black.opacity(0.12),
        radius: 24,
        x: 0,
        y: 8
    )
    
    /// Тень для elevated карточек
    static let shadowElevated = ShadowStyle(
        color: Color.black.opacity(0.06),
        radius: 16,
        x: 0,
        y: 6
    )
}

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extension

extension View {
    
    func luneShadow(_ style: ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
    
    func luneCardShadow() -> some View {
        self.luneShadow(ShadowTokens.shadowSm)
    }
    
    func luneElevatedShadow() -> some View {
        self.luneShadow(ShadowTokens.shadowElevated)
    }
}
