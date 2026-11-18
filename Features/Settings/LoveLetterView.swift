import SwiftUI

/// Небольшое личное послание. Открывается только по нажатию кнопки в настройках.
/// Не является вкладкой, экраном онбординга и не показывается автоматически.
struct LoveLetterView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let letter = """
    Для моей любимой жены ♡

    Это приложение я сделал для тебя.

    Пусть LUNÉ будет маленьким напоминанием о том, как сильно я тебя люблю и как важно для меня твоё счастье.

    Береги себя, улыбайся чаще и знай: ты для меня самая особенная.

    С любовью, твой муж ♡
    """

    var body: some View {
        ZStack {
            ColorTokens.background.ignoresSafeArea()

            LuneFlowerMark(size: 190, opacity: 0.10)
                .offset(y: -140)
                .accessibilityHidden(true)

            ScrollView {
                VStack(spacing: SpacingTokens.lg) {
                    Spacer(minLength: SpacingTokens.md)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(ColorTokens.roseDeep)
                        .accessibilityHidden(true)

                    Text(letter)
                        .font(TypographyTokens.Dynamic.bodyLarge)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(7)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Любовное послание")

                    LuneFlowerMark(size: 54, opacity: 0.55)
                        .accessibilityHidden(true)

                    LuneSecondaryButton(title: "Назад", icon: "chevron.left") {
                        dismiss()
                    }
                    .padding(.horizontal, SpacingTokens.screenHorizontal)

                    Spacer(minLength: SpacingTokens.sm)
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
            }
        }
        .navigationTitle(" ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Готово") { dismiss() }
                    .font(TypographyTokens.Dynamic.bodyMedium)
                    .foregroundStyle(ColorTokens.roseDeep)
                    .frame(minHeight: SpacingTokens.touchMinimum)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.45)) { appeared = true }
        }
    }
}

#Preview {
    NavigationStack { LoveLetterView() }
}
