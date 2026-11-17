import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List {
                // Режим
                Section {
                    if let profile = appState.userProfile {
                        NavigationLink(destination: ModeSwitcherView()) {
                            HStack {
                                Image(systemName: profile.mode.iconName)
                                    .foregroundStyle(ColorTokens.rosePrimary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Режим приложения")
                                        .font(TypographyTokens.labelMedium)
                                    
                                    Text(profile.mode.displayName)
                                        .font(TypographyTokens.bodySmall)
                                        .foregroundStyle(ColorTokens.textSecondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Персонализация")
                }
                
                // Приватность
                Section {
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Приватность", systemImage: "lock.shield")
                    }
                } header: {
                    Text("Безопасность")
                }
                
                // О приложении
                Section {
                    NavigationLink(destination: AboutView()) {
                        Label("О приложении LUNÉ", systemImage: "info.circle")
                    }
                    
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                } header: {
                    Text("Информация")
                }
                
                // Данные
                Section {
                    NavigationLink(destination: Text("Экспорт")) {
                        Label("Экспорт данных", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: {}) {
                        Label("Удалить все данные", systemImage: "trash")
                    }
                } header: {
                    Text("Данные")
                } footer: {
                    Text("Удаление данных необратимо")
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Mode Switcher

struct ModeSwitcherView: View {
    
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            ForEach(AppMode.allCases, id: \.self) { mode in
                Button(action: {
                    appState.switchMode(to: mode)
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.displayName)
                                .font(TypographyTokens.labelLarge)
                                .foregroundStyle(ColorTokens.textPrimary)
                            
                            Text(mode.description)
                                .font(TypographyTokens.bodySmall)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                        
                        Spacer()
                        
                        if appState.userProfile?.mode == mode {
                            Image(systemName: "checkmark")
                                .foregroundStyle(ColorTokens.rosePrimary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Выбор режима")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Settings

struct PrivacySettingsView: View {
    
    var body: some View {
        List {
            Section {
                Text("Все ваши данные хранятся локально на этом iPhone. LUNÉ не отправляет информацию на сервера и не использует облачную синхронизацию.")
                    .font(TypographyTokens.bodyMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            
            Section {
                Toggle("Face ID / Touch ID", isOn: .constant(false))
                Toggle("Скрыть превью уведомлений", isOn: .constant(true))
            } header: {
                Text("Защита")
            }
        }
        .navigationTitle("Приватность")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About

struct AboutView: View {
    
    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.lg) {
                // Logo
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ColorTokens.rosePrimary, ColorTokens.blush],
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
                    .padding(.top, SpacingTokens.xl)
                
                Text("LUNÉ")
                    .font(TypographyTokens.displayMedium)
                    .foregroundStyle(ColorTokens.textPrimary)
                
                Text("Версия 1.0")
                    .font(TypographyTokens.bodyMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
                
                VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                    Text("О приложении")
                        .font(TypographyTokens.titleSmall)
                    
                    Text("LUNÉ — это приватное приложение для отслеживания менструального цикла и планирования беременности. Все ваши данные хранятся только на вашем устройстве.")
                        .font(TypographyTokens.bodyMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                
                Spacer()
            }
        }
        .background(ColorTokens.background)
        .navigationTitle("О приложении")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
