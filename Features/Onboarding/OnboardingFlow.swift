import SwiftUI

/// Цельный сценарий знакомства: приветствие показывается один раз (WelcomeView),
/// а здесь идут только вопросы. Любой ответ сохраняется, даже если пользователь
/// позже нажмёт «Пропустить».
struct OnboardingFlow: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = 0
    @State private var mode: AppMode = .cycleTracking
    @State private var lastPeriodDate: Date = Date()
    @State private var hasLastPeriod = false
    @State private var lastPeriodConfirmed = false
    @State private var cycleLength: Int?
    @State private var periodDuration: Int?
    @State private var historyDates: [Date] = []
    @State private var notificationsOn = false
    @State private var faceIDOn = false
    @State private var isSaving = false

    private let totalSteps = 9

    var body: some View {
        NavigationStack {
            VStack(spacing: SpacingTokens.xxs) {
                progressBar
                content
            }
            .background(ColorTokens.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step > 0 {
                        Button("Назад") {
                            withAnimation(reduceMotion ? nil : AnimationTokens.selection) { step -= 1 }
                        }
                        .font(TypographyTokens.Dynamic.bodyMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .frame(minHeight: SpacingTokens.touchMinimum)
                        .disabled(isSaving)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Пропустить") { finish() }
                        .font(TypographyTokens.Dynamic.bodyMedium)
                        .foregroundStyle(ColorTokens.roseDeep)
                        .frame(minHeight: SpacingTokens.touchMinimum)
                        .disabled(isSaving)
                }
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? ColorTokens.rosePrimary : ColorTokens.separator)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            Text("Шаг \(step + 1) из \(totalSteps)")
                .font(TypographyTokens.Dynamic.caption)
                .foregroundStyle(ColorTokens.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, SpacingTokens.screenHorizontal)
        .padding(.top, SpacingTokens.xxs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Шаг \(step + 1) из \(totalSteps)")
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0:
            OnboardingStepShell(
                symbol: "hand.raised.fill",
                title: "Только твоё. Только здесь",
                message: "LUNÉ работает полностью офлайн: без аккаунта, интернета и аналитики. Ни одна запись не покидает этот iPhone — даже в облако.",
                buttonTitle: "Хорошо"
            ) { step = 1 }
        case 1:
            ModeStep(mode: $mode) { step = 2 }
        case 2:
            LastPeriodStep(
                date: $lastPeriodDate,
                hasPeriod: $hasLastPeriod,
                lastConfirmed: lastPeriodConfirmed
            ) {
                lastPeriodConfirmed = true
                step = 3
            }
        case 3:
            CycleLengthStep(length: $cycleLength) { step = 4 }
        case 4:
            PeriodDurationStep(duration: $periodDuration) { step = 5 }
        case 5:
            HistoryStep(
                dates: $historyDates,
                excludedDate: (lastPeriodConfirmed && hasLastPeriod) ? CalendarDate(lastPeriodDate) : nil
            ) { step = 6 }
        case 6:
            NotificationsStep(isOn: $notificationsOn) { step = 7 }
        case 7:
            BiometricStep(isOn: $faceIDOn) { step = 8 }
        default:
            FinishStep(isSaving: isSaving) { finish() }
        }
    }

    /// Сохраняет все уже введённые ответы. «Пропустить» лишь завершает сценарий,
    /// но не обнуляет выбранные параметры и историю.
    private func finish() {
        guard !isSaving else { return }
        isSaving = true

        let draft = OnboardingDraft(
            mode: mode,
            hasLastPeriod: hasLastPeriod,
            lastPeriodConfirmed: lastPeriodConfirmed,
            lastPeriodDate: lastPeriodDate,
            cycleLength: cycleLength,
            periodDuration: periodDuration,
            historyDates: historyDates,
            notificationsOn: notificationsOn,
            faceIDOn: faceIDOn
        )

        let values = OnboardingDataNormalizer.profileValues(from: draft)
        let database = DatabaseManager.shared
        let profile = appState.profile ?? database.fetchOrCreateProfile()

        profile.mode = values.mode
        if let length = values.typicalCycleLength { profile.typicalCycleLength = length }
        if let duration = values.typicalPeriodDuration { profile.typicalPeriodDuration = duration }
        profile.notificationsEnabled = values.notificationsEnabled
        profile.faceIDEnabled = values.faceIDRequested && BiometricAuth.isAvailable()
        profile.hasCompletedOnboarding = true
        profile.touch()

        let existing = Set(database.periods().map(\.startDayKey))
        for day in OnboardingDataNormalizer.periodStarts(from: draft) where !existing.contains(day.key) {
            database.insert(MenstrualPeriod(
                startDay: day,
                userReportedDuration: values.typicalPeriodDuration
            ))
        }
        database.save()

        // Явно публикуем профиль, чтобы ContentView сразу показала MainTabView.
        appState.profile = profile
        appState.refresh()
        appState.showToast("Всё готово")

        Task { @MainActor in
            await NotificationService.reschedule(
                enabled: profile.notificationsEnabled,
                prediction: appState.prediction,
                periodDaysBefore: profile.periodReminderDaysBefore,
                symptomHour: profile.symptomReminderEnabled ? profile.symptomReminderHour : nil,
                lhHour: profile.lhTestReminderEnabled ? profile.lhTestReminderHour : nil,
                pregnancyHour: profile.pregnancyTestReminderEnabled ? profile.pregnancyTestReminderHour : nil
            )
        }
    }
}

// MARK: - Оболочка шага

struct OnboardingStepShell<Content: View>: View {
    let symbol: String
    let title: String
    let message: String
    let buttonTitle: String
    let next: () -> Void
    let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

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
            VStack(spacing: SpacingTokens.sm) {
                Spacer(minLength: SpacingTokens.sm)

                ZStack {
                    Circle().fill(ColorTokens.blush.opacity(0.75))
                    Image(systemName: symbol)
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(ColorTokens.roseDeep)
                }
                .frame(width: 88, height: 88)
                .accessibilityHidden(true)

                VStack(spacing: SpacingTokens.xs) {
                    Text(title)
                        .font(TypographyTokens.Dynamic.titleLarge)
                        .foregroundStyle(ColorTokens.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(TypographyTokens.Dynamic.bodyLarge)
                        .foregroundStyle(ColorTokens.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, SpacingTokens.xxs)

                content

                Spacer(minLength: SpacingTokens.sm)

                LunePrimaryButton(title: buttonTitle, action: next)
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.bottom, SpacingTokens.md)
            .frame(maxWidth: .infinity, minHeight: 520, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) { appeared = true }
        }
    }
}

// MARK: - Ранние шаги

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
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.displayName)
                                .font(TypographyTokens.Dynamic.titleSmall)
                                .foregroundStyle(ColorTokens.textPrimary)
                            Text(option.description)
                                .font(TypographyTokens.Dynamic.bodySmall)
                                .foregroundStyle(ColorTokens.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 4)
                        if mode == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ColorTokens.roseDeep)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(SpacingTokens.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: RadiusTokens.md)
                            .fill(mode == option ? ColorTokens.blush.opacity(0.7) : ColorTokens.surface)
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
                .font(TypographyTokens.Dynamic.caption)
                .foregroundStyle(ColorTokens.textTertiary)
                .multilineTextAlignment(.center)

            LunePrimaryButton(title: "Продолжить", action: next)
        }
    }
}

