import SwiftUI

// MARK: - Cycle ring

struct LuneCycleRing: View {
    let day: Int
    let total: Int
    var size: CGFloat = 132
    var lineWidth: CGFloat = 11
    var centerTop: String?
    var centerBottom: String = "день цикла"

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: CGFloat {
        guard total > 0 else { return 0 }
        return min(max(CGFloat(day) / CGFloat(total), 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(ColorTokens.surfaceSecondary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [ColorTokens.rosePrimary, ColorTokens.roseDeep],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AnimationTokens.resolved(AnimationTokens.progress, reduceMotion: reduceMotion), value: progress)

            VStack(spacing: 0) {
                if let centerTop {
                    Text(centerTop)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Text("\(day)")
                    .font(.system(size: size * 0.33, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ColorTokens.textPrimary)
                Text(centerBottom)
                    .font(.caption2)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("День \(day) из \(total)")
    }
}

// MARK: - Calendar day

enum CalendarDayKind: Equatable {
    case empty
    case normal
    case period
    case predictedPeriod
    case fertile
    case ovulation
    case symptom

    var fillColor: Color {
        switch self {
        case .empty: return .clear
        case .normal: return ColorTokens.surface
        case .period: return ColorTokens.periodActive.opacity(0.85)
        case .predictedPeriod: return ColorTokens.periodPredicted.opacity(0.55)
        case .fertile: return ColorTokens.fertilityWindow.opacity(0.35)
        case .ovulation: return ColorTokens.ovulation.opacity(0.5)
        case .symptom: return ColorTokens.blush
        }
    }
}

struct LuneCalendarDay: View {
    let date: CalendarDate
    var kind: CalendarDayKind = .normal
    var isToday: Bool = false
    var isSelected: Bool = false
    var hasObservation: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: {
            AnimationTokens.selectionHaptic()
            action()
        }) {
            ZStack {
                if kind != .empty {
                    RoundedRectangle(cornerRadius: RadiusTokens.sm)
                        .fill(kind.fillColor)

                    if isSelected {
                        RoundedRectangle(cornerRadius: RadiusTokens.sm)
                            .stroke(ColorTokens.selectedRing, lineWidth: 2)
                    } else if isToday {
                        RoundedRectangle(cornerRadius: RadiusTokens.sm)
                            .stroke(ColorTokens.todayRing, lineWidth: 2)
                    }

                    Text("\(date.day)")
                        .font(TypographyTokens.numberCalendar)
                        .foregroundStyle(
                            kind == .period || kind == .ovulation
                                ? Color.white
                                : ColorTokens.textPrimary
                        )

                    if hasObservation {
                        Circle()
                            .fill(ColorTokens.roseDeep)
                            .frame(width: 4, height: 4)
                            .offset(y: 13)
                    }
                }
            }
            .frame(width: SpacingTokens.calendarDaySize, height: SpacingTokens.calendarDaySize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(kind == .empty)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var accessibilityDescription: String {
        guard kind != .empty else { return "" }
        var parts = ["\(date.day) \(monthName(date.month))"]
        switch kind {
        case .period: parts.append("месячные")
        case .predictedPeriod: parts.append("прогноз месячных")
        case .fertile: parts.append("ориентировочное фертильное окно")
        case .ovulation: parts.append("ориентировочная дата овуляции")
        case .symptom: parts.append("есть запись симптома")
        default: break
        }
        if isToday { parts.append("сегодня") }
        return parts.joined(separator: ", ")
    }

    private func monthName(_ month: Int) -> String {
        DateFormatter().shortMonthSymbols[safe: month - 1] ?? ""
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Legend

struct LuneCalendarLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
            FlowLayout(spacing: SpacingTokens.sm) {
                legendItem("Месячные", ColorTokens.periodActive.opacity(0.85))
                legendItem("Прогноз", ColorTokens.periodPredicted.opacity(0.55))
                legendItem("Фертильное окно", ColorTokens.fertilityWindow.opacity(0.35))
                legendItem("Овуляция", ColorTokens.ovulation.opacity(0.5))
                legendItem("Наблюдение", ColorTokens.blush)
            }
        }
    }

    private func legendItem(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(title)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
        }
    }
}

/// Простая flex-раскладка без внешних зависимостей.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeRows(proposal: proposal, subviews: subviews)
        let width = rows.map(\.totalWidth).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.rowHeight } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrangeRows(proposal: proposal, subviews: subviews) {
            var x = bounds.minX
            for item in row.items {
                item.view.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(width: item.width, height: item.height)
                )
                x += item.width + spacing
            }
            y += row.rowHeight + spacing
        }
    }

    private struct Row {
        var items: [(view: LayoutSubviews.Element, width: CGFloat, height: CGFloat)]
        var totalWidth: CGFloat {
            var widths: CGFloat = 0
            for item in items { widths += item.width }
            let gaps = max(items.count - 1, 0)
            return widths + spacing * CGFloat(gaps)
        }

        var rowHeight: CGFloat {
            var highest: CGFloat = 0
            for item in items { highest = max(highest, item.height) }
            return highest
        }
    }

    private func arrangeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row(items: [])

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            let candidate = current.totalWidth + (current.items.isEmpty ? 0 : spacing) + size.width
            if candidate > maxWidth && !current.items.isEmpty {
                rows.append(current)
                current = Row(items: [])
            }
            current.items.append((view, size.width, size.height))
        }
        if !current.items.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Insight card

struct LuneInsightCard: View {
    let symbol: String
    let title: String
    let detail: String
    var caution: String?
    var tint: Color = ColorTokens.lavender

    var body: some View {
        LuneCard(background: tint.opacity(0.35), showShadow: false) {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                Image(systemName: symbol)
                    .font(.system(size: SpacingTokens.iconMd))
                    .foregroundStyle(ColorTokens.roseDeep)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(TypographyTokens.titleSmall)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(detail)
                        .font(TypographyTokens.bodyMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                    if let caution {
                        Text(caution)
                            .font(TypographyTokens.caption)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Test result card

struct LuneTestResultCard: View {
    let title: String
    let date: CalendarDate
    let result: TestResult
    let note: String?

    var body: some View {
        LuneCard {
            HStack(spacing: SpacingTokens.sm) {
                Image(systemName: result.symbolName)
                    .font(.system(size: 26))
                    .foregroundStyle(resultColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(TypographyTokens.labelMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                    Text(date.key)
                        .font(TypographyTokens.bodyLarge)
                        .foregroundStyle(ColorTokens.textPrimary)
                    Text(result.displayName)
                        .font(TypographyTokens.labelMedium)
                        .foregroundStyle(resultColor)
                    if let note, !note.isEmpty {
                        Text(note)
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var resultColor: Color {
        switch result {
        case .positive: return ColorTokens.testPositive
        case .negative: return ColorTokens.testNegative
        case .invalid: return ColorTokens.testInvalid
        }
    }
}
