import SwiftUI

struct MainTabView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Label("Календарь", systemImage: "calendar")
                }
                .tag(1)
            
            JournalView()
                .tabItem {
                    Label("Дневник", systemImage: "book.fill")
                }
                .tag(2)
            
            AnalyticsView()
                .tabItem {
                    Label("Аналитика", systemImage: "chart.bar.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(ColorTokens.rosePrimary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
