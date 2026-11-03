import SwiftUI

/// Тёмная шапка: заголовок по центру и кнопка добавления справа.
struct ShelfHeaderView: View {
    let onAdd: () -> Void

    var body: some View {
        ZStack {
            Text("Книжная полка")
                .textCase(.uppercase)
                .font(Theme.Fonts.headerTitle)
                .tracking(Theme.Fonts.headerTitleTracking)
                .foregroundStyle(Theme.Colors.textOnDark)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
                // Оставляем место под кнопку с обеих сторон, чтобы заголовок не наезжал на неё.
                .padding(.horizontal, 44)

            HStack {
                Spacer()
                Button(action: onAdd) {
                    Label("Добавить книгу", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    ShelfHeaderView {}
        .background(Theme.Colors.backgroundDark)
}
