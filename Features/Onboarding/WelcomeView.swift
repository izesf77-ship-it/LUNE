import SwiftUI

struct WelcomeView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            ColorTokens.background
                .ignoresSafeArea()
            
            VStack(spacing: SpacingTokens.xxl) {
                Spacer()
                
                // Иконка
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                ColorTokens.rosePrimary.opacity(0.8),
                                ColorTokens.blush
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                    )
                    .luneElevatedShadow()
                
                VStack(spacing: SpacingTokens.sm) {
                    Text("Добро пожаловать в LUNÉ")
                        .luneDisplayLarge()
                        .multilineTextAlignment(.center)
                    
                    Text("Отслеживайте цикл, планируйте беременность и заботьтесь о своём здоровье")
                        .luneBodyMedium()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SpacingTokens.xl)
                }
                
                Spacer()
                
                // Приватность
                VStack(spacing: SpacingTokens.xs) {
                    HStack(spacing: SpacingTokens.xxs) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(ColorTokens.rosePrimary)
                        
                        Text("Полная приватность")
                            .font(TypographyTokens.labelMedium)
                            .foregroundStyle(ColorTokens.textPrimary)
                    }
                    
                    Text("Все ваши данные хранятся только на этом iPhone")
                        .luneCaption()
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, SpacingTokens.xl)
                
                // Кнопка
                LunePrimaryButton(
                    title: "Начать",
                    action: {
                        AnimationTokens.hapticMedium()
                        showOnboarding = true
                    }
                )
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
