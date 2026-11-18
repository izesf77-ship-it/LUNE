import SwiftUI

struct PeriodEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    let day: CalendarDate
    var period: MenstrualPeriod?

    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var hasEnd = false
    @State private var selectedDuration: Int?
    @State private var notes = ""
    @State private var showValidation = false

    private let database = DatabaseManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Даты") {
                    LuneDatePicker(title: "Начало менструации", date: $startDate)
                    Toggle("Уже закончилась", isOn: $hasEnd)
                        .tint(ColorTokens.rosePrimary)
                    if hasEnd {
                        LuneDatePicker(title: "Конец менструации", date: $endDate)
                    }
                }

                Section("Длительность") {
                    Text("Если знаете обычную длительность, выберите её. Расчёт по датам имеет приоритет.")
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(2...10, id: \.self) { value in
                                LuneSelectableChip(title: "\(value) дн.", isSelected: selectedDuration == value) {
                                    selectedDuration = selectedDuration == value ? nil : value
                                }
                            }
                        }
                    }
                }

                Section("Заметка") {
                    LuneTextField(title: "Необязательно", placeholder: "Например, самочувствие", text: $notes, isMultiline: true)
                }

                if showValidation {
                    Section {
                        Text("Дата окончания не может быть раньше даты начала.")
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.error)
                    }
                }

                if let period {
                    Section {
                        Button(role: .destructive) {
                            database.delete(period)
                            appState.refresh()
                            appState.showToast("Запись удалена")
                            dismiss()
                        } label: {
                            Label("Удалить запись", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(period == nil ? "Новая менструация" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }.foregroundStyle(ColorTokens.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { save() }
                        .foregroundStyle(ColorTokens.roseDeep)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: setup)
        }
    }

    private func setup() {
        let initial = day.localDate() ?? Date()
        startDate = period?.startDay.localDate() ?? initial
        if let end = period?.endDay {
            endDate = end.localDate() ?? initial
            hasEnd = true
        } else {
            hasEnd = false
        }
        selectedDuration = period?.userReportedDuration
        notes = period?.notes ?? ""
    }

    private func save() {
        let start = CalendarDate(startDate)
        let end = hasEnd ? CalendarDate(endDate) : nil

        if let end, end < start {
            showValidation = true
            AnimationTokens.errorHaptic()
            return
        }

        if let period {
            period.startDate = start.localDate() ?? startDate
            period.startDayKey = start.key
            period.endDate = end?.localDate()
            period.endDayKey = end?.key
            period.userReportedDuration = selectedDuration
            period.notes = notes.isEmpty ? nil : notes
            period.touch()
        } else {
            let duplicate = database.all(MenstrualPeriod.self).first { $0.startDay == start }
            if duplicate == nil {
                database.insert(MenstrualPeriod(
                    startDay: start,
                    endDay: end,
                    userReportedDuration: selectedDuration,
                    notes: notes.isEmpty ? nil : notes
                ))
            }
        }

        database.save()
        appState.refresh()
        appState.showToast("Запись сохранена")
        dismiss()
    }
}
