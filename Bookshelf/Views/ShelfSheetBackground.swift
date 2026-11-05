import SwiftUI

extension View {
    /// Фон экранов полки: тёмный верх и светлый лист со скруглёнными верхними углами.
    func shelfSheetBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                UnevenRoundedRectangle(
                    topLeadingRadius: Theme.Metrics.sheetCornerRadius,
                    topTrailingRadius: Theme.Metrics.sheetCornerRadius
                )
                .fill(Theme.Colors.surface)
                .ignoresSafeArea(edges: .bottom)
            }
            .padding(.top, 8)
            .background { Theme.Colors.backgroundDark.ignoresSafeArea() }
    }
}
