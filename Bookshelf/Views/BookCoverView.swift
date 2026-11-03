import SwiftUI

/// Обложка книги. Если адреса нет или картинка не загрузилась — заглушка с названием.
struct BookCoverView: View {
    let title: String
    let coverURL: URL?
    var size = CGSize(width: 48, height: 72)
    var cornerRadius: CGFloat = 4

    /// Базовые размеры шрифта заглушки рассчитаны на ширину 48pt.
    private var scale: CGFloat { size.width / 48 }

    var body: some View {
        Group {
            if let coverURL {
                AsyncImage(url: coverURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        placeholder.overlay { ProgressView() }
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        // Тонкая светлая обводка: тёмная обложка не сливается с тёмным фоном.
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Theme.Colors.textOnDark.opacity(0.12), lineWidth: 0.5)
        }
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(Theme.Colors.backgroundDark.gradient)
            Text(title)
                .font(.system(size: Self.placeholderFontSize(for: title) * scale, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.Colors.textOnDark)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .minimumScaleFactor(0.6)
                .padding(4 * scale)
        }
    }

    /// Ширина текста на обложке шириной 48pt (без отступов) и средняя ширина буквы в долях кегля.
    private static let placeholderTextWidth: CGFloat = 40
    private static let averageCharWidth: CGFloat = 0.55

    /// Размер шрифта заглушки (для обложки шириной 48pt): короткие названия крупнее,
    /// чтобы не терялись на обложке. Самое длинное слово должно поместиться в строку целиком —
    /// иначе SwiftUI разорвёт его посередине, а не уменьшит шрифт.
    static func placeholderFontSize(for title: String) -> CGFloat {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let base: CGFloat = switch trimmed.count {
        case ...4: 18
        case ...12: 12
        default: 9
        }
        let longestWord = trimmed.split(whereSeparator: \.isWhitespace).map(\.count).max() ?? 0
        guard longestWord > 0 else { return base }
        return min(base, placeholderTextWidth / (CGFloat(longestWord) * averageCharWidth))
    }
}

#Preview {
    HStack(spacing: 16) {
        BookCoverView(title: "Я", coverURL: nil)
        BookCoverView(title: "1984", coverURL: nil)
        BookCoverView(title: "Война и мир", coverURL: nil)
        BookCoverView(title: "Очень длинное название книги, которое не влезает", coverURL: nil)
        BookCoverView(title: "Битая ссылка", coverURL: URL(string: "https://invalid.example/cover.jpg"))
    }
    .padding()
}

#Preview("Крупная") {
    HStack(spacing: 16) {
        BookCoverView(title: "Я", coverURL: nil, size: Theme.Metrics.coverSize)
        BookCoverView(title: "Мастер и Маргарита", coverURL: nil, size: Theme.Metrics.coverSize)
    }
    .padding()
}
