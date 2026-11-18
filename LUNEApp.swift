import SwiftUI
import SwiftData

@main
struct LUNEApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
