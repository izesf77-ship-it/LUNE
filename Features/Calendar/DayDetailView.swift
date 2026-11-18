import SwiftUI

struct DayDetailView: View {
    @EnvironmentObject private var appState: AppState
    let day: CalendarDate

    @State private var showPeriod = false
    @State private var showSymptoms = false
    @State private var showMood = false
    @State private var showLH = false
    @State private var showPregnancy = false
    @State private var showTemperature = false
    @State private var showMucus = false
    @State private var showNoteEditor = false
    @State private var noteText = ""

    private let database = DatabaseManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                header
                addActions
                records
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPeriod) { PeriodEditorView(day: day) }
        .sheet(isPresented: $showSymptoms) { SymptomJournalView(day: day) }
        .sheet(isPresented: $showMood) { MoodJournalView(day: day) }
        .sheet(isPresented: $showLH) { LHTestEditorView(day: day) }
        .sheet(isPresented: $showPregnancy) { PregnancyTestEditorView(day: day) }
        .sheet(isPresented: $showTemperature) { BasalTemperatureView() }
        .sheet(isPresented: $showMucus) { CervicalMucusView(day: day) }
        .sheet(isPresented: $showNoteEditor) { noteSheet }
    }

    private var title: String {
        "\(day.day) \(monthName(day.month))"
    }

    private var header: some View {
        LuneGradientCard(palette: .rose) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(TypographyTokens.displayMedium)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(day.key)
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.textSecondary)
                    Text("День \(day.days(until: database.periods().first?.startDay ?? day) + 1) относительно последней записанной менструации")
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var addActions: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
            LuneSectionHeader(title: "Добавить запись")
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100), spacing: SpacingTokens.xs)],
                spacing: SpacingTokens.xs
            ) {
                AddTile(title: "Месячные", symbol: "drop.fill") { showPeriod = true }
                AddTile(title: "Симптом", symbol: "bolt.circle") { showSymptoms = true }
                AddTile(title: "Настроение", symbol: "face.smiling") { showMood = true }
                AddTile(title: "Заметка", symbol: "note.text") { noteText = ""; showNoteEditor = true }
                AddTile(title: "ЛГ-тест", symbol: "testtube.2") { showLH = true }
                AddTile(title: "Тест на беременность", symbol: "cross.case") { showPregnancy = true }
                AddTile(title: "Температура", symbol: "thermometer") { showTemperature = true }
                AddTile(title: "Слизь", symbol: "drop") { showMucus = true }
                AddTile(title: "Близость", symbol: "heart") { addIntimacy() }
                AddTile(title: "Лекарство", symbol: "pills") { addMedication() }
            }
        }
    }

    @ViewBuilder
    private var records: some View {
        let symptoms = database.records(DailySymptomEntry.self, on: day)
        let moods = database.records(DailyMoodEntry.self, on: day)
        let notes = database.records(DailyNote.self, on: day)
        let bleeding = database.records(BleedingDayEntry.self, on: day)
        let temperatures = database.records(BasalTemperatureEntry.self, on: day)
        let mucus = database.records(CervicalMucusEntry.self, on: day)
        let lh = database.records(LHTestEntry.self, on: day)
        let pregnancy = database.records(PregnancyTestEntry.self, on: day)
        let intimacy = database.records(IntimacyEntry.self, on: day)
        let medications = database.records(MedicationEntry.self, on: day)

        if symptoms.isEmpty && moods.isEmpty && notes.isEmpty && bleeding.isEmpty
            && temperatures.isEmpty && mucus.isEmpty && lh.isEmpty && pregnancy.isEmpty
            && intimacy.isEmpty && medications.isEmpty {
            LuneCard {
                LuneEmptyState(
                    symbol: "square.and.pencil",
                    title: "За этот день пока нет записей",
                    message: "Выберите действие выше, чтобы добавить первое наблюдение."
                )
            }
        } else {
            VStack(spacing: SpacingTokens.sm) {
                recordSection("Симптомы") {
                    ForEach(symptoms, id: \.id) { item in
                        RecordRow(title: item.symptom.displayName, subtitle: "Интенсивность \(item.intensity) из 3") {
                            database.delete(item); appState.refresh()
                        }
                    }
                }
                recordSection("Настроение") {
                    ForEach(moods, id: \.id) { item in
                        RecordRow(title: item.mood.displayName, subtitle: item.note) {
                            database.delete(item); appState.refresh()
                        }
                    }
                }
                recordSection("Кровотечение") {
                    ForEach(bleeding, id: \.id) { item in
                        RecordRow(title: item.flowName, subtitle: item.notes) {
                            database.delete(item); appState.refresh()
                        }
                    }
                }
                recordSection("Температура") {
                    ForEach(temperatures, id: \.id) { item in
                        RecordRow(title: String(format: "%.2f °C", item.celsius), subtitle: item.notes) {
                            database.delete(item); appState.refresh()
                        }
                    }
                }
                recordSection("Цервикальная слизь") {
                    ForEach(mucus, id: \.id) { item in
                        RecordRow(title: item.type.displayName, subtitle: item.notes) {
                            database.delete(item); appState.refresh()
                        }
                    }
                }
                recordSection("Тесты") {
                    ForEach(lh, id: \.id) { item in
                        RecordRow(title: "ЛГ-тест: \(item.result.displayName)", subtitle: item.notes) {
                            database.delete(item); appState.refresh()
                        }
                    }
                    ForEach(pregnancy, id: \.id) { item in
                        RecordRow(title: "Тест на беременность: \(item.result.displayName)", subtitle: item.notes) {
                            database.delete(item); appState.refresh()
                        }
                    }
                }
                recordSection("Близость и лекарства") {
                    ForEach(intimacy, id: \.id) { item in
                        RecordRow(
                            title: item.protectionUsed ? "Близость (защита)" : "Близость",
                            subtitle: item.notes
                        ) { database.delete(item); appState.refresh() }
                    }
                    ForEach(medications, id: \.id) { item in
                        RecordRow(title: item.name, subtitle: item.dose) {
                            database.delete(item); appState.refresh()
                        }
                    }
                }
                recordSection("Заметки") {
                    ForEach(notes, id: \.id) { item in
                        RecordRow(title: item.text, subtitle: nil) {
                            database.delete(item); appState.refresh()
                        }
                    }
                }
            }
        }
    }

    private func recordSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        LuneCard {
            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                Text(title)
                    .font(TypographyTokens.labelMedium)
                    .foregroundStyle(ColorTokens.roseDeep)
                content()
            }
        }
    }

    private var noteSheet: some View {
        LuneBottomSheet(isPresented: $showNoteEditor, title: "Заметка на день") {
            VStack(spacing: SpacingTokens.sm) {
                LuneTextField(title: "Текст", placeholder: "О чём хотите помнить?", text: $noteText, isMultiline: true)
                LunePrimaryButton(title: "Сохранить") {
                    guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    database.insert(DailyNote(day: day, text: noteText))
                    appState.refresh()
                    showNoteEditor = false
                }
            }
        }
    }

    private func addIntimacy() {
        database.insert(IntimacyEntry(day: day))
        appState.refresh()
        appState.showToast("Запись сохранена")
    }

    private func addMedication() {
        database.insert(MedicationEntry(day: day, name: "Записанное лекарство"))
        appState.refresh()
        appState.showToast("Запись сохранена")
    }

    private func monthName(_ month: Int) -> String {
        DateFormatter().shortMonthSymbols[safe: month - 1] ?? ""
    }
}

struct AddTile: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button {
            AnimationTokens.lightHaptic()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(ColorTokens.roseDeep)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(ColorTokens.surfaceSecondary))
                Text(title)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 88)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct RecordRow: View {
    let title: String
    let subtitle: String?
    let delete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.xxs) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyTokens.bodyMedium)
                    .foregroundStyle(ColorTokens.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(TypographyTokens.caption)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            Spacer()
            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
            }
            .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
            .accessibilityLabel("Удалить запись")
        }
    }
}
