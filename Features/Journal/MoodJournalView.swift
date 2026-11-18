import SwiftUI

struct MoodJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    let day: CalendarDate

    @State private var selection: MoodType?
    @State private var note = ""
    private let database = DatabaseManager.shared

    private var entries: [DailyMoodEntry] {
        database.records(DailyMoodEntry.self, on: day)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneCard {
                        VStack(spacing: SpacingTokens.sm) {
                            Text("Как ты себя чувствуешь?")
                                .font(TypographyTokens.titleSmall)
                                .foregroundStyle(ColorTokens.textPrimary)
                            LuneMoodPicker(selection: $selection)
                            LuneTextField(title: "Заметка", placeholder: "Необязательно", text: $note)
                            LunePrimaryButton(title: "Сохранить настроение") {
                                guard let selection else { return }
                                database.insert(DailyMoodEntry(
                                    day: day,
                                    mood: selection,
                                    note: note.isEmpty ? nil : note
                                ))
                                database.save()
                                appState.refresh()
                                appState.showToast("Запись сохранена")
                                self.selection = nil
                                note = ""
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                        LuneSectionHeader(title: "Записи за день", subtitle: entries.isEmpty ? nil : "\(entries.count)")
                        if entries.isEmpty {
                            LuneCard {
                                LuneEmptyState(
                                    symbol: "face.smiling",
                                    title: "Настроение пока не отмечено",
                                    message: "Выберите подходящее состояние выше."
                                )
                            }
                        } else {
                            ForEach(entries, id: \.id) { entry in
                                LuneCard {
                                    HStack {
                                        Image(systemName: entry.mood.symbolName)
                                            .foregroundStyle(ColorTokens.roseDeep)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.mood.displayName)
                                                .font(TypographyTokens.bodyLarge)
                                            if let text = entry.note, !text.isEmpty {
                                                Text(text)
                                                    .font(TypographyTokens.bodySmall)
                                                    .foregroundStyle(ColorTokens.textSecondary)
                                            }
                                        }
                                        Spacer()
                                        Button(role: .destructive) {
                                            database.delete(entry)
                                            appState.refresh()
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.vertical, SpacingTokens.xs)
            }
            .background(ColorTokens.background)
            .navigationTitle("Настроение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }.foregroundStyle(ColorTokens.roseDeep)
                }
            }
        }
    }
}
