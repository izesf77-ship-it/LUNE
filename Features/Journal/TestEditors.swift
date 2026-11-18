import SwiftUI

// MARK: - LH test

struct LHTestEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    let day: CalendarDate

    @State private var result: TestResult = .negative
    @State private var note = ""
    private let database = DatabaseManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneCard {
                        VStack(spacing: SpacingTokens.sm) {
                            Text("Результат ЛГ-теста")
                                .font(TypographyTokens.titleSmall)
                                .foregroundStyle(ColorTokens.textPrimary)

                            LuneSegmentedControl(options: TestResult.allCases, selection: $result) { $0.displayName }

                            LuneTextField(title: "Заметка", placeholder: "Необязательно", text: $note)

                            LunePrimaryButton(title: "Сохранить результат") {
                                database.insert(LHTestEntry(day: day, result: result, notes: note.isEmpty ? nil : note))
                                database.save()
                                appState.refresh()
                                appState.showToast("Результат сохранён")
                                dismiss()
                            }
                        }
                    }

                    LuneInsightCard(
                        symbol: "info.circle",
                        title: "Как понимать результат",
                        detail: "Положительный ЛГ-тест может указывать на приближение овуляции, но не доказывает, что она произошла.",
                        caution: "Результат теста не является медицинским диагнозом."
                    )

                    history
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.vertical, SpacingTokens.xs)
            }
            .background(ColorTokens.background)
            .navigationTitle("ЛГ-тест")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }.foregroundStyle(ColorTokens.roseDeep)
                }
            }
        }
    }

    private var history: some View {
        let entries = database.all(LHTestEntry.self).sorted { $0.day > $1.day }
        return VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            LuneSectionHeader(title: "История тестов", subtitle: entries.isEmpty ? nil : "\(entries.count)")
            if entries.isEmpty {
                LuneCard {
                    LuneEmptyState(symbol: "testtube.2", title: "Тестов пока нет", message: "Записанный результат появится здесь.")
                }
            } else {
                ForEach(entries.prefix(20), id: \.id) { entry in
                    LuneCard {
                        HStack {
                            LuneTestResultCard(title: "ЛГ-тест", date: entry.day, result: entry.result, note: entry.notes)
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
    }
}

// MARK: - Pregnancy test

struct PregnancyTestEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    let day: CalendarDate

    @State private var result: TestResult = .negative
    @State private var note = ""
    @State private var wantsObservation = false
    @State private var showConsent = false
    private let database = DatabaseManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.md) {
                    LuneCard {
                        VStack(spacing: SpacingTokens.sm) {
                            Text("Результат теста на беременность")
                                .font(TypographyTokens.titleSmall)
                                .foregroundStyle(ColorTokens.textPrimary)

                            LuneSegmentedControl(options: TestResult.allCases, selection: $result) { $0.displayName }

                            LuneTextField(title: "Заметка", placeholder: "Необязательно", text: $note)

                            if result == .positive {
                                VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                                    Text("Положительный результат — это сигнал, требующий медицинского подтверждения. Запись в приложении не является диагнозом и не меняет режим автоматически.")
                                        .font(TypographyTokens.bodySmall)
                                        .foregroundStyle(ColorTokens.textSecondary)
                                    Toggle("Сохранить историю и открыть информационный сценарий", isOn: $wantsObservation)
                                        .tint(ColorTokens.rosePrimary)
                                        .font(TypographyTokens.bodySmall)
                                }
                                .padding(SpacingTokens.sm)
                                .background(ColorTokens.blush.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: RadiusTokens.sm))
                            }

                            LunePrimaryButton(title: "Сохранить результат") {
                                if result == .positive && wantsObservation { showConsent = true }
                                else { save(observation: false) }
                            }
                        }
                    }

                    LuneInsightCard(
                        symbol: "info.circle",
                        title: "Интерпретация теста",
                        detail: "Следуйте инструкции производителя. Отрицательный результат может быть получен слишком рано — при отсутствии месячных тест можно повторить через неделю.",
                        caution: "По симптомам нельзя сделать вывод о беременности."
                    )

                    history
                }
                .padding(.horizontal, SpacingTokens.screenHorizontal)
                .padding(.vertical, SpacingTokens.xs)
            }
            .background(ColorTokens.background)
            .navigationTitle("Тест на беременность")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }.foregroundStyle(ColorTokens.roseDeep)
                }
            }
            .alert("Информационный сценарий", isPresented: $showConsent) {
                Button("Отмена", role: .cancel) { save(observation: false) }
                Button("Сохранить и открыть") { save(observation: true) }
            } message: {
                Text("Мы сохраним результат и откроем справочную информацию. Режим приложения не изменится автоматически.")
            }
        }
    }

    private func save(observation: Bool) {
        database.insert(PregnancyTestEntry(
            day: day,
            result: result,
            notes: note.isEmpty ? nil : note,
            wantsObservationScenario: observation
        ))
        database.save()
        appState.refresh()
        appState.showToast("Результат сохранён")
        dismiss()
    }

    private var history: some View {
        let entries = database.all(PregnancyTestEntry.self).sorted { $0.day > $1.day }
        return VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            LuneSectionHeader(title: "История тестов", subtitle: entries.isEmpty ? nil : "\(entries.count)")
            if entries.isEmpty {
                LuneCard {
                    LuneEmptyState(symbol: "cross.case", title: "Тестов пока нет", message: "Записанный результат появится здесь.")
                }
            } else {
                ForEach(entries.prefix(20), id: \.id) { entry in
                    LuneCard {
                        HStack {
                            LuneTestResultCard(
                                title: "Тест на беременность",
                                date: entry.day,
                                result: entry.result,
                                note: entry.notes
                            )
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
    }
}
