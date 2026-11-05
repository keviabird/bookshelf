import SwiftUI

/// Строка книги: номер (необязательно), обложка, название, автор и подвал.
/// На полке подвал — прогресс чтения, в поиске — год и кнопка добавления.
struct BookRowView<Footer: View>: View {
    /// nil — без кружка с номером.
    let rank: Int?
    let title: String
    let author: String
    let coverURL: URL?
    @ViewBuilder let footer: Footer

    init(
        rank: Int? = nil,
        title: String,
        author: String,
        coverURL: URL?,
        @ViewBuilder footer: () -> Footer
    ) {
        self.rank = rank
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.footer = footer()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Кружок номера заходит на обложку за счёт отрицательного отступа в стеке.
            HStack(alignment: .top, spacing: -Theme.Metrics.rankBadgeOverlap) {
                if let rank {
                    RankBadge(number: rank)
                        .padding(.top, 12)
                        .zIndex(1)
                }
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
                footer
            }
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        // Колонка с текстом растягивается до высоты обложки, и прогресс встаёт вниз.
        .fixedSize(horizontal: false, vertical: true)
        // Подвал может содержать кнопку, поэтому строка не схлопывается в один элемент VoiceOver.
        .accessibilityElement(children: .contain)
    }
}

/// Подвал строки на полке: полоса прогресса; nil — число страниц неизвестно, полосы нет.
struct BookRowProgressFooter: View {
    let progress: Double?

    var body: some View {
        if let progress {
            ReadingProgressBar(progress: progress)
                .padding(.bottom, 12)
        }
    }
}

extension BookRowView where Footer == BookRowProgressFooter {
    init(rank: Int?, title: String, author: String, coverURL: URL?, progress: Double?) {
        self.init(rank: rank, title: title, author: author, coverURL: coverURL) {
            BookRowProgressFooter(progress: progress)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        BookRowView(rank: 1, title: "Мастер и Маргарита", author: "Михаил Булгаков", coverURL: nil, progress: 0.14)
        BookRowView(rank: 2, title: "Мы", author: "", coverURL: nil, progress: 1)
        BookRowView(rank: 3, title: "Без страниц", author: "Неизвестно", coverURL: nil, progress: nil)
        BookRowView(title: "Без номера", author: "Поиск", coverURL: nil) {
            Text("1967").font(Theme.Fonts.progress)
        }
    }
    .padding()
}
