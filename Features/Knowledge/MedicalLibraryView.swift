import SwiftUI

struct MedicalLibraryView: View {
    @State private var search = ""
    @State private var selected: MedicalArticle?

    private var articles: [MedicalArticle] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return MedicalKnowledgeLibrary.articles }
        return MedicalKnowledgeLibrary.articles.filter {
            $0.title.lowercased().contains(query)
                || $0.summary.lowercased().contains(query)
                || $0.category.lowercased().contains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.sm) {
                LuneTextField(title: "Поиск по справочнику", placeholder: "Например, овуляция", text: $search)

                if articles.isEmpty {
                    LuneCard {
                        LuneEmptyState(
                            symbol: "magnifyingglass",
                            title: "Ничего не найдено",
                            message: "Попробуйте другой запрос."
                        )
                    }
                } else {
                    ForEach(articles) { article in
                        LuneCard {
                            Button {
                                selected = article
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(article.category)
                                        .font(TypographyTokens.caption)
                                        .foregroundStyle(ColorTokens.roseDeep)
                                    Text(article.title)
                                        .font(TypographyTokens.titleSmall)
                                        .foregroundStyle(ColorTokens.textPrimary)
                                    Text(article.summary)
                                        .font(TypographyTokens.bodySmall)
                                        .foregroundStyle(ColorTokens.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Text("Справочник встроен в приложение и доступен без интернета. Материалы носят информационный характер.")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SpacingTokens.screenHorizontal)
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("Справочник")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selected) { article in
            articleSheet(article)
        }
    }

    private func articleSheet(_ article: MedicalArticle) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SpacingTokens.md) {
                    Text(article.title)
                        .font(TypographyTokens.titleLarge)
                        .foregroundStyle(ColorTokens.textPrimary)

                    LuneCard {
                        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                            ForEach(article.details, id: \.self) { detail in
                                HStack(alignment: .top, spacing: SpacingTokens.xxs) {
                                    Text("•").foregroundStyle(ColorTokens.roseDeep)
                                    Text(detail)
                                        .font(TypographyTokens.bodyMedium)
                                        .foregroundStyle(ColorTokens.textSecondary)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Источник: \(article.sourceURL)")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(ColorTokens.textTertiary)
                            .textSelection(.enabled)
                        Text("Проверено: \(article.reviewDate)")
                            .font(TypographyTokens.caption)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                .padding()
            }
            .background(ColorTokens.background)
            .navigationTitle("Материал")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { selected = nil }
                        .foregroundStyle(ColorTokens.roseDeep)
                }
            }
        }
    }
}
