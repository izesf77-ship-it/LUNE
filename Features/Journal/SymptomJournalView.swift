import SwiftUI

struct SymptomJournalView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    let day: CalendarDate

    @State private var intensity: IntensityOption = .medium
    private let database = DatabaseManager.shared

    private var entries: [DailySymptomEntry] {
        database.records(DailySymptomEntry.self, on: day)
    }

    private var selectedTypes: Set<SymptomType> {
        Set(entries.map(\.symptom))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneCard {
                        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                            Text("Одно касание — и симптом записан. Интенсивность можно выбрать отдельно.")
                                .font(TypographyTokens.bodySmall)
                                .foregroundStyle(ColorTokens.textSecondary)

                            LuneSegmentedControl(
                                options: IntensityOption.allCases,
                                selection: $intensity
                            ) { $0.title }

                            LuneSymptomPicker(selection: selectedTypes) { symptom in
                                toggle(symptom)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                        LuneSectionHeader(title: "Записано за день", subtitle: entries.isEmpty ? nil : "\(entries.count)")

                        if entries.isEmpty {
                            LuneCard {
                                LuneEmptyState(
                                    symbol: "bolt.circle",
                                    title: "Симптомов не отмечено",
                                    message: "Выберите симптом выше, если хотите что-то записать."
                                )
                            }
                        } else {
                            ForEach(entries, id: \.id) { entry in
                                LuneCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(entry.symptom.displayName)
                                                .font(TypographyTokens.bodyLarge)
                                            Text("Интенсивность \(entry.intensity) из 3")
                                                .font(TypographyTokens.caption)
                                                .foregroundStyle(ColorTokens.textSecondary)
                                            if let note = entry.notes, !note.isEmpty {
                                                Text(note)
                                                    .font(TypographyTokens.bodySmall)
                                                    .foregroundStyle(ColorTokens.textSecondary)
                                            }
                                        }
                                        Spacer()
                                        Menu {
                                            ForEach(1...3, id: \.self) { value in
                                                Button("Интенсивность \(value)") {
                                                    entry.intensity = value
                                                    entry.touch()
                                                    database.save()
                                                    appState.refresh()
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "slider.horizontal.3")
                                                .foregroundStyle(ColorTokens.roseDeep)
                                                .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                                        }
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
            .navigationTitle("Симптомы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundStyle(ColorTokens.roseDeep)
                }
            }
        }
    }

    private func toggle(_ symptom: SymptomType) {
        if let existing = entries.first(where: { $0.symptom == symptom }) {
            database.delete(existing)
        } else {
            database.insert(DailySymptomEntry(day: day, symptom: symptom, intensity: intensity.rawValue))
        }
        appState.refresh()
        AnimationTokens.selectionHaptic()
    }
}

enum IntensityOption: Int, Identifiable, CaseIterable, Hashable {
    case low = 1, medium = 2, high = 3
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .low: return "Слабо"
        case .medium: return "Умеренно"
        case .high: return "Сильно"
        }
    }
}
