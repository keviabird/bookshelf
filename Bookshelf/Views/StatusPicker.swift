import SwiftUI

/// Выбор статуса книги в карточке: три `StatusChip` по центру.
/// Если не помещаются в ширину (крупный текст), прокручиваются вбок.
struct StatusPicker: View {
    let selected: ReadingStatus
    let onSelect: (ReadingStatus) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            chips
                .frame(maxWidth: .infinity)
            ScrollView(.horizontal, showsIndicators: false) {
                chips
            }
        }
    }

    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(ReadingStatus.allCases) { status in
                StatusChip(title: status.title, isSelected: status == selected) {
                    onSelect(status)
                }
            }
        }
    }
}

#Preview {
    StatusPicker(selected: .reading) { _ in }
        .padding()
}
