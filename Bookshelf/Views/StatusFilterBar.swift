import SwiftUI

/// Ряд чипов: «Все» и по одному на каждый статус. Можно выбрать несколько статусов.
/// Если чипы помещаются — стоят по центру, иначе прокручиваются вбок.
struct StatusFilterBar: View {
    let totalCount: Int
    let isAllSelected: Bool
    let count: (ReadingStatus) -> Int
    let isSelected: (ReadingStatus) -> Bool
    let onSelectAll: () -> Void
    let onToggle: (ReadingStatus) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            chips
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                chips
                    .padding(.horizontal)
            }
        }
    }

    private var chips: some View {
        HStack(spacing: 10) {
            StatusChip(title: "Все", count: totalCount, isSelected: isAllSelected, action: onSelectAll)
            ForEach(ReadingStatus.allCases) { status in
                StatusChip(
                    title: status.title,
                    count: count(status),
                    isSelected: isSelected(status),
                    action: { onToggle(status) }
                )
            }
        }
    }
}

#Preview {
    StatusFilterBar(
        totalCount: 5,
        isAllSelected: false,
        count: { _ in 2 },
        isSelected: { $0 != .finished },
        onSelectAll: {},
        onToggle: { _ in }
    )
}
