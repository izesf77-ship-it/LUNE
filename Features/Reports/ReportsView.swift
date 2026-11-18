import SwiftUI
import UIKit

struct ReportsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var pdfData: Data?
    @State private var showShare = false
    @State private var showError = false
    private let database = DatabaseManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                LuneCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Label("PDF-отчёт", systemImage: "doc.text.fill")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.roseDeep)
                        Text("Отчёт формируется на устройстве из ваших записей и не отправляется никуда. Включены история менструаций, сводка прогноза и частота симптомов.")
                            .font(TypographyTokens.bodyMedium)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                summaryCard

                LunePrimaryButton(title: "Создать PDF-отчёт", icon: "square.and.arrow.up") {
                    generate()
                }

                if showError {
                    Text("Не удалось создать отчёт. Попробуйте ещё раз.")
                        .font(TypographyTokens.bodySmall)
                        .foregroundStyle(ColorTokens.error)
                }

                LuneInsightCard(
                    symbol: "hand.raised",
                    title: "Приватность отчёта",
                    detail: "Файл создаётся локально. Поделиться им можно только через системное меню — по вашему решению.",
                    caution: "Отчёт не является медицинским заключением."
                )
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("Отчёты")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            if let pdfData {
                ShareSheet(items: [pdfData])
            }
        }
    }

    private var summaryCard: some View {
        let periods = database.all(MenstrualPeriod.self)
        let symptoms = database.all(DailySymptomEntry.self)
        return LuneCard {
            VStack(spacing: SpacingTokens.xs) {
                SummaryRow(title: "Записей о менструациях", value: "\(periods.count)")
                SummaryRow(title: "Записей симптомов", value: "\(symptoms.count)")
                SummaryRow(title: "Температурных измерений", value: "\(database.all(BasalTemperatureEntry.self).count)")
                SummaryRow(title: "ЛГ-тестов", value: "\(database.all(LHTestEntry.self).count)")
            }
        }
    }

    private func generate() {
        let records = database.all(DailySymptomEntry.self)
        let counts = Dictionary(grouping: records, by: \.symptom)
            .map { ($0.key.displayName, $0.value.count) }
            .sorted { $0.1 > $1.1 }

        let input = PDFReportService.ReportInput(
            periods: database.periods(),
            prediction: appState.prediction,
            symptomCounts: counts,
            temperatureCount: database.all(BasalTemperatureEntry.self).count,
            lhTestCount: database.all(LHTestEntry.self).count,
            mode: appState.mode
        )
        pdfData = PDFReportService.generate(input)
        showError = pdfData == nil
        if pdfData != nil { showShare = true }
    }
}

private struct SummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).font(TypographyTokens.bodyMedium)
            Spacer()
            Text(value)
                .font(TypographyTokens.labelMedium)
                .foregroundStyle(ColorTokens.roseDeep)
        }
        .frame(minHeight: 32)
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
