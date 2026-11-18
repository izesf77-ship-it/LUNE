import SwiftUI

/// Единственный приветственный экран. После «Начать» открывается сценарий
/// вопросов — приветствие внутри него больше не повторяется.
struct WelcomeView: View {
    @State private var showOnboarding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var markSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 84 : 112
    }

    var body: some View {
        ZStack {
            ColorTokens.background.ignoresSafeArea()

            // Мягкие цветочные акценты по краям — без перекрытия контента.
            VStack {
                HStack {
                    LuneFlowerMark(size: 54, opacity: 0.22)
                        .offset(x: -22, y: 6)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    LuneFlowerMark(size: 68, opacity: 0.16)
                        .offset(x: 20, y: -10)
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: SpacingTokens.md) {
                Spacer(minLength: SpacingTokens.lg)

                LuneFlowerMark(size: markSize)
                    .shadow(color: ColorTokens.roseDeep.opacity(0.10), radius: 18, y: 8)
                    .accessibilityHidden(true)

                VStack(spacing: SpacingTokens.sm) {
                    Text("Добро пожаловать")
                        .font(TypographyTokens.Dynamic.displayLarge)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("LUNÉ — тихое место, где можно заботиться о себе и замечать свой ритм. Без спешки, без лишних вопросов и только на твоём iPhone.")
                        .font(TypographyTokens.Dynamic.bodyLarge)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, SpacingTokens.xxs)
                }

                Spacer(minLength: SpacingTokens.sm)

                VStack(spacing: SpacingTokens.xs) {
                    Label("Твои данные остаются на этом iPhone", systemImage: "lock.shield.fill")
                    Label("Без интернета, аккаунта и аналитики", systemImage: "wifi.slash")
                }
                .font(TypographyTokens.Dynamic.bodySmall)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)

                LunePrimaryButton(title: "Начать", icon: "arrow.right") {
                    showOnboarding = true
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.bottom, SpacingTokens.sm)
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlow()
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: showOnboarding)
    }
}

/// Небольшой оригинальный цветочный знак LUNÉ из SF-фигур.
struct LuneFlowerMark: View {
    let size: CGFloat
    var opacity: Double = 1

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { index in
                Ellipse()
                    .fill(ColorTokens.rosePrimary.opacity(opacity))
                    .frame(width: size * 0.30, height: size * 0.52)
                    .offset(y: -size * 0.27)
                    .rotationEffect(.degrees(Double(index) * 72))
            }
            Circle()
                .fill(ColorTokens.roseDeep.opacity(opacity))
                .frame(width: size * 0.22, height: size * 0.22)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppState())
}

#Preview("Large text") {
    WelcomeView()
        .environmentObject(AppState())
        .environment(\.dynamicTypeSize, .accessibility3)
}
