import SwiftUI

struct LuneBottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    let content: Content

    init(
        isPresented: Binding<Bool>,
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: SpacingTokens.sm) {
            Capsule()
                .fill(ColorTokens.separator)
                .frame(width: 36, height: 5)
                .padding(.top, SpacingTokens.xxs)

            HStack {
                Text(title)
                    .font(TypographyTokens.titleSmall)
                    .foregroundStyle(ColorTokens.textPrimary)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ColorTokens.textSecondary)
                        .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Закрыть")
            }

            ScrollView {
                content
                    .padding(.bottom, SpacingTokens.xl)
            }
        }
        .padding(.horizontal, SpacingTokens.md)
        .background(ColorTokens.background)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}
