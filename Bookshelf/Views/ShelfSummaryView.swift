import SwiftUI

/// Сводка «У вас на полке 5 книг» с крупной золотой цифрой.
/// Собрана из одного `Text`, поэтому переносится целиком и выравнивается по базовой линии.
struct ShelfSummaryView: View {
    let count: Int
    /// Слово в нужной форме: «книга», «книги» или «книг».
    let noun: String

    var body: some View {
        (
            Text("У вас на полке ")
            + Text("\(count)")
                .font(Theme.Fonts.summaryNumber)
                .foregroundStyle(Theme.Colors.accent)
            + Text(" \(noun)")
        )
        .font(Theme.Fonts.summaryText)
        .foregroundStyle(Theme.Colors.textPrimary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 24) {
        ShelfSummaryView(count: 1, noun: "книга")
        ShelfSummaryView(count: 5, noun: "книг")
        ShelfSummaryView(count: 22, noun: "книги")
    }
    .padding()
}
