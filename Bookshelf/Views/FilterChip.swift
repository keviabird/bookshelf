import SwiftUI

/// Чип фильтра: название и счётчик в капсуле. Выбранный чип — тёмный.
struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(Theme.Fonts.chipTitle)
                Text("\(count)")
                    .font(Theme.Fonts.chipCount)
                    .monospacedDigit()
            }
            .lineLimit(1)
            .padding(Theme.Metrics.chipPadding)
            .foregroundStyle(isSelected ? Theme.Colors.sheet : Theme.Colors.ink)
            .background(isSelected ? Theme.Colors.ink : Theme.Colors.muted, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(count)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        FilterChip(title: "Все", count: 5, isSelected: true) {}
        FilterChip(title: "Читаю", count: 2, isSelected: false) {}
    }
    .padding()
}
