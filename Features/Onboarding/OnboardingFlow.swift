import SwiftUI

struct OnboardingFlow: View {
    
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var selectedMode: AppMode = .cycleTracking
    @State private var lastPeriodStart: Date = Date()
    @State private var typicalCycleLength: Int? = 28
    @State private var typicalPeriodDuration: Int? = 5
    
    private let totalSteps = 5
    
    var body: some View {
        ZStack {
            ColorTokens.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .tint(ColorTokens.rosePrimary)
                    .padding(.horizontal, SpacingTokens.screenHorizontal)
                    .padding(.top, SpacingTokens.sm)
                
                // Content
                TabView(selection: $currentStep) {
                    ModeSelectionStep(selectedMode: $selectedMode)
                        .tag(0)
                    
                    LastPeriodStep(lastPeriodStart: $lastPeriodStart)
                        .tag(1)
                    
                    CycleLengthStep(cycleLength: $typicalCycleLength)
                        .tag(2)
                    
                    PeriodDurationStep(duration: $typicalPeriodDuration)
                        .tag(3)
                    
                    CompletionStep()
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation
                HStack(spacing: SpacingTokens.sm) {
                    if currentStep > 0 {
                        Button(action: previousStep) {
                            Text("Назад")
                                .font(TypographyTokens.labelMedium)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: SpacingTokens.buttonHeight)
                        }
                    }
                    
                    LunePrimaryButton(
                        title: currentStep == totalSteps - 1 ? "Завершить" : "Продолжить",
                        action: nextStep
                    )
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.bottom, SpacingTokens.md)
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func previousStep() {
        if currentStep > 0 {
            withAnimation {
                currentStep -= 1
            }
        }
    }
    
    private func completeOnboarding() {
        guard let profile = appState.userProfile else { return }
        
        // Сохраняем настройки
        profile.mode = selectedMode
        profile.typicalCycleLength = typicalCycleLength
        profile.typicalPeriodDuration = typicalPeriodDuration
        
        // Добавляем последний период
        let period = MenstrualPeriod(
            startDate: lastPeriodStart,
            endDate: nil,
            isConfirmed: true
        )
        DatabaseManager.shared.addPeriod(period)
        
        // Завершаем onboarding
        appState.completeOnboarding()
        dismiss()
    }
}

// MARK: - Шаг 1: Выбор режима

struct ModeSelectionStep: View {
    
    @Binding var selectedMode: AppMode
    
    var body: some View {
        VStack(spacing: SpacingTokens.xl) {
            VStack(spacing: SpacingTokens.sm) {
                Text("Выберите режим")
                    .luneTitleLarge()
                
                Text("Вы сможете изменить его в любое время")
                    .luneBodyMedium()
                    .multilineTextAlignment(.center)
            }
            .padding(.top, SpacingTokens.xxl)
            
            VStack(spacing: SpacingTokens.sm) {
                ForEach(AppMode.allCases, id: \.self) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        action: {
                            AnimationTokens.hapticSelection()
                            selectedMode = mode
                        }
                    )
                }
            }
            
            Spacer()
        }
        .luneScreenPadding()
    }
}

struct ModeCard: View {
    
