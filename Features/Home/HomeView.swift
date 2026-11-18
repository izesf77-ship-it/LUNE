import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showPeriodEditor = false
    @State private var showSymptomJournal = false
    @State private var showMoodJournal = false
    @State private var showLHEditor = false
    @State private var showPregnancyEditor = false
    @State private var showTemperature = false
    @State private var showMucus = false
    @State private var showDayDetail = false
    @State private var showRecommendations = false
    @State private var selectedDay = CalendarDate(Date())

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    header
                    if appState.mode == .cycleTracking {
                        CycleHomeView(
                            selectedDay: $selectedDay,
                            showDayDetail: $showDayDetail,
                            showPeriodEditor: $showPeriodEditor,
                            showSymptomJournal: $showSymptomJournal,
                            showMoodJournal: $showMoodJournal,
                            showRecommendations: $showRecommendations
                        )
                    } else {
                        PlanningHomeView(
                            showLHEditor: $showLHEditor,
                            showPregnancyEditor: $showPregnancyEditor,
                            showTemperature: $showTemperature,
                            showMucus: $showMucus,
                            showRecommendations: $showRecommendations
                        )
                    }
                }
                .padding(.vertical, SpacingTokens.xs)
            }
            .background(ColorTokens.background)
            .navigationDestination(isPresented: $showDayDetail) {
                DayDetailView(day: selectedDay)
            }
            .navigationDestination(isPresented: $showRecommendations) {
                RecommendationsView()
            }
            .sheet(isPresented: $showPeriodEditor) { PeriodEditorView(day: selectedDay) }
            .sheet(isPresented: $showSymptomJournal) { SymptomJournalView(day: selectedDay) }
            .sheet(isPresented: $showMoodJournal) { MoodJournalView(day: selectedDay) }
            .sheet(isPresented: $showLHEditor) { LHTestEditorView(day: selectedDay) }
            .sheet(isPresented: $showPregnancyEditor) { PregnancyTestEditorView(day: selectedDay) }
            .sheet(isPresented: $showTemperature) { BasalTemperatureView() }
            .sheet(isPresented: $showMucus) { CervicalMucusView(day: selectedDay) }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(greeting)
                    .font(TypographyTokens.titleLarge)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(formattedDate)
                    .font(TypographyTokens.bodySmall)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            Spacer()
            Image(systemName: appState.mode.iconName)
                .font(.system(size: 24))
                .foregroundStyle(ColorTokens.roseDeep)
                .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                .accessibilityLabel("Режим: \(appState.mode.displayName)")
        }
        .padding(.horizontal, SpacingTokens.screenHorizontal)
    }

    private var greeting: String {
        guard let name = appState.profile?.userName, !name.isEmpty else {
            return "Привет"
        }
        return "Привет, \(name)"
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: Date()).capitalized
    }
}
