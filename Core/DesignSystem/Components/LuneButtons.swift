import SwiftUI

// MARK: - Primary

struct LunePrimaryButton: View {
    enum Style {
        case rose, deep, lavender, subtle

        var background: Color {
            switch self {
            case .rose: return ColorTokens.rosePrimary
            case .deep: return ColorTokens.roseDeep
            case .lavender: return ColorTokens.lavender
            case .subtle: return ColorTokens.surfaceSecondary
            }
        }

        var foreground: Color {
            switch self {
            case .rose, .deep: return .white
            case .lavender, .subtle: return ColorTokens.textPrimary
            }
        }
    }

    let title: String
    var icon: String?
    var isDisabled: Bool = false
    var isLoading: Bool = false
    var style: Style = .rose
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            guard !isDisabled && !isLoading else { return }
            AnimationTokens.selectionHaptic()
            action()
        } label: {
            HStack(spacing: SpacingTokens.xxs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foreground))
                }
                if let icon { Image(systemName: icon) }
                Text(title)
                    .font(TypographyTokens.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .frame(height: SpacingTokens.buttonHeight)
            .foregroundStyle(style.foreground)
            .background(
                RoundedRectangle(cornerRadius: RadiusTokens.button)
                    .fill(style.background)
                    .opacity(isDisabled ? 0.45 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .animation(AnimationTokens.resolved(AnimationTokens.selection, reduceMotion: reduceMotion), value: isDisabled)
        .accessibilityLabel(title)
    }
}

// MARK: - Secondary

struct LuneSecondaryButton: View {
    let title: String
    var icon: String?
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            guard !isDisabled else { return }
            AnimationTokens.lightHaptic()
            action()
        } label: {
            HStack(spacing: SpacingTokens.xxs) {
                if let icon { Image(systemName: icon) }
                Text(title)
                    .font(TypographyTokens.labelMedium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: SpacingTokens.buttonHeight)
            .foregroundStyle(ColorTokens.roseDeep)
            .background(
                RoundedRectangle(cornerRadius: RadiusTokens.button)
                    .stroke(ColorTokens.rosePrimary, lineWidth: 1.5)
                    .background(RoundedRectangle(cornerRadius: RadiusTokens.button).fill(ColorTokens.surface))
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel(title)
    }
}

// MARK: - Icon button

struct LuneIconButton: View {
    let symbol: String
    var size: CGFloat = SpacingTokens.iconSm
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button {
            AnimationTokens.selectionHaptic()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(ColorTokens.roseDeep)
                .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                .background(
                    Circle().fill(ColorTokens.surfaceSecondary)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
