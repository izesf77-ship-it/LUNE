import SwiftUI

/// Контроллер онбординга. Все вопросы допускают «Не знаю» или «Пропустить».
struct OnboardingFlow: View {
    @EnvironmentObject private var appState: AppState

    @State private var step = 0
    @State private var mode: AppMode = .cycleTracking
    @State private var lastPeriodDate: Date = Date()
    @State private var hasLastPeriod = true
    @State private var cycleLength: Int?
    @State private var periodDuration: Int?
    @State private var historyDates: [Date] = []
    @State private var notificationsOn = false
    @State private var faceIDOn = false
    @State private var isSaving = false

    private let totalSteps = 10

    var body: some View {
        NavigationStack {
            VStack(spacing: SpacingTokens.sm) {
                progressBar
                content
            }
            .background(ColorTokens.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step > 0 {
                        Button("Назад") {
                            withAnimation(AnimationTokens.selection) { step -= 1 }
                        }
                        .foregroundStyle(ColorTokens.textSecondary)
                        .frame(minHeight: SpacingTokens.touchMinimum)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Пропустить") {
                        finish(skipRest: true)
                    }
                    .font(TypographyTokens.labelMedium)
                    .foregroundStyle(ColorTokens.roseDeep)
                    .frame(minHeight: SpacingTokens.touchMinimum)
                }
            }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 5) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? ColorTokens.rosePrimary : ColorTokens.separator)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, SpacingTokens.screenHorizontal)
        .padding(.top, SpacingTokens.xxs)
        .accessibilityLabel("Шаг \(step + 1) из \(totalSteps)")
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            OnboardingStepShell(
                symbol: "sparkles",
                title: "Добро пожаловать в LUNÉ",
                message: "Пространство для наблюдения за циклом и самочувствием. Ваши данные остаются на этом iPhone.",
                buttonTitle: "Начать"
            ) { step = 1 }
        case 1:
            OnboardingStepShell(
                symbol: "hand.raised.fill",
                title: "Ваша приватность",
                message: "LUNÉ работает полностью офлайн: без аккаунта, интернета, аналитики и рекламы. Мы не отправляем ваши записи никуда — даже в облако.",
                buttonTitle: "Понятно"
            ) { step = 2 }
        case 2:
            ModeStep(mode: $mode) { step = 3 }
        case 3:
            LastPeriodStep(date: $lastPeriodDate, hasPeriod: $hasLastPeriod) { step = 4 }
        case 4:
            CycleLengthStep(length: $cycleLength) { step = 5 }
        case 5:
            PeriodDurationStep(duration: $periodDuration) { step = 6 }
        case 6:
            HistoryStep(dates: $historyDates) { step = 7 }
        case 7:
            NotificationsStep(isOn: $notificationsOn) { step = 8 }
        case 8:
            BiometricStep(isOn: $faceIDOn) { step = 9 }
        default:
            FinishStep(isSaving: isSaving) { finish(skipRest: false) }
        }
    }

    private func finish(skipRest: Bool) {
        guard !isSaving else { return }
        isSaving = true

        let profile = appState.profile ?? DatabaseManager.shared.fetchOrCreateProfile()
        profile.mode = mode
        profile.typicalCycleLength = skipRest ? nil : cycleLength
        profile.typicalPeriodDuration = skipRest ? nil : periodDuration
        profile.notificationsEnabled = skipRest ? false : notificationsOn
        profile.faceIDEnabled = skipRest ? false : faceIDOn && BiometricAuth.isAvailable()
        profile.hasCompletedOnboarding = true
        profile.touch()

        let database = DatabaseManager.shared
        if !skipRest && hasLastPeriod {
            let existing = Set(database.periods().map(\.startDayKey))
            let start = CalendarDate(lastPeriodDate)
            if !existing.contains(start.key) {
                database.insert(MenstrualPeriod(
                    startDay: start,
                    userReportedDuration: periodDuration
                ))
            }
        }
        if !skipRest {
            for date in historyDates {
                let day = CalendarDate(date)
                if !database.periods().contains(where: { $0.startDay == day }) {
                    database.insert(MenstrualPeriod(startDay: day))
                }
            }
        }
        database.save()
        appState.refresh()
        appState.showToast("Настройки сохранены")

        Task { @MainActor in
            await NotificationService.reschedule(
                enabled: profile.notificationsEnabled,
                prediction: appState.prediction,
                periodDaysBefore: profile.periodReminderDaysBefore,
                symptomHour: profile.symptomReminderEnabled ? profile.symptomReminderHour : nil,
                lhHour: nil,
                pregnancyHour: nil
            )
        }
    }
}

