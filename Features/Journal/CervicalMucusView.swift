import SwiftUI

struct CervicalMucusView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    let day: CalendarDate

    @State private var type: CervicalMucusType = .unknown
    @State private var note = ""
    private let database = DatabaseManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneCard {
                        VStack(spacing: SpacingTokens.sm) {
                            Text("Наблюдение за слизью")
                                .font(TypographyTokens.titleSmall)
                                .foregroundStyle(ColorTokens.textPrimary)

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 110), spacing: SpacingTokens.xs)],
                                spacing: SpacingTokens.xs
                            ) {
                                ForEach(CervicalMucusType.allCases) { option in
                                    LuneSelectableChip(
                                        title: option.displayName,
                                        isSelected: type == option
                                    ) { type = option }
                                }
                            }

                            LuneTextField(title: "Заметка", placeholder: "Необязательно", text: $note)

                            LunePrimaryButton(title: "Сохранить") {
                                database.insert(CervicalMucusEntry(
                                    day: day,
                                    type: type,
                                    notes: note.isEmpty ? nil : note
                                ))
                                database.save()
                                appState.refresh()
                                appState.showToast("Наблюдение сохранено")
                                dismiss()
                            }
                        }
                    }

                    LuneInsightCard(
                        symbol: "drop",
                        title: "Это наблюдение, а не подтверждение",
                        detail: "Изменения слизи могут быть одним из признаков фертильности, но не позволяют подтвердить овуляцию.",
                        caution: nil,
                        tint: ColorTokens.lavender
                    )
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
            }
            .background(ColorTokens.background)
            .navigationTitle("Цервикальная слизь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }.foregroundStyle(ColorTokens.roseDeep)
                }
            }
        }
    }
}