struct LastPeriodStep: View {
    @Binding var date: Date
    @Binding var hasPeriod: Bool
    let lastConfirmed: Bool
    let next: () -> Void

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

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
                LuneDatePicker(
                    title: "Дата начала последних месячных",
                    date: Binding(
                        get: { min(date, today) },
                        set: { date = min($0, today) }
                    ),
                    maximumDate: today
                )
                if lastConfirmed {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ColorTokens.success)
                        Text(CalendarDate(date).key)
                            .font(TypographyTokens.Dynamic.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    .accessibilityLabel("Дата выбрана")
                }
            } else {
                Text("Это нормально. Прогноз появится после нескольких записей — дату можно добавить позже.")
                    .font(TypographyTokens.Dynamic.bodyMedium)
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
            Text("Если знаешь обычную длительность цикла — выбери. Это поможет точнее оценить ближайшие даты.")
                .font(TypographyTokens.Dynamic.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 80), spacing: SpacingTokens.xs)],
                spacing: SpacingTokens.xs
            ) {
                ForEach(options, id: \.self) { value in
                    LuneSelectableChip(title: "\(value) дн.", isSelected: length == value) {
                        length = length == value ? nil : value
                    }
                }
            }

            Button("Не знаю") { length = nil; next() }
                .font(TypographyTokens.Dynamic.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .frame(minHeight: SpacingTokens.touchMinimum)

            LunePrimaryButton(title: length == nil ? "Пропустить" : "Продолжить", action: next)
        }
    }
}
