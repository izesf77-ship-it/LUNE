import SwiftUI

/// Карточка LUNÉ с мягкими тенями и скруглениями
struct LuneCard<Content: View>: View {
    
    let content: Content
    var padding: CGFloat = SpacingTokens.cardPadding
    var backgroundColor: Color = ColorTokens.surface
    var shadowEnabled: Bool = true
    
    init(
        padding: CGFloat = SpacingTokens.cardPadding,
        backgroundColor: Color = ColorTokens.surface,
        shadowEnabled: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.shadowEnabled = shadowEnabled
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: SpacingTokens.cardRadius)
                    .fill(backgroundColor)
            )
            .conditionalModifier(shadowEnabled) { view in
                view.luneCardShadow()
            }
    }
}

/// Gradient-карточка для особых моментов
struct LuneGradientCard<Content: View>: View {
    
    let content: Content
    let gradient: LinearGradient
    var padding: CGFloat = SpacingTokens.cardPadding
    
    init(
        gradient: LinearGradient,
        padding: CGFloat = SpacingTokens.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: SpacingTokens.cardRadius)
                    .fill(gradient)
            )
            .luneElevatedShadow()
    }
}

// MARK: - Conditional Modifier Helper

extension View {
    @ViewBuilder
    func conditionalModifier<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preset Gradients

extension LinearGradient {
    
    static var luneRose: LinearGradient {
        LinearGradient(
            colors: [
                ColorTokens.rosePrimary.opacity(0.3),
                ColorTokens.blush.opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var luneLavender: LinearGradient {
        LinearGradient(
            colors: [
                ColorTokens.lavender.opacity(0.4),
                ColorTokens.blush.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Cards") {
    ScrollView {
        VStack(spacing: 16) {
            LuneCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Твой цикл")
                        .luneTitleMedium()
                    Text("День 14 из 28")
                        .luneBodyMedium()
                }
            }
            
            LuneGradientCard(gradient: .luneRose) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Месячные начнутся через 5 дней")
                        .font(TypographyTokens.titleSmall)
                        .foregroundStyle(ColorTokens.textPrimary)
                }
            }
            
            LuneCard(backgroundColor: ColorTokens.blush) {
                Text("Цветная карточка")
                    .luneBodyLarge()
            }
        }
        .padding()
    }
    .background(ColorTokens.background)
}
