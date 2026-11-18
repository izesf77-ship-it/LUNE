import SwiftUI

struct LuneChip: View {
    let title: String
    var icon: String?
    var color: Color = ColorTokens.rosePrimary

    var body: some View {
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon) }
            Text(title)
                .font(TypographyTokens.labelSmall)
        }
        .padding(.horizontal, SpacingTokens.xs)
        .padding(.vertical, 7)
        .background(color.opacity(0.16))
        .foregroundStyle(ColorTokens.textPrimary)
        .clipShape(Capsule())
        .accessibilityLabel(title)
    }
}

struct LuneSelectableChip: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            AnimationTokens.selectionHaptic()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(title)
                    .font(TypographyTokens.labelMedium)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, SpacingTokens.sm)
            .frame(minHeight: SpacingTokens.chipHeight)
            .background(
                Capsule()
                    .fill(isSelected ? ColorTokens.rosePrimary.opacity(0.32) : ColorTokens.surface)
            )
            .overlay(
                Capsule().stroke(
                    isSelected ? ColorTokens.roseDeep : ColorTokens.separator,
                    lineWidth: isSelected ? 1.5 : 1
                )
            )
            .foregroundStyle(isSelected ? ColorTokens.roseDeep : ColorTokens.textPrimary)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(title)
    }
}