// MARK: - Shell

struct OnboardingStepShell<Content: View>: View {
    let symbol: String
    let title: String
    let message: String
    let buttonTitle: String
    let next: () -> Void
    let content: Content

    init(
        symbol: String,
        title: String,
        message: String,
        buttonTitle: String = "Продолжить",
        @ViewBuilder content: () -> Content = { EmptyView() },
        next: @escaping () -> Void
    ) {
        self.symbol = symbol
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.content = content()
        self.next = next
    }

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                Spacer(minLength: SpacingTokens.xl)

                Image(systemName: symbol)
                    .font(.system(size: 52))
                    .foregroundStyle(ColorTokens.rosePrimary)
                    .accessibilityHidden(true)

                VStack(spacing: SpacingTokens.xs) {
                    Text(title)
                        .font(TypographyTokens.displayMedium)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(TypographyTokens.bodyLarge)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                }

                content

                Spacer(minLength: SpacingTokens.lg)

                LunePrimaryButton(title: buttonTitle, action: next)
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .frame(minHeight: 560)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Early steps

struct ModeStep: View {
    @Binding var mode: AppMode
    let next: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            ForEach(AppMode.allCases) { option in
                Button {
                    AnimationTokens.selectionHaptic()
                    mode = option
                } label: {
                    HStack(spacing: SpacingTokens.sm) {
                        Image(systemName: option.iconName)
                            .font(.system(size: 26))
                            .foregroundStyle(ColorTokens.roseDeep)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.displayName)
                                .font(TypographyTokens.titleSmall)
                                .foregroundStyle(ColorTokens.textPrimary)
                            Text(option.description)
                                .font(TypographyTokens.bodySmall)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }
                        Spacer()
                        if mode == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ColorTokens.roseDeep)
                        }
                    }
                    .padding(SpacingTokens.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: RadiusTokens.md)
                            .fill(mode == option ? ColorTokens.blush.opacity(0.6) : ColorTokens.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: RadiusTokens.md)
                            .stroke(mode == option ? ColorTokens.rosePrimary : ColorTokens.separator, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(mode == option ? [.isSelected] : [])
            }

            Text("Режим можно изменить в любой момент в настройках. История при этом сохраняется.")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textTertiary)
                .multilineTextAlignment(.center)

            LunePrimaryButton(title: "Продолжить", action: next)
        }
    }
}

struct LastPeriodStep: View {
    @Binding var date: Date
    @Binding var hasPeriod: Bool
    let next: () -> Void

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            LuneSegmentedControl(
                options: OnboardingChoice.allCases,
                selection: Binding(
                    get: { hasPeriod ? .known : .unknown },
                    set: { hasPeriod = $0 == .known }
                )
            ) { $0.title }

            if hasPeriod {
                LuneDatePicker(title: "Дата начала последних месячных", date: $date)
            } else {
                Text("Это нормально. Прогноз появится после нескольких записей.")
                    .font(TypographyTokens.bodyMedium)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }

            LunePrimaryButton(title: "Продолжить", action: next)
        }
    }
}

enum OnboardingChoice: String, Identifiable, CaseIterable, Hashable {
    case known, unknown
    var id: String { rawValue }
    var title: String { self == .known ? "Знаю дату" : "Не знаю" }
}

struct CycleLengthStep: View {
    @Binding var length: Int?
    let next: () -> Void

    private let options = [21, 24, 26, 28, 30, 32, 35]

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 76), spacing: SpacingTokens.xs)],
                spacing: SpacingTokens.xs
            ) {
                ForEach(options, id: \.self) { value in
                    LuneSelectableChip(title: "\(value) дн.", isSelected: length == value) {
                        length = length == value ? nil : value
                    }
                }
            }

            Button("Не знаю") { length = nil; next() }
                .font(TypographyTokens.labelMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(minHeight: SpacingTokens.touchMinimum)

            LunePrimaryButton(title: length == nil ? "Пропустить" : "Продолжить", action: next)
        }
    }
}
