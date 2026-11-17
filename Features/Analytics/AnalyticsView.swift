import SwiftUI

struct AnalyticsView: View {
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.lg) {
                    // Empty state
                    EmptyAnalyticsState()
                }
                .padding(.vertical, SpacingTokens.sm)
            }
            .background(ColorTokens.background)
            .navigationTitle("Аналитика")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct EmptyAnalyticsState: View {
    
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            Spacer()
            
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundStyle(ColorTokens.textTertiary)
            
            Text("Недостаточно данных")
                .font(TypographyTokens.titleMedium)
                .foregroundStyle(ColorTokens.textPrimary)
            
            Text("Отслеживайте циклы для получения статистики")
                .font(TypographyTokens.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    AnalyticsView()
}
