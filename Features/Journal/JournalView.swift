import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var appState: AppState
    @State private var day = CalendarDate(Date())
    @State private var showSymptoms = false
    @State private var showMood = false
    @State private var showWellbeing = false
    @State private var showNote = false
    @State private var noteText = ""

    private let database = DatabaseManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    dateHeader
                    quickEntry
                    wellbeingSummary
                    todayRecords
                    recentHistory
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.vertical, SpacingTokens.xs)
            }
            .background(ColorTokens.background)
            .navigationTitle("Дневник")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSymptoms) { SymptomJournalView(day: day) }
            .sheet(isPresented: $showMood) { MoodJournalView(day: day) }
            .sheet(isPresented: $showWellbeing) { WellbeingView(day: day) }
            .sheet(isPresented: $showNote) { noteSheet }
        }
    }

    private var dateHeader: some View {
        HStack {
            LuneIconButton(symbol: "chevron.left", accessibilityLabel: "Предыдущий день") {
                day = day.adding(days: -1)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(day.key)
                    .font(TypographyTokens.titleMedium)
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(day == CalendarDate(Date()) ? "Сегодня" : "")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
            Spacer()
            LuneIconButton(symbol: "chevron.right", accessibilityLabel: "Следующий день") {
                day = day.adding(days: 1)
            }
        }
    }

    private var quickEntry: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
            LuneSectionHeader(title: "Быстрые записи")
            HStack(spacing: SpacingTokens.sm) {
                QuickAction(title: "Симптомы", symbol: "bolt.circle", color: ColorTokens.roseDeep) { showSymptoms = true }
                QuickAction(title: "Настроение", symbol: "face.smiling", color: ColorTokens.rosePrimary) { showMood = true }
                QuickAction(title: "Самочувствие", symbol: "heart.circle", color: ColorTokens.roseDeep) { showWellbeing = true }
                QuickAction(title: "Заметка", symbol: "note.text", color: ColorTokens.lavender) {
                    noteText = ""; showNote = true
                }
            }
        }
    }

    private var wellbeingSummary: some View {
        let entries = database.records(DailyWellbeingEntry.self, on: day)
        return Group {
            if let entry = entries.first {
                LuneCard {
                    LuneSectionHeader(title: "Самочувствие", subtitle: day.key)
                    HStack(spacing: SpacingTokens.md) {
                        Metric(title: "Энергия", value: "\(entry.energy)/5")
                        Metric(title: "Сон", value: String(format: "%.1f ч", entry.sleepHours))
                        Metric(title: "Боль", value: "\(entry.painLevel)/10")
                        Metric(title: "Вздутие", value: "\(entry.bloating)/3")
                    }
                }
            } else {
                LuneCard {
                    LuneEmptyState(
                        symbol: "heart.circle",
                        title: "Самочувствие не отмечено",
                        message: "Одна запись в день помогает замечать личные закономерности.",
                        actionTitle: "Записать"
                    ) { showWellbeing = true }
                }
            }
        }
    }

    private var todayRecords: some View {
        let symptoms = database.records(DailySymptomEntry.self, on: day)
        let moods = database.records(DailyMoodEntry.self, on: day)
        let notes = database.records(DailyNote.self, on: day)

        return VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            LuneSectionHeader(title: "Записи за день")
            if symptoms.isEmpty && moods.isEmpty && notes.isEmpty {
                LuneCard {
                    LuneEmptyState(
                        symbol: "square.and.pencil",
                        title: "Пока пусто",
                        message: "Добавьте симптом, настроение или заметку."
                    )
                }
            } else {
                ForEach(symptoms, id: \.id) { entry in
                    RecordRow(title: entry.symptom.displayName, subtitle: "Интенсивность \(entry.intensity) из 3") {
                        database.delete(entry); appState.refresh()
                    }
                }
                ForEach(moods, id: \.id) { entry in
                    RecordRow(title: entry.mood.displayName, subtitle: entry.note) {
                        database.delete(entry); appState.refresh()
                    }
                }
                ForEach(notes, id: \.id) { entry in
                    RecordRow(title: entry.text, subtitle: nil) {
                        database.delete(entry); appState.refresh()
                    }
                }
            }
        }
    }

    private var recentHistory: some View {
        let allSymptoms = database.all(DailySymptomEntry.self)
        let sorted = Dictionary(grouping: allSymptoms, by: \.symptom)
            .map { ($0.key.displayName, $0.value.count) }
            .sorted { $0.1 > $1.1 }

        return Group {
            if !sorted.isEmpty {
                VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                    LuneSectionHeader(title: "Частые симптомы", subtitle: "По всем записям")
                    LuneCard {
                        ForEach(sorted.prefix(5), id: \.0) { item in
                            HStack {
                                Text(item.0).font(TypographyTokens.bodyMedium)
                                Spacer()
                                Text("\(item.1)")
                                    .font(TypographyTokens.labelMedium)
                                    .foregroundStyle(ColorTokens.roseDeep)
                            }
                            .frame(minHeight: 34)
                        }
                    }
                }
            }
        }
    }

    private var noteSheet: some View {
        LuneBottomSheet(isPresented: $showNote, title: "Заметка") {
            VStack(spacing: SpacingTokens.sm) {
                LuneTextField(title: "Текст", placeholder: "Что хотите запомнить?", text: $noteText, isMultiline: true)
                LunePrimaryButton(title: "Сохранить") {
                    guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    database.insert(DailyNote(day: day, text: noteText))
                    database.save()
                    appState.refresh()
                    appState.showToast("Заметка сохранена")
                    showNote = false
                }
            }
        }
    }
}

struct Metric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(TypographyTokens.labelLarge)
                .foregroundStyle(ColorTokens.roseDeep)
            Text(title)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
