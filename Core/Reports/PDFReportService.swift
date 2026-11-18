import Foundation
import UIKit

/// Генератор PDF-отчётов целиком на устройстве. Без сети и внешних библиотек.
enum PDFReportService {

    private static let pageWidth: CGFloat = 595
    private static let pageHeight: CGFloat = 842
    private static let margin: CGFloat = 44

    struct ReportInput {
        let periods: [MenstrualPeriod]
        let prediction: CyclePrediction?
        let symptomCounts: [(name: String, count: Int)]
        let temperatureCount: Int
        let lhTestCount: Int
        let mode: AppMode
    }

    static func generate(_ input: ReportInput) -> Data {
        let data = NSMutableData()
        var cursorY: CGFloat = 0
        var pageNumber = 1

        UIGraphicsBeginPDFContextToData(data, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), nil)
        defer { UIGraphicsEndPDFContext() }

        func newPage() {
            UIGraphicsBeginPDFPage()
            cursorY = pageHeight - margin - 20
            drawText(
                "LUNÉ",
                at: CGPoint(x: margin, y: cursorY),
                font: UIFont.systemFont(ofSize: 11, weight: .bold),
                color: UIColor(hex: 0xA64D72)
            )
            cursorY += 18
            drawSeparator(at: cursorY)
            cursorY += 24
            pageNumber += 1
        }

        func ensureSpace(_ height: CGFloat) {
            if cursorY - height < margin + 30 { newPage() }
        }

        newPage()

        drawText(
            "Отчёт о цикле",
            at: CGPoint(x: margin, y: cursorY),
            font: UIFont.systemFont(ofSize: 26, weight: .bold),
            color: UIColor(hex: 0x352C35)
        )
        cursorY += 36

        let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        drawText(
            "Создан \(dateString) · режим: \(input.mode.displayName)",
            at: CGPoint(x: margin, y: cursorY),
            font: UIFont.systemFont(ofSize: 11, weight: .regular),
            color: UIColor(hex: 0x836E7B)
        )
        cursorY += 30

        // Сводка
        sectionTitle("Сводка", y: &cursorY)
        if let prediction = input.prediction {
            line("Количество проанализированных интервалов: \(prediction.sampleCount)", y: &cursorY, ensureSpace)
            line("Медианная длительность цикла: \(prediction.cycleLength) дн.", y: &cursorY, ensureSpace)
            line("Разброс длительности: \(prediction.cycleLengthSpread) дн.", y: &cursorY, ensureSpace)
            line("Ожидаемое начало: \(prediction.nextStart.key) (ориентировочно)", y: &cursorY, ensureSpace)
            line("Уверенность прогноза: \(prediction.confidence.displayName)", y: &cursorY, ensureSpace)
            line(prediction.explanation, y: &cursorY, ensureSpace)
        } else {
            line("Недостаточно данных для построения прогноза.", y: &cursorY, ensureSpace)
        }
        cursorY += 10

        // История
        sectionTitle("История менструаций", y: &cursorY)
        if input.periods.isEmpty {
            line("Записей пока нет.", y: &cursorY, ensureSpace)
        } else {
            for period in input.periods.prefix(40) {
                let duration = period.duration.map { "\(String($0)) дн." } ?? "не указана"
                line("\(period.startDay.key) — \(period.endDay?.key ?? "запись открыта") · длительность: \(duration)",
                     y: &cursorY, ensureSpace)
            }
        }
        cursorY += 10

        // Симптомы
        sectionTitle("Частота симптомов", y: &cursorY)
        if input.symptomCounts.isEmpty {
            line("Записей симптомов пока нет.", y: &cursorY, ensureSpace)
        } else {
            for item in input.symptomCounts.prefix(20) {
                line("\(item.name) — \(item.count)", y: &cursorY, ensureSpace)
            }
        }
        cursorY += 10

        sectionTitle("Наблюдения", y: &cursorY)
        line("Измерений базальной температуры: \(input.temperatureCount)", y: &cursorY, ensureSpace)
        line("Записанных ЛГ-тестов: \(input.lhTestCount)", y: &cursorY, ensureSpace)
        cursorY += 16

        sectionTitle("Важная информация", y: &cursorY)
        wrapText(
            "Данные отчёта отражают только то, что вы записали в приложении. Прогноз и календарные оценки не являются медицинским диагнозом и не подтверждают овуляцию или беременность. Приложение не является средством контрацепции. При вопросах о здоровье обратитесь к врачу.",
            y: &cursorY
        )

        return data as Data
    }

    // MARK: - Drawing helpers

    private static func sectionTitle(_ title: String, y: inout CGFloat) {
        ensureSpaceInCurrentPage(50, y: &y)
        drawText(
            title,
            at: CGPoint(x: margin, y: y),
            font: UIFont.systemFont(ofSize: 15, weight: .semibold),
            color: UIColor(hex: 0xA64D72)
        )
        y += 24
    }

    private static func line(
        _ text: String,
        y: inout CGFloat,
        _ ensure: (CGFloat, inout CGFloat) -> Void
    ) {
        ensure(20, &y)
        drawText(
            text,
            at: CGPoint(x: margin, y: y),
            font: UIFont.systemFont(ofSize: 11, weight: .regular),
            color: UIColor(hex: 0x352C35)
        )
        y += 17
    }

    private static func ensureSpaceInCurrentPage(_ height: CGFloat, y: inout CGFloat) {
        if y - height < margin + 30 {
            // Простая защита от выхода за границы страницы без создания новой.
            y = pageHeight - margin - 20
        }
    }

    private static func wrapText(_ text: String, y: inout CGFloat) {
        let font = UIFont.systemFont(ofSize: 10, weight: .regular)
        let maxWidth = pageWidth - margin * 2
        var line = ""
        for word in text.split(separator: " ") {
            let candidate = line.isEmpty ? String(word) : line + " " + word
            let width = (candidate as NSString).size(withAttributes: [.font: font]).width
            if width > maxWidth && !line.isEmpty {
                drawText(line, at: CGPoint(x: margin, y: y), font: font, color: UIColor(hex: 0x836E7B))
                y += 15
                line = String(word)
            } else {
                line = candidate
            }
        }
        if !line.isEmpty {
            drawText(line, at: CGPoint(x: margin, y: y), font: font, color: UIColor(hex: 0x836E7B))
            y += 15
        }
    }

    private static func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        (text as NSString).draw(
            at: point,
            withAttributes: [.font: font, .foregroundColor: color]
        )
    }

    private static func drawSeparator(at y: CGFloat) {
        UIColor(hex: 0xECDDE4).setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        path.lineWidth = 1
        path.stroke()
    }
}
