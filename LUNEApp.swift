import SwiftUI
import SwiftData

@main
struct LUNEApp: App {
    
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(DatabaseManager.shared.container)
                .preferredColorScheme(appState.colorScheme)
                .task {
                    await appState.initialize()
                }
        }
    }
}

/// Глобальное состояние приложения
@MainActor
final class AppState: ObservableObject {
    
    @Published var isLoading = true
    @Published var userProfile: UserProfile?
    @Published var colorScheme: ColorScheme? = nil
    
    private let database = DatabaseManager.shared
    
    func initialize() async {
        // Загружаем профиль пользователя
        userProfile = database.fetchOrCreateUserProfile()
        
        // Небольшая задержка для splash screen
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec
        
        isLoading = false
    }
    
    func updateProfile() {
        userProfile?.updateTimestamp()
        database.saveContext()
    }
    
    func switchMode(to mode: AppMode) {
        userProfile?.mode = mode
        updateProfile()
    }
    
    func completeOnboarding() {
        userProfile?.hasCompletedOnboarding = true
        updateProfile()
    }
}
