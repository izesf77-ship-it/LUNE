import SwiftUI

struct JournalView: View {
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SpacingTokens.lg) {
                    // Empty state
                    EmptyJournalState()
                }
                .padding(.vertical, SpacingTokens.sm)
            }
            .background(ColorTokens.background)
            .navigationTitle("Дневник")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct EmptyJournalState: View {
    
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            Spacer()
            
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundStyle(ColorTokens.textTertiary)
            
            Text("Дневник пуст")
                .font(TypographyTokens.titleMedium)
                .foregroundStyle(ColorTokens.textPrimary)
            
            Text("Начните отслеживать симптомы и настроение")
                .font(TypographyTokens.bodyMedium)
                .foregroundStyle(ColorTokens.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    JournalView()
}
