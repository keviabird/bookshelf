import Foundation
import Observation

@Observable
@MainActor
final class AddBookViewModel {
    var title = ""
    var author = ""
    var coverURLString = ""
    var status: ReadingStatus = .wantToRead
    private(set) var errorMessage: String?

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedAuthor: String { author.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedCoverURL: String { coverURLString.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Корректный URL обложки или nil, если поле пустое либо адрес неверный.
    var coverURL: URL? {
        guard let url = URL(string: trimmedCoverURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil
        else { return nil }
        return url
    }

    /// Поле обложки необязательное, но если заполнено — адрес должен быть корректным.
    var isCoverURLValid: Bool {
        trimmedCoverURL.isEmpty || coverURL != nil
    }

    var canSave: Bool {
        !trimmedTitle.isEmpty && !trimmedAuthor.isEmpty && isCoverURLValid
    }

    /// Сохраняет книгу. Возвращает true при успехе.
    @discardableResult
    func save() -> Bool {
        guard canSave else { return false }
        let book = Book(
            title: trimmedTitle,
            author: trimmedAuthor,
            coverURL: coverURL,
            status: status
        )
        do {
            try repository.add(book)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
