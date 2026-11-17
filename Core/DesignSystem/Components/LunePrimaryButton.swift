import SwiftUI

/// Основная кнопка LUNÉ
struct LunePrimaryButton: View {
    
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var style: ButtonStyle = .rose
    
    enum ButtonStyle {
        case rose
        case roseDeep
        case lavender
        case neutral
        
        var backgroundColor: Color {
            switch self {
            case .rose: return ColorTokens.rosePrimary
            case .roseDeep: return ColorTokens.roseDeep
            case .lavender: return ColorTokens.lavender
            case .neutral: return ColorTokens.surface
            }
        }
        
        var textColor: Color {
            switch self {
            case .rose, .roseDeep: return .white
            case .lavender: return ColorTokens.textPrimary
            case .neutral: return ColorTokens.textPrimary
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                AnimationTokens.hapticMedium()
                action()
            }
        }) {
            HStack(spacing: SpacingTokens.xxs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                        .scaleEffect(0.9)
                }
                
                Text(title)
                    .font(TypographyTokens.labelLarge)
                    .foregroundStyle(style.textColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: SpacingTokens.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: SpacingTokens.radiusMd)
                    .fill(style.backgroundColor)
                    .opacity(isDisabled ? 0.5 : 1.0)
            )
        }
        .disabled(isDisabled || isLoading)
        .animation(AnimationTokens.selection, value: isLoading)
        .animation(AnimationTokens.selection, value: isDisabled)
    }
}

#Preview("Primary Button") {
    VStack(spacing: 16) {
        LunePrimaryButton(title: "Продолжить", action: {})
        
        LunePrimaryButton(
            title: "Сохранить",
            action: {},
            style: .roseDeep
        )
        
        LunePrimaryButton(
            title: "Загрузка...",
            action: {},
            isLoading: true
        )
        
        LunePrimaryButton(
            title: "Недоступно",
            action: {},
            isDisabled: true
        )
        
        LunePrimaryButton(
            title: "Фертильность",
            action: {},
            style: .lavender
        )
    }
    .padding()
    .background(ColorTokens.background)
}
