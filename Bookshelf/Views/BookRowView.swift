import SwiftUI

/// Строка списка: номер, обложка, название, автор и прогресс чтения.
struct BookRowView: View {
    let rank: Int
    let title: String
    let author: String
    let coverURL: URL?
    /// nil — число страниц неизвестно, полоса не показывается.
    let progress: Double?

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Кружок номера заходит на обложку за счёт отрицательного отступа в стеке.
            HStack(alignment: .top, spacing: -Theme.Metrics.rankBadgeOverlap) {
                RankBadge(number: rank)
                    .padding(.top, 12)
                    .zIndex(1)
                BookCoverView(title: title, coverURL: coverURL, size: Theme.Metrics.coverSize)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 4)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Theme.Fonts.bookTitle)
                    .lineLimit(2)
                if !author.isEmpty {
                    Text(author)
                        .font(Theme.Fonts.bookAuthor)
                        .tracking(0.5)
                        .lineLimit(2)
                }
                Spacer(minLength: 16)
                if let progress {
                    ReadingProgressBar(progress: progress)
                        .padding(.bottom, 12)
                }
            }
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        // Колонка с текстом растягивается до высоты обложки, и прогресс встаёт вниз.
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: 32) {
        BookRowView(rank: 1, title: "Мастер и Маргарита", author: "Михаил Булгаков", coverURL: nil, progress: 0.14)
        BookRowView(rank: 2, title: "Мы", author: "", coverURL: nil, progress: 1)
        BookRowView(rank: 3, title: "Без страниц", author: "Неизвестно", coverURL: nil, progress: nil)
    }
    .padding()
}
