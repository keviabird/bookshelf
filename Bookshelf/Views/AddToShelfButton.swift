import SwiftUI

/// Кнопка добавления книги из поиска на полку, в стиле `StatusChip`.
/// Уже добавленная книга — светлая неактивная капсула «На полке».
struct AddToShelfButton: View {
    let isOnShelf: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // Не `Label`: в строке списка он может сам свернуться до одной иконки.
            HStack(spacing: 6) {
                Image(systemName: isOnShelf ? "checkmark" : "plus")
                Text(isOnShelf ? "На полке" : "На полку")
            }
            .font(Theme.Fonts.chipTitle)
            .lineLimit(1)
            .padding(Theme.Metrics.chipPadding)
            .foregroundStyle(isOnShelf ? Theme.Colors.textPrimary : Theme.Colors.surface)
            .background(isOnShelf ? Theme.Colors.track : Theme.Colors.textPrimary, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isOnShelf)
        .accessibilityLabel(isOnShelf ? "Уже на полке" : "Добавить на полку")
    }
}

#Preview {
    HStack {
        AddToShelfButton(isOnShelf: false) {}
        AddToShelfButton(isOnShelf: true) {}
    }
    .padding()
}
