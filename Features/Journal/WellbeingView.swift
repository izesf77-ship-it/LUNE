import SwiftUI

struct WellbeingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    let day: CalendarDate

    @State private var energy: Int = 3
    @State private var sleep: Double = 7
    @State private var pain: Int = 0
    @State private var bloating: Int = 0
    @State private var note = ""
    private let database = DatabaseManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneCard {
                        VStack(spacing: SpacingTokens.sm) {
                            Text("Как ты себя чувствуешь?")
                                .font(TypographyTokens.titleSmall)
                                .foregroundStyle(ColorTokens.textPrimary)

                            settingRow("Энергия", value: $energy, range: 1...5, label: "из 5")
                            settingRow("Боль", value: $pain, range: 0...10, label: "из 10")
                            settingRow("Вздутие", value: $bloating, range: 0...3, label: "из 3")

                            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                                HStack {
                                    Text("Сон")
                                        .font(TypographyTokens.labelMedium)
                                    Spacer()
                                    Text(String(format: "%.1f ч", sleep))
                                        .font(TypographyTokens.labelMedium)
                                        .foregroundStyle(ColorTokens.roseDeep)
                                }
                                Slider(value: $sleep, in: 0...14, step: 0.5)
                                    .tint(ColorTokens.rosePrimary)
                            }

                            LuneTextField(title: "Заметка", placeholder: "Необязательно", text: $note, isMultiline: true)

                            LunePrimaryButton(title: "Сохранить") {
                                if let existing = database.records(DailyWellbeingEntry.self, on: day).first {
                                    existing.energy = energy
                                    existing.sleepHours = sleep
                                    existing.painLevel = pain
                                    existing.bloating = bloating
                                    existing.notes = note.isEmpty ? nil : note
                                    existing.touch()
                                } else {
                                    database.insert(DailyWellbeingEntry(
                                        day: day,
                                        energy: energy,
                                        sleepHours: sleep,
                                        painLevel: pain,
                                        bloating: bloating,
                                        notes: note.isEmpty ? nil : note
                                    ))
                                }
                                database.save()
                                appState.refresh()
                                appState.showToast("Самочувствие сохранено")
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
            }
            .background(ColorTokens.background)
            .navigationTitle("Самочувствие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }.foregroundStyle(ColorTokens.roseDeep)
                }
            }
            .onAppear {
                if let existing = database.records(DailyWellbeingEntry.self, on: day).first {
                    energy = existing.energy
                    sleep = existing.sleepHours
                    pain = existing.painLevel
                    bloating = existing.bloating
                    note = existing.notes ?? ""
                }
            }
        }
    }

    private func settingRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(TypographyTokens.labelMedium)
                Spacer()
                Text("\(value.wrappedValue) \(label)")
                    .font(TypographyTokens.labelMedium)
                    .foregroundStyle(ColorTokens.roseDeep)
            }
            Picker(title, selection: value) {
                ForEach(range, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(title)
        }
    }
}
