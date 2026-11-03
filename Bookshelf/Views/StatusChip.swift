import SwiftUI

/// Чип статуса (компонент «Status Chip» в Figma): название и необязательный счётчик в капсуле.
/// Выбранный чип — тёмный. Используется в фильтре списка (со счётчиком) и в карточке книги (без).
struct StatusChip: View {
    let title: String
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(Theme.Fonts.chipTitle)
                if let count {
                    Text("\(count)")
                        .font(Theme.Fonts.chipCount)
                        .monospacedDigit()
                }
            }
            .lineLimit(1)
            .padding(Theme.Metrics.chipPadding)
            .foregroundStyle(isSelected ? Theme.Colors.surface : Theme.Colors.textPrimary)
            .background(isSelected ? Theme.Colors.textPrimary : Theme.Colors.track, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(count.map { "\(title), \($0)" } ?? title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            StatusChip(title: "Все", count: 5, isSelected: true) {}
            StatusChip(title: "Читаю", count: 2, isSelected: false) {}
        }
        HStack {
            StatusChip(title: "Хочу прочитать", isSelected: false) {}
            StatusChip(title: "Читаю", isSelected: true) {}
        }
    }
    .padding()
}
