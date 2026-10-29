import Foundation
import Observation

@Observable
@MainActor
final class BookListViewModel {
    private(set) var books: [Book] = []
    private(set) var errorMessage: String?
    var isAddingBook = false

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
    }

    /// При ошибке список не очищается: остаются последние загруженные книги.
    func loadBooks() {
        do {
            books = try repository.fetchBooks()
            errorMessage = nil
        } catch {
            errorMessage = "Не удалось загрузить книги."
        }
    }

    func makeAddBookViewModel() -> AddBookViewModel {
        AddBookViewModel(repository: repository)
    }
}
