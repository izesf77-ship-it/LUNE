import SwiftUI

enum LuneTab: Int {
    case home, calendar, journal, analytics, planning, settings
}

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: LuneTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Главная", systemImage: "house") }
                .tag(LuneTab.home)

            CalendarView()
                .tabItem { Label("Календарь", systemImage: "calendar") }
                .tag(LuneTab.calendar)

            JournalView()
                .tabItem { Label("Дневник", systemImage: "book") }
                .tag(LuneTab.journal)

            AnalyticsView()
                .tabItem { Label("Аналитика", systemImage: "chart.bar") }
                .tag(LuneTab.analytics)

            if appState.mode == .conceptionPlanning {
                FertilityInsightsView()
                    .tabItem { Label("Планирование", systemImage: "heart") }
                    .tag(LuneTab.planning)
            }

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gearshape") }
                .tag(LuneTab.settings)
        }
        .tint(ColorTokens.roseDeep)
        .onChange(of: appState.mode) { _, newMode in
            if newMode == .cycleTracking && selectedTab == .planning {
                selectedTab = .home
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
