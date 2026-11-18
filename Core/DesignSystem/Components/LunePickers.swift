import SwiftUI

/// Быстрый выбор симптома: одно касание добавляет запись с базовой интенсивностью.
struct LuneSymptomPicker: View {
    let selection: Set<SymptomType>
    let toggle: (SymptomType) -> Void

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: SpacingTokens.xs)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: SpacingTokens.xs) {
            ForEach(SymptomType.allCase) { symptom in
                LuneSelectableChip(
                    title: symptom.displayName,
                    icon: symptom.iconName,
                    isSelected: selection.contains(symptom)
                ) {
                    toggle(symptom)
                }
            }
        }
    }
}

extension SymptomType {
    /// Искусственное имя, чтобы не конфликтовать с synthesized `allCases`.
    static let allCase = SymptomType.allCases
}

struct LuneMoodPicker: View {
    @Binding var selection: MoodType?

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: SpacingTokens.xs)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: SpacingTokens.xs) {
            ForEach(MoodType.allCases) { mood in
                Button {
                    AnimationTokens.selectionHaptic()
                    selection = selection == mood ? nil : mood
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: mood.symbolName)
                            .font(.system(size: 24))
                        Text(mood.displayName)
                            .font(TypographyTokens.caption)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)
                    .background(
                        RoundedRectangle(cornerRadius: RadiusTokens.sm)
                            .fill(selection == mood ? ColorTokens.rosePrimary.opacity(0.28) : ColorTokens.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: RadiusTokens.sm)
                            .stroke(selection == mood ? ColorTokens.roseDeep : ColorTokens.separator,
                                    lineWidth: selection == mood ? 1.5 : 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(ColorTokens.textPrimary)
                .accessibilityAddTraits(selection == mood ? [.isSelected] : [])
                .accessibilityLabel(mood.displayName)
            }
        }
    }
}
