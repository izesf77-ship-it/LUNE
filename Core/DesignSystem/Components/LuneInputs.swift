import SwiftUI

struct LuneTextField: View {
    let title: String
    var placeholder: String
    @Binding var text: String
    var isMultiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
            Text(title)
                .font(TypographyTokens.labelMedium)
                .foregroundStyle(ColorTokens.textPrimary)

            Group {
                if isMultiline {
                    TextEditor(text: $text)
                        .frame(minHeight: 90)
                        .padding(8)
                } else {
                    TextField(placeholder, text: $text)
                        .padding(.horizontal, SpacingTokens.sm)
                        .frame(height: SpacingTokens.textFieldHeight)
                }
            }
            .font(TypographyTokens.bodyLarge)
            .foregroundStyle(ColorTokens.textPrimary)
            .background(ColorTokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: RadiusTokens.sm))
            .overlay(
                RoundedRectangle(cornerRadius: RadiusTokens.sm)
                    .stroke(ColorTokens.separator, lineWidth: 1)
            )
            .accessibilityLabel(title)
        }
    }
}

struct LuneDatePicker: View {
    let title: String
    @Binding var date: Date
    var displayedComponents: DatePickerComponents = [.date]

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
            Text(title)
                .font(TypographyTokens.labelMedium)
                .foregroundStyle(ColorTokens.textPrimary)

            DatePicker("", selection: $date, displayedComponents: displayedComponents)
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SpacingTokens.sm)
                .frame(height: SpacingTokens.textFieldHeight)
                .background(ColorTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: RadiusTokens.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: RadiusTokens.sm)
                        .stroke(ColorTokens.separator, lineWidth: 1)
                )
                .accessibilityLabel(title)
        }
    }
}

struct LuneSegmentedControl<T: Hashable & Identifiable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { option in
                Button {
                    AnimationTokens.selectionHaptic()
                    selection = option
                } label: {
                    Text(label(option))
                        .font(TypographyTokens.labelMedium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: RadiusTokens.sm)
                                .fill(selection == option ? ColorTokens.surface : Color.clear)
                        )
                        .foregroundStyle(selection == option ? ColorTokens.roseDeep : ColorTokens.textSecondary)
                        .shadow(color: selection == option ? Color.black.opacity(0.05) : .clear, radius: 4, y: 1)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(ColorTokens.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: RadiusTokens.md))
    }
}
