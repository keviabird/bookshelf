import SwiftUI

/// Заголовок тёмной панели навигации: капслок с разрядкой.
struct ShelfNavigationTitle: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .textCase(.uppercase)
            .font(Theme.Fonts.headerTitle)
            .tracking(Theme.Fonts.headerTitleTracking)
            .foregroundStyle(Theme.Colors.textOnDark)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityAddTraits(.isHeader)
    }
}

extension View {
    /// Системная панель навигации на тёмном фоне экрана. Она есть на всех экранах стека,
    /// поэтому при переходе панель плавно меняется, а не появляется заново
    /// (иначе кнопка «назад» вырастает стеклянным пузырём с бликом).
    func shelfNavigationBar(title: LocalizedStringKey) -> some View {
        navigationBarTitleDisplayMode(.inline)
            // Фон панели прозрачный — под ней тёмный фон экрана. Своя заливка панели взяла бы
            // тёмный вариант цвета из-за `toolbarColorScheme(.dark)` и отличалась бы от фона.
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ShelfNavigationTitle(title)
                }
            }
    }
}

#Preview {
    NavigationStack {
        Theme.Colors.backgroundDark
            .ignoresSafeArea()
            .shelfNavigationBar(title: "Книжная полка")
    }
}
