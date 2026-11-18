import SwiftUI

private enum CatalogSegment: String, Identifiable, CaseIterable, Hashable {
    case cycle, planning
    var id: String { rawValue }
}

/// Каталог компонентов для визуальной проверки в Xcode Previews.
/// Не является частью пользовательского интерфейса приложения.
struct ComponentCatalogView: View {
    @State private var selectedMood: MoodType?
    @State private var symptoms: Set<SymptomType> = [.pain]
    @State private var toggle = true
    @State private var segment: CatalogSegment = .cycle
    @State private var text = ""
    @State private var date = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                LuneCard {
                    Text("Карточка")
                        .font(TypographyTokens.titleSmall)
                    Text("Базовый контейнер с мягкой тенью и скруглением 22 pt.")
                        .font(TypographyTokens.bodyMedium)
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                LuneGradientCard(palette: .lavender) {
                    Text("Градиентная карточка")
                        .font(TypographyTokens.titleSmall)
                }

                LunePrimaryButton(title: "Основная кнопка", icon: "heart") {}
                LuneSecondaryButton(title: "Вторичная кнопка") {}
                LuneIconButton(symbol: "bell", accessibilityLabel: "Уведомления") {}

                LuneSectionHeader(title: "Заголовок секции", subtitle: "Подзаголовок", actionTitle: "Все") {}

                LuneChip(title: "Чип", icon: "sparkles")
                LuneSelectableChip(title: "Выбрано", isSelected: true) {}
                LuneSelectableChip(title: "Не выбрано", isSelected: false) {}

                LuneTextField(title: "Заметка", placeholder: "Введите текст", text: $text)
                LuneDatePicker(title: "Дата", date: $date)

                LuneSegmentedControl(options: CatalogSegment.allCases, selection: $segment) {
                    $0 == .cycle ? "Цикл" : "Планирование"
                }

                LuneCycleRing(day: 14, total: 28)

                LuneSymptomPicker(selection: symptoms) { symptom in
                    if symptoms.contains(symptom) { symptoms.remove(symptom) }
                    else { symptoms.insert(symptom) }
                }
                LuneMoodPicker(selection: $selectedMood)

                LuneTestResultCard(
                    title: "Тест на беременность",
                    date: CalendarDate(Date()),
                    result: .negative,
                    note: nil
                )

                LuneInsightCard(
                    symbol: "lightbulb",
                    title: "Подсказка",
                    detail: "Пример информационной подсказки без медицинского вывода.",
                    caution: "Не является диагнозом."
                )

                LuneSettingsRow(icon: "faceid", title: "Face ID", subtitle: "Защита данных", isOn: $toggle)
                LuneSettingsRow(icon: "gearshape", title: "Настройки", trailing: "Значение") {}

                LuneEmptyState(
                    symbol: "calendar.badge.plus",
                    title: "Пока нет записей",
                    message: "Добавьте первую дату начала менструации, чтобы увидеть прогноз.",
                    actionTitle: "Добавить"
                ) {}
            }
            .padding()
        }
        .background(ColorTokens.background)
    }
}

#Preview("Component catalog") {
    ComponentCatalogView()
}

#Preview("Component catalog • dark") {
    ComponentCatalogView()
        .preferredColorScheme(.dark)
}

#Preview("Component catalog • large text") {
    ComponentCatalogView()
        .environment(\.dynamicTypeSize, .accessibility3)
}
