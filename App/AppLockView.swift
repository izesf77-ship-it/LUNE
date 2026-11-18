import SwiftUI

struct AppLockView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isAuthenticating = false
    @State private var showError = false

    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Spacer()

            Image(systemName: "lock.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(ColorTokens.rosePrimary)

            Text("LUNÉ защищён")
                .font(TypographyTokens.displayMedium)
                .foregroundStyle(ColorTokens.textPrimary)

            Text("Данные доступны только владельцу устройства. Используйте \(BiometricAuth.biometryName) для входа.")
                .font(TypographyTokens.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)

            if showError {
                Text("Не удалось подтвердить доступ. Попробуйте ещё раз.")
                    .font(TypographyTokens.bodySmall)
                    .foregroundStyle(ColorTokens.error)
                    .multilineTextAlignment(.center)
            }

            LunePrimaryButton(
                title: "Открыть",
                icon: "faceid",
                isLoading: isAuthenticating
            ) {
                Task {
                    isAuthenticating = true
                    await appState.unlock()
                    isAuthenticating = false
                    showError = appState.isLocked
                }
            }
            .padding(.top, SpacingTokens.sm)

            Spacer()
        }
        .padding(SpacingTokens.xl)
        .background(ColorTokens.background)
    }
}
