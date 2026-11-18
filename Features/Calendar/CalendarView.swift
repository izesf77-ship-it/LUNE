import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var monthAnchor = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    @State private var selectedDay = CalendarDate(Date())
    @State private var showDayDetail = false
    @State private var showPeriodEditor = false

    private let database = DatabaseManager.shared
    private let weekdaySymbols = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    private var prediction: CyclePrediction { appState.prediction }
    private var snapshot: FertilitySnapshot { appState.fertilitySnapshot }
    private var today: CalendarDate { CalendarDate(Date()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    monthHeader
                    weekdayHeader
                    dayGrid
                    LuneCalendarLegend()
                    selectedDayCard
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.vertical, SpacingTokens.xs)
            }
            .background(ColorTokens.background)
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showDayDetail) {
                DayDetailView(day: selectedDay)
            }
            .sheet(isPresented: $showPeriodEditor) {
                PeriodEditorView(day: selectedDay)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            LuneIconButton(symbol: "chevron.left", accessibilityLabel: "Предыдущий месяц") {
                shiftMonth(by: -1)
            }
            Spacer()
            Text(monthTitle)
                .font(TypographyTokens.titleMedium)
                .foregroundStyle(ColorTokens.textPrimary)
            Spacer()
            LuneIconButton(symbol: "chevron.right", accessibilityLabel: "Следующий месяц") {
                shiftMonth(by: 1)
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: monthAnchor).capitalized
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: SpacingTokens.xxs), count: 7),
            spacing: SpacingTokens.xxs
        ) {
            ForEach(days.indices, id: \.self) { index in
                if let day = days[index] {
                    LuneCalendarDay(
                        date: day,
                        kind: kind(for: day),
                        isToday: day == today,
                        isSelected: day == selectedDay,
                        hasObservation: hasObservation(day)
                    ) {
                        selectedDay = day
                        AnimationTokens.selectionHaptic()
                    }
                } else {
                    Color.clear.frame(width: SpacingTokens.calendarDaySize, height: SpacingTokens.calendarDaySize)
                }
            }
        }
    }

    private var selectedDayCard: some View {
        LuneCard {
            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                HStack {
                    Text("\(selectedDay.day) \(monthName(selectedDay.month))")
                        .font(TypographyTokens.titleSmall)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Spacer()
                    if kind(for: selectedDay) == .period {
                        LuneChip(title: "Месячные", icon: "drop.fill", color: ColorTokens.periodActive)
                    } else if kind(for: selectedDay) == .predictedPeriod {
                        LuneChip(title: "Прогноз", color: ColorTokens.periodPredicted)
                    } else if kind(for: selectedDay) == .fertile || kind(for: selectedDay) == .ovulation {
                        LuneChip(title: "Ориентировочное окно", color: ColorTokens.fertilityWindow)
                    }
                }

                let symptoms = database.records(DailySymptomEntry.self, on: selectedDay)
                let moods = database.records(DailyMoodEntry.self, on: selectedDay)
                let notes = database.records(DailyNote.self, on: selectedDay)

                if symptoms.isEmpty && moods.isEmpty && notes.isEmpty {
                    Text("Нет записей за этот день")
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(symptoms, id: \.id) { entry in
                            Label(entry.symptom.displayName, systemImage: entry.symptom.iconName)
                        }
                        ForEach(moods, id: \.id) { entry in
                            Label("Настроение: \(entry.mood.displayName)", systemImage: entry.mood.symbolName)
                        }
                        ForEach(notes, id: \.id) { entry in
                            Label(entry.text, systemImage: "note.text")
                                .lineLimit(2)
                        }
                    }
                    .font(TypographyTokens.bodySmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                }

                HStack(spacing: SpacingTokens.xs) {
                    LuneSecondaryButton(title: "Открыть день") { showDayDetail = true }
                    LuneSecondaryButton(title: "Месячные") { showPeriodEditor = true }
                }
            }
        }
    }

    // MARK: - Helpers

    private func shiftMonth(by value: Int) {
        guard let date = Calendar.current.date(byAdding: .month, value: value, to: monthAnchor) else { return }
        monthAnchor = Calendar.current.dateInterval(of: .month, for: date)?.start ?? date
    }

    private func daysInMonth() -> [CalendarDate?] {
        let calendar = Calendar.gregorianUTC
        guard let range = calendar.range(of: .day, in: .month, for: monthAnchor) else { return [] }

        // Заголовок месяца строится в локальном календаре, сетка — в фиксированном UTC.
        let components = Calendar.current.dateComponents([.year, .month], from: monthAnchor)
        let year = components.year ?? 1970
        let month = components.month ?? 1

        let firstDay = CalendarDate(year: year, month: month, day: 1)
        let offset = (firstDay.weekday + 5) % 7
        var result: [CalendarDate?] = Array(repeating: nil, count: offset)
        for day in range {
            result.append(CalendarDate(year: year, month: month, day: day))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private func kind(for day: CalendarDate) -> CalendarDayKind {
        if database.all(MenstrualPeriod.self).contains(where: { $0.contains(day) }) {
            return .period
        }
        if prediction.nextStartRange.contains(day) {
            return .predictedPeriod
        }
        if day == snapshot.estimatedOvulationDay {
            return .ovulation
        }
        if appState.mode == .conceptionPlanning && snapshot.fertileWindow.contains(day) {
            return .fertile
        }
        if hasObservation(day) {
            return .symptom
        }
        return .normal
    }

    private func hasObservation(_ day: CalendarDate) -> Bool {
        !database.records(DailySymptomEntry.self, on: day).isEmpty
            || !database.records(DailyMoodEntry.self, on: day).isEmpty
            || !database.records(DailyNote.self, on: day).isEmpty
            || !database.records(BasalTemperatureEntry.self, on: day).isEmpty
            || !database.records(LHTestEntry.self, on: day).isEmpty
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.shortMonthSymbols[safe: month - 1] ?? ""
    }
}
