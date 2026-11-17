import SwiftUI

struct CalendarView: View {
    
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.lg) {
                    // Month Header
                    MonthHeader(currentMonth: $currentMonth)
                    
                    // Calendar Grid
                    CalendarGrid(
                        currentMonth: currentMonth,
                        selectedDate: $selectedDate
                    )
                    
                    // Day Details
                    if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
                        DayDetailsSection(date: selectedDate)
                    }
                }
                .padding(.vertical, SpacingTokens.sm)
            }
            .background(ColorTokens.background)
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Month Header

struct MonthHeader: View {
    
    @Binding var currentMonth: Date
    
    var body: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ColorTokens.rosePrimary)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(TypographyTokens.titleMedium)
                .foregroundStyle(ColorTokens.textPrimary)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(ColorTokens.rosePrimary)
            }
        }
        .luneScreenPadding()
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth).capitalized
    }
    
    private func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Calendar Grid

struct CalendarGrid: View {
    
    let currentMonth: Date
    @Binding var selectedDate: Date
    
    private let weekDays = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: SpacingTokens.calendarSpacing), count: 7)
    
    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            // Week days header
            HStack(spacing: SpacingTokens.calendarSpacing) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(TypographyTokens.labelSmall)
                        .foregroundStyle(ColorTokens.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid
            LazyVGrid(columns: columns, spacing: SpacingTokens.calendarSpacing) {
                ForEach(generateDays(), id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
                        )
                        .onTapGesture {
                            AnimationTokens.hapticSelection()
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: SpacingTokens.calendarDaySize)
                    }
                }
            }
        }
        .luneScreenPadding()
    }
    
    private func generateDays() -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        
        // Сдвиг (понедельник = 1)
        let shift = (firstWeekday == 1 ? 6 : firstWeekday - 2)
        
        var days: [Date?] = Array(repeating: nil, count: shift)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(bySetting: .day, value: day, of: currentMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}

// MARK: - Calendar Day View

struct CalendarDayView: View {
    
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(ColorTokens.rosePrimary)
            } else if isToday {
                Circle()
                    .strokeBorder(ColorTokens.rosePrimary, lineWidth: 2)
            }
            
            Text(dayNumber)
                .font(TypographyTokens.numberCalendar)
                .foregroundStyle(
                    isSelected ? .white :
                    isToday ? ColorTokens.rosePrimary :
                    isCurrentMonth ? ColorTokens.textPrimary :
                    ColorTokens.textTertiary
                )
        }
        .frame(width: SpacingTokens.calendarDaySize, height: SpacingTokens.calendarDaySize)
    }
}

// MARK: - Day Details Section

struct DayDetailsSection: View {
    
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            Text("Сегодня")
                .font(TypographyTokens.titleSmall)
                .foregroundStyle(ColorTokens.textPrimary)
                .luneScreenPadding()
            
            LuneCard {
                VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                    Text("Добавьте запись")
                        .font(TypographyTokens.bodyLarge)
                        .foregroundStyle(ColorTokens.textPrimary)
                    
                    Text("Отметьте симптомы, настроение или другие наблюдения")
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            .luneScreenPadding()
        }
    }
}

#Preview {
    CalendarView()
}
