import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var appState: AppState
    @State private var periods: [MenstrualPeriod] = []
    @State private var currentCycleDay: Int = 1
    @State private var daysUntilNextPeriod: Int? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.lg) {
                    // Приветствие
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if let profile = appState.userProfile, let name = profile.userName {
                                Text("Привет, \(name)")
                                    .luneTitleLarge()
                            } else {
                                Text("Привет")
                                    .luneTitleLarge()
                            }
                            
                            Text(formattedDate)
                                .luneBodyMedium()
                        }
                        
                        Spacer()
                        
                        // Режим
                        if let profile = appState.userProfile {
                            Image(systemName: profile.mode.iconName)
                                .font(.system(size: SpacingTokens.iconLg))
                                .foregroundStyle(ColorTokens.rosePrimary)
                        }
                    }
                    .luneScreenPadding()
                    
                    // Основная карточка
                    if let profile = appState.userProfile {
                        switch profile.mode {
                        case .cycleTracking:
                            CycleTrackingCard(
                                cycleDay: currentCycleDay,
                                daysUntil: daysUntilNextPeriod
                            )
                        case .conceptionPlanning:
                            FertilityCard()
                        }
                    }
                    
                    // Быстрые действия
                    QuickActionsSection()
                    
                    // Insights
                    InsightsSection()
                }
                .padding(.vertical, SpacingTokens.sm)
            }
            .background(ColorTokens.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            loadData()
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: Date())
    }
    
    private func loadData() {
        periods = DatabaseManager.shared.fetchConfirmedPeriods()
        calculateCycleInfo()
    }
    
    private func calculateCycleInfo() {
        guard let lastPeriod = periods.first else {
            currentCycleDay = 1
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.startOfDay(for: lastPeriod.startDate)
        
        if let days = calendar.dateComponents([.day], from: startDate, to: today).day {
            currentCycleDay = days + 1
        }
        
        // Простой прогноз
        if let cycleLength = appState.userProfile?.typicalCycleLength {
            let daysSinceStart = currentCycleDay - 1
            if daysSinceStart < cycleLength {
                daysUntilNextPeriod = cycleLength - daysSinceStart
            } else {
                daysUntilNextPeriod = 0
            }
        }
    }
}

// MARK: - Cycle Tracking Card

struct CycleTrackingCard: View {
    
    let cycleDay: Int
    let daysUntil: Int?
    
    var body: some View {
        LuneCard(padding: SpacingTokens.lg) {
            HStack(spacing: SpacingTokens.lg) {
                // Кольцевой индикатор
                ZStack {
                    Circle()
                        .stroke(ColorTokens.blush, lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            ColorTokens.rosePrimary,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(cycleDay)")
                            .font(TypographyTokens.numberMedium)
                            .foregroundStyle(ColorTokens.textPrimary)
                        
                        Text("день")
                            .luneCaption()
                    }
                }
                
                // Информация
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    Text("Твой цикл")
                        .font(TypographyTokens.titleSmall)
                        .foregroundStyle(ColorTokens.textPrimary)
                    
                    if let days = daysUntil {
                        if days > 0 {
                            Text("Месячные ожидаются примерно через \(days) дней")
                                .font(TypographyTokens.bodyMedium)
                                .foregroundStyle(ColorTokens.textSecondary)
                        } else {
                            Text("Месячные могут начаться в любой день")
                                .font(TypographyTokens.bodyMedium)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                    } else {
                        Text("Соберите больше данных для прогноза")
                            .font(TypographyTokens.bodyMedium)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
        .luneScreenPadding()
    }
    
    private var progress: CGFloat {
        // Примерный прогресс на основе 28-дневного цикла
        return min(CGFloat(cycleDay) / 28.0, 1.0)
    }
}

// MARK: - Fertility Card

struct FertilityCard: View {
    
    var body: some View {
        LuneCard(padding: SpacingTokens.lg, backgroundColor: ColorTokens.lavender.opacity(0.3)) {
            VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: SpacingTokens.iconXl))
                        .foregroundStyle(ColorTokens.roseDeep)
                    
                    Text("Планирование беременности")
                        .font(TypographyTokens.titleMedium)
                        .foregroundStyle(ColorTokens.textPrimary)
                    
                    Spacer()
                }
                
                Text("Отслеживайте фертильное окно и признаки овуляции")
                    .font(TypographyTokens.bodyMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .luneScreenPadding()
    }
}

// MARK: - Quick Actions

struct QuickActionsSection: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            Text("Быстрые действия")
                .font(TypographyTokens.titleSmall)
                .foregroundStyle(ColorTokens.textPrimary)
                .luneScreenPadding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: SpacingTokens.sm) {
                    QuickActionButton(
                        icon: "drop.fill",
                        title: "Месячные",
                        color: ColorTokens.periodActive
                    ) {}
                    
                    QuickActionButton(
                        icon: "face.smiling",
                        title: "Настроение",
                        color: ColorTokens.rosePrimary
                    ) {}
                    
                    QuickActionButton(
                        icon: "bolt.circle",
                        title: "Симптомы",
                        color: ColorTokens.roseDeep
                    ) {}
                    
                    QuickActionButton(
                        icon: "note.text",
                        title: "Заметка",
                        color: ColorTokens.lavender
                    ) {}
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
            }
        }
    }
}

struct QuickActionButton: View {
    
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: SpacingTokens.xxs) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 26))
                            .foregroundStyle(color)
                    )
                
                Text(title)
                    .font(TypographyTokens.labelSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Insights

struct InsightsSection: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            Text("Рекомендации")
                .font(TypographyTokens.titleSmall)
                .foregroundStyle(ColorTokens.textPrimary)
                .luneScreenPadding()
            
            LuneCard {
                HStack(spacing: SpacingTokens.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: SpacingTokens.iconMd))
                        .foregroundStyle(ColorTokens.rosePrimary)
                    
                    Text("Регулярно отслеживайте симптомы для более точного прогноза")
                        .font(TypographyTokens.bodyMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                    
                    Spacer()
                }
            }
            .luneScreenPadding()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
