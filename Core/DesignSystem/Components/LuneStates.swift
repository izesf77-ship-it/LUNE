import SwiftUI

struct LuneSectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyTokens.titleSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            Spacer(minLength: 8)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(TypographyTokens.labelMedium)
                        .foregroundStyle(ColorTokens.roseDeep)
                }
                .frame(minHeight: SpacingTokens.touchMinimum)
                .buttonStyle(.plain)
            }
        }
    }
}

struct LuneEmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            Image(systemName: symbol)
                .font(.system(size: 38))
                .foregroundStyle(ColorTokens.rosePrimary)
                .accessibilityHidden(true)

            Text(title)
                .font(TypographyTokens.titleSmall)
                .foregroundStyle(ColorTokens.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(TypographyTokens.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                LuneSecondaryButton(title: actionTitle, action: action)
                    .padding(.top, SpacingTokens.xxs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xl)
    }
}

struct LuneErrorState: View {
    let message: String
    var retryTitle: String = "Повторить"
    let retry: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 34))
                .foregroundStyle(ColorTokens.warning)
            Text("Не удалось загрузить данные")
                .font(TypographyTokens.titleSmall)
                .foregroundStyle(ColorTokens.textPrimary)
            Text(message)
                .font(TypographyTokens.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
            LuneSecondaryButton(title: retryTitle, action: retry)
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xl)
    }
}

struct LuneToast: View {
    let message: String

    var body: some View {
        HStack(spacing: SpacingTokens.xxs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(ColorTokens.success)
            Text(message)
                .font(TypographyTokens.labelMedium)
                .foregroundStyle(ColorTokens.textPrimary)
        }
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.xs)
        .background(
            Capsule().fill(ColorTokens.surface)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 12, y: 4)
        .accessibilityAddTraits(.isStaticText)
    }
}

struct LuneSettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    var trailing: String?
    var isOn: Binding<Bool>?
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let isOn {
                Toggle(isOn: isOn) { label }
                    .tint(ColorTokens.rosePrimary)
            } else if let action {
                Button(action: action) {
                    HStack {
                        label
                        Spacer()
                        if let trailing {
                            Text(trailing)
                                .font(TypographyTokens.bodySmall)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minHeight: SpacingTokens.touchMinimum)
            } else {
                HStack {
                    label
                    Spacer()
                }
                .frame(minHeight: SpacingTokens.touchMinimum)
            }
        }
    }

    private var label: some View {
        HStack(spacing: SpacingTokens.sm) {
            Image(systemName: icon)
                .font(.system(size: SpacingTokens.iconSm))
                .foregroundStyle(ColorTokens.roseDeep)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyTokens.bodyLarge)
                    .foregroundStyle(ColorTokens.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
        }
    }
}
