import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if appState.isLoading {
                SplashView()
            } else if let profile = appState.userProfile {
                if profile.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    WelcomeView()
                }
            } else {
                // Fallback: не должно произойти
                ProgressView()
            }
        }
        .animation(.easeInOut, value: appState.isLoading)
        .animation(.easeInOut, value: appState.userProfile?.hasCompletedOnboarding)
    }
}

// MARK: - Splash View

struct SplashView: View {
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            ColorTokens.Light.background
                .ignoresSafeArea()
            
            VStack(spacing: SpacingTokens.md) {
                // Иконка приложения (placeholder)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ColorTokens.Light.rosePrimary,
                                ColorTokens.Light.blush
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text("LUNÉ")
                    .font(TypographyTokens.displayLarge)
                    .foregroundStyle(ColorTokens.Light.textPrimary)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview("Splash") {
    SplashView()
}
