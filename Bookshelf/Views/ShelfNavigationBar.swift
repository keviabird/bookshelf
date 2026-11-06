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
    ///
    /// - Parameter title: заголовок по центру. `nil` — экран ставит заголовок сам,
    ///   через `ShelfLeadingTitle` (список: справа две кнопки, по центру заголовок не помещается).
    func shelfNavigationBar(title: LocalizedStringKey?) -> some View {
        navigationBarTitleDisplayMode(.inline)
            // Фон панели прозрачный — под ней тёмный фон экрана. Своя заливка панели взяла бы
            // тёмный вариант цвета из-за `toolbarColorScheme(.dark)` и отличалась бы от фона.
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if let title {
                    ToolbarItem(placement: .principal) {
                        ShelfNavigationTitle(title)
                    }
                }
            }
    }
}

/// Заголовок слева, после левых кнопок панели — одинаково на любой ширине экрана.
/// В `principal` так не выйдет: система центрирует его, если хватает места, и прижимает, если нет.
struct ShelfLeadingTitle: ToolbarContent {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    var body: some ToolbarContent {
        if #available(iOS 26, *) {
            // Без этого iOS 26 обернёт текст стеклянной капсулой, как кнопку.
            ToolbarItem(placement: .topBarLeading) {
                ShelfNavigationTitle(title)
                    // Элементу слева система даёт ширину по минимуму — без fixedSize текст обрезается.
                    .fixedSize()
                    // Иначе на крупном шрифте заголовок вытеснит кнопки справа в меню «•••».
                    .dynamicTypeSize(...DynamicTypeSize.large)
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) {
                ShelfNavigationTitle(title)
                    // Элементу слева система даёт ширину по минимуму — без fixedSize текст обрезается.
                    .fixedSize()
                    // Иначе на крупном шрифте заголовок вытеснит кнопки справа в меню «•••».
                    .dynamicTypeSize(...DynamicTypeSize.large)
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
