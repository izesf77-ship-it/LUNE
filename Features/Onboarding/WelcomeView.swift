import SwiftUI

/// Первый экран после splash. Вежливо знакомит с продуктом и приватностью.
struct WelcomeView: View {
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            ColorTokens.background.ignoresSafeArea()

            VStack(spacing: SpacingTokens.lg) {
                Spacer(minLength: SpacingTokens.xl)

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ColorTokens.rosePrimary, ColorTokens.blush],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "sparkles")
                        .font(.system(size: 54))
                        .foregroundStyle(.white)
                }
                .frame(width: 118, height: 118)
                .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)

                VStack(spacing: SpacingTokens.sm) {
                    Text("Добро пожаловать в LUNÉ")
                        .font(TypographyTokens.displayLarge)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Место, где можно спокойно наблюдать за циклом, самочувствием и планами — без аккаунта и подключения к интернету.")
                        .font(TypographyTokens.bodyLarge)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, SpacingTokens.md)

                Spacer()

                HStack(spacing: SpacingTokens.xxs) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(ColorTokens.roseDeep)
                    Text("Все данные хранятся только на этом iPhone")
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingTokens.md)

                LunePrimaryButton(title: "Начать", icon: "arrow.right") {
                    showOnboarding = true
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.bottom, SpacingTokens.md)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlow()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppState())
}
