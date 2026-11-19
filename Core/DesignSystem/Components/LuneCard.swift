import SwiftUI

/// Базовая карточка LUNE: мягкие скругления и ненавязчивая тень.
struct LuneCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = SpacingTokens.cardPadding
    var background: Color = ColorTokens.surface
    var showShadow: Bool = true

    init(
        padding: CGFloat = SpacingTokens.cardPadding,
        background: Color = ColorTokens.surface,
        showShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.background = background
        self.showShadow = showShadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: RadiusTokens.card).fill(background))
            .modifier(OptionalShadow(enabled: showShadow))
    }
}

private struct OptionalShadow: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled {
            content.shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
        } else {
            content
        }
    }
}

/// Градиентная акцентная карточка (используется экономно).
struct LuneGradientCard<Content: View>: View {
    let content: Content
    var palette: Palette = .rose
    var padding: CGFloat = SpacingTokens.cardPadding

    enum Palette {
        case rose, lavender

        var colors: [Color] {
            switch self {
            case .rose: return [ColorTokens.rosePrimary.opacity(0.28), ColorTokens.blush.opacity(0.7)]
            case .lavender: return [ColorTokens.lavender.opacity(0.7), ColorTokens.blush.opacity(0.45)]
            }
        }
    }

    init(
        palette: Palette = .rose,
        padding: CGFloat = SpacingTokens.cardPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: RadiusTokens.card)
                    .fill(LinearGradient(colors: palette.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            )
    }
}
