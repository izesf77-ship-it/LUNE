import SwiftUI

struct RecommendationsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var category: RecommendationCategory?

    private var items: [PresentedRecommendation] {
        let all = RecommendationEngine.recommendations(for: appState.recommendationContext)
        guard let category else { return all }
        return all.filter { $0.recommendation.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.sm) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SpacingTokens.xs) {
                        LuneSelectableChip(title: "Все", isSelected: category == nil) { category = nil }
                        ForEach(RecommendationCategory.allCases, id: \.self) { item in
                            LuneSelectableChip(
                                title: item.displayName,
                                isSelected: category == item
                            ) { category = category == item ? nil : item }
                        }
                    }
                    .padding(.horizontal, SpacingTokens.screenHorizontal)
                }

                if items.isEmpty {
                    LuneCard {
                        LuneEmptyState(
                            symbol: "lightbulb",
                            title: "Нет подходящих рекомендаций",
                            message: "Выберите другую категорию — подсказки зависят от ваших записей и режима."
                        )
                    }
                } else {
                    ForEach(items) { item in
                        LuneCard {
                            VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                                HStack {
                                    Label(item.recommendation.category.displayName,
                                          systemImage: "bookmark")
                                        .font(TypographyTokens.caption)
                                        .foregroundStyle(ColorTokens.roseDeep)
                                    Spacer()
                                    if item.recommendation.safety == .urgentInformation {
                                        LuneChip(title: "Важно", color: ColorTokens.warning)
                                    }
                                }
                                Text(item.recommendation.title)
                                    .font(TypographyTokens.titleSmall)
                                    .foregroundStyle(ColorTokens.textPrimary)
                                Text(item.recommendation.text)
                                    .font(TypographyTokens.bodyMedium)
                                    .foregroundStyle(ColorTokens.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Divider()
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Источник: \(item.recommendation.sourceURL)")
                                        .font(TypographyTokens.caption)
                                        .foregroundStyle(ColorTokens.textTertiary)
                                        .textSelection(.enabled)
                                    Text("Проверено: \(item.recommendation.medicalReviewDate)")
                                        .font(TypographyTokens.caption)
                                        .foregroundStyle(ColorTokens.textTertiary)
                                }
                            }
                        }
                    }
                }

                Text("Рекомендации носят информационный характер и не заменяют консультацию врача.")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SpacingTokens.screenHorizontal)
            }
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("Рекомендации")
        .navigationBarTitleDisplayMode(.inline)
    }
}
