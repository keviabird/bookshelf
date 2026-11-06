import SwiftUI

/// Кнопка панели с нативным меню: выбор ключа сортировки и направления.
struct BookSortMenu: View {
    @Binding var sort: BookSort

    var body: some View {
        Menu {
            Picker("Сортировать по", selection: $sort.key) {
                ForEach(BookSortKey.allCases) { key in
                    Text(key.title).tag(key)
                }
            }
            Picker("Направление", selection: $sort.order) {
                ForEach(BookSortOrder.allCases) { order in
                    Label(order.title, systemImage: order.systemImage).tag(order)
                }
            }
        } label: {
            Label("Сортировка", systemImage: "arrow.up.arrow.down")
                .labelStyle(.iconOnly)
        }
        .accessibilityValue("\(sort.key.title), \(sort.order.title.lowercased())")
    }
}

#Preview {
    BookSortMenu(sort: .constant(.default))
        .tint(Theme.Colors.accent)
}
