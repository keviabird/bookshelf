import Foundation
import Observation

@Observable
final class BookListViewModel {
    private(set) var books: [Book] = []
    private(set) var errorMessage: String?
    var isAddingBook = false

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
    }

    func loadBooks() {
        do {
            books = try repository.fetchBooks()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func makeAddBookViewModel() -> AddBookViewModel {
        AddBookViewModel(repository: repository)
    }
}
