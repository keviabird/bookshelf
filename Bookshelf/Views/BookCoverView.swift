import SwiftUI

/// Обложка книги. Если адреса нет или картинка не загрузилась — заглушка с названием.
struct BookCoverView: View {
    let title: String
    let coverURL: URL?

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
        .frame(width: 48, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(Color.accentColor.gradient)
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .minimumScaleFactor(0.6)
                .padding(4)
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        BookCoverView(title: "Война и мир", coverURL: nil)
        BookCoverView(title: "Очень длинное название книги, которое не влезает", coverURL: nil)
        BookCoverView(title: "Битая ссылка", coverURL: URL(string: "https://invalid.example/cover.jpg"))
    }
    .padding()
}
