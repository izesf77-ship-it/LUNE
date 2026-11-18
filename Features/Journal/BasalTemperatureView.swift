import SwiftUI
import Charts

struct BasalTemperatureView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var day = CalendarDate(Date()).localDate() ?? Date()
    @State private var celsius = 36.6
    @State private var note = ""

    private let database = DatabaseManager.shared

    private var entries: [BasalTemperatureEntry] {
        database.all(BasalTemperatureEntry.self).sorted { $0.day < $1.day }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneCard {
                        VStack(spacing: SpacingTokens.sm) {
                            LuneSectionHeader(title: "Новое измерение")
                            LuneDatePicker(title: "День", date: $day)
                            HStack {
                                Text("Температура")
                                    .font(TypographyTokens.labelMedium)
                                Spacer()
                                Text(String(format: "%.2f °C", celsius))
                                    .font(TypographyTokens.numberMedium)
                                    .foregroundStyle(ColorTokens.roseDeep)
                            }
                            Slider(value: $celsius, in: 35.0...39.0, step: 0.05)
                                .tint(ColorTokens.rosePrimary)
                            LuneTextField(title: "Заметка", placeholder: "Необязательно", text: $note)
                            LunePrimaryButton(title: "Сохранить измерение") {
                                database.insert(BasalTemperatureEntry(
                                    day: CalendarDate(day),
                                    celsius: celsius,
                                    notes: note.isEmpty ? nil : note
                                ))
                                database.save()
                                appState.refresh()
                                appState.showToast("Измерение сохранено")
                                note = ""
                            }
                        }
                    }

                    LuneCard {
                        LuneSectionHeader(
                            title: "График",
                            subtitle: "Ретроспективная закономерность, не подтверждение овуляции"
                        )
                        if entries.isEmpty {
                            LuneEmptyState(
                                symbol: "chart.xyaxis.line",
                                title: "Нет измерений",
                                message: "Добавьте первое измерение, чтобы увидеть график."
                            )
                        } else {
                            Chart(entries.suffix(21)) { entry in
                                LineMark(
                                    x: .value("День", entry.day.key),
                                    y: .value("°C", entry.celsius)
                                )
                                .foregroundStyle(ColorTokens.roseDeep)
                                .symbol(Circle())
                            }
                            .chartYScale(domain: 35.5...38.0)
                            .frame(height: 180)
                            .accessibilityLabel("График базальной температуры")
                        }
                    }

                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        LuneSectionHeader(title: "История", subtitle: entries.isEmpty ? nil : "\(entries.count)")
                        ForEach(entries.suffix(30).reversed(), id: \.id) { entry in
                            LuneCard {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(String(format: "%.2f °C", entry.celsius))
                                            .font(TypographyTokens.bodyLarge)
                                        Text(entry.day.key)
                                            .font(TypographyTokens.caption)
                                            .foregroundStyle(ColorTokens.textSecondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        database.delete(entry); appState.refresh()
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.vertical, SpacingTokens.xs)
            }
            .background(ColorTokens.background)
            .navigationTitle("Температура")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }.foregroundStyle(ColorTokens.roseDeep)
                }
            }
        }
    }
}