    let mode: AppMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: SpacingTokens.sm) {
                Image(systemName: mode.iconName)
                    .font(.system(size: SpacingTokens.iconLg))
                    .foregroundStyle(isSelected ? ColorTokens.rosePrimary : ColorTokens.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(TypographyTokens.titleSmall)
                        .foregroundStyle(ColorTokens.textPrimary)
                    
                    Text(mode.description)
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ColorTokens.rosePrimary)
                        .font(.system(size: 24))
                }
            }
            .padding(SpacingTokens.sm)
            .background(
                RoundedRectangle(cornerRadius: SpacingTokens.radiusMd)
                    .fill(ColorTokens.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: SpacingTokens.radiusMd)
                            .strokeBorder(
                                isSelected ? ColorTokens.rosePrimary : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .luneCardShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Шаг 2: Последние месячные

struct LastPeriodStep: View {
    
    @Binding var lastPeriodStart: Date
    
    var body: some View {
        VStack(spacing: SpacingTokens.xl) {
            VStack(spacing: SpacingTokens.sm) {
                Text("Когда начались последние месячные?")
                    .luneTitleLarge()
                    .multilineTextAlignment(.center)
                
                Text("Это поможет точнее прогнозировать цикл")
                    .luneBodyMedium()
                    .multilineTextAlignment(.center)
            }
            .padding(.top, SpacingTokens.xxl)
            
            DatePicker(
                "Дата начала",
                selection: $lastPeriodStart,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(ColorTokens.rosePrimary)
            
            Spacer()
        }
        .luneScreenPadding()
    }
}

// MARK: - Шаг 3: Длина цикла

struct CycleLengthStep: View {
    
    @Binding var cycleLength: Int?
    @State private var selectedLength: Int = 28
    
    var body: some View {
        VStack(spacing: SpacingTokens.xl) {
            VStack(spacing: SpacingTokens.sm) {
                Text("Какова обычная длина вашего цикла?")
                    .luneTitleLarge()
                    .multilineTextAlignment(.center)
                
                Text("Это среднее количество дней от начала одних месячных до начала следующих")
                    .luneBodyMedium()
                    .multilineTextAlignment(.center)
            }
            .padding(.top, SpacingTokens.xxl)
            
            VStack(spacing: SpacingTokens.md) {
                Text("\(selectedLength) дней")
                    .font(TypographyTokens.numberLarge)
                    .foregroundStyle(ColorTokens.rosePrimary)
                
                Picker("Длина цикла", selection: $selectedLength) {
                    ForEach(21...45, id: \.self) { days in
                        Text("\(days)").tag(days)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                
                Button(action: {
                    cycleLength = nil
                }) {
                    Text("Не знаю")
                        .font(TypographyTokens.labelMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            
            Spacer()
        }
        .luneScreenPadding()
        .onChange(of: selectedLength) { _, newValue in
            cycleLength = newValue
        }
        .onAppear {
            if let length = cycleLength {
                selectedLength = length
            }
        }
    }
}

// MARK: - Шаг 4: Длительность месячных

struct PeriodDurationStep: View {
    
    @Binding var duration: Int?
    @State private var selectedDuration: Int = 5
    
    var body: some View {
        VStack(spacing: SpacingTokens.xl) {
            VStack(spacing: SpacingTokens.sm) {
                Text("Сколько обычно длятся месячные?")
                    .luneTitleLarge()
                    .multilineTextAlignment(.center)
                
                Text("Количество дней кровотечения")
                    .luneBodyMedium()
                    .multilineTextAlignment(.center)
            }
            .padding(.top, SpacingTokens.xxl)
            
            VStack(spacing: SpacingTokens.md) {
                Text("\(selectedDuration) дней")
                    .font(TypographyTokens.numberMedium)
                    .foregroundStyle(ColorTokens.rosePrimary)
                
                Picker("Длительность", selection: $selectedDuration) {
                    ForEach(2...10, id: \.self) { days in
                        Text("\(days)").tag(days)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                
                Button(action: {
                    duration = nil
                }) {
                    Text("Не знаю")
                        .font(TypographyTokens.labelMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            
            Spacer()
        }
        .luneScreenPadding()
        .onChange(of: selectedDuration) { _, newValue in
            duration = newValue
        }
        .onAppear {
            if let dur = duration {
                selectedDuration = dur
            }
        }
    }
}

// MARK: - Шаг 5: Завершение

struct CompletionStep: View {
    
    var body: some View {
        VStack(spacing: SpacingTokens.xl) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(ColorTokens.rosePrimary)
            
            VStack(spacing: SpacingTokens.sm) {
                Text("Всё готово!")
                    .luneDisplayLarge()
                
                Text("Начните отслеживать цикл и заботиться о своём здоровье")
                    .luneBodyMedium()
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .luneScreenPadding()
    }
}

#Preview {
    OnboardingFlow()
        .environmentObject(AppState())
}
