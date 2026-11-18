import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            ColorTokens.background.ignoresSafeArea()

            if appState.isLoading {
                SplashView()
            } else if appState.isLocked {
                AppLockView()
            } else if let profile = appState.profile {
                if profile.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    WelcomeView()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toast = appState.toast {
                LuneToast(message: toast)
                    .padding(.bottom, SpacingTokens.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: AnimationTokens.fast), value: appState.isLoading)
        .animation(.easeInOut(duration: AnimationTokens.fast), value: appState.toast)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                PrivacyShield.shared.show()
            } else if newPhase == .active {
                PrivacyShield.shared.hide()
            }
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: SpacingTokens.md) {
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
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .frame(width: 96, height: 96)

            Text("LUNÉ")
                .font(TypographyTokens.displayLarge)
                .foregroundStyle(ColorTokens.textPrimary)

            Text("Забота о себе — в вашем ритме")
                .font(TypographyTokens.bodySmall)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.94)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { appeared = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LUNÉ. Загрузка")
    }
}

#Preview("Splash") {
    SplashView()
}
