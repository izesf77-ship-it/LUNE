import SwiftUI

struct HistoricalCyclesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editingPeriod: MenstrualPeriod?
    private let database = DatabaseManager.shared

    private var periods: [MenstrualPeriod] { database.periods() }

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                LuneCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Text("Твоя история цикла")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.textPrimary)
                        Text("Список содержит только подтверждённые вами даты. Прогнозы здесь не хранятся.")
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                if periods.isEmpty {
                    LuneCard {
                        LuneEmptyState(
                            symbol: "calendar.badge.clock",
                            title: "История пока пуста",
                            message: "Добавьте даты начала менструаций — они появятся здесь и будут использованы для прогноза."
                        )
                    }
                } else {
                    ForEach(periods, id: \.id) { period in
                        LuneCard {
                            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                                Image(systemName: "drop.circle.fill")
                                    .foregroundStyle(ColorTokens.periodActive)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(period.startDay.key)
                                        .font(TypographyTokens.bodyLarge)
                                    if let end = period.endDay {
                                        Text("до \(end.key) · \(period.duration ?? 0) дн.")
                                            .font(TypographyTokens.bodySmall)
                                            .foregroundStyle(ColorTokens.textSecondary)
                                    } else {
                                        Text("Дата окончания не указана")
                                            .font(TypographyTokens.bodySmall)
                                            .foregroundStyle(ColorTokens.textSecondary)
                                    }
                                    if let notes = period.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(TypographyTokens.caption)
                                            .foregroundStyle(ColorTokens.textTertiary)
                                    }
                                }
                                Spacer()
                                Button {
                                    editingPeriod = period
                                } label: {
                                    Image(systemName: "pencil")
                                        .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(ColorTokens.roseDeep)
                                .accessibilityLabel("Редактировать запись")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("История циклов")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingPeriod) { period in
            PeriodEditorView(day: period.startDay, period: period)
        }
    }
}
