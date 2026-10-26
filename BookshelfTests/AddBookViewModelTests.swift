import Foundation
import Testing
@testable import Bookshelf

/// Хранилище в памяти для тестов ViewModel.
private final class InMemoryBookRepository: BookRepository {
    var books: [Book] = []
    func fetchBooks() throws -> [Book] { books }
    func add(_ book: Book) throws { books.append(book) }
    func delete(_ book: Book) throws { books.removeAll { $0 === book } }
}

@MainActor
struct AddBookViewModelTests {
    @Test func cannotSaveWithoutTitleOrAuthor() {
        let viewModel = AddBookViewModel(repository: InMemoryBookRepository())
        viewModel.title = "   "
        viewModel.author = "Толстой"
        #expect(!viewModel.canSave)

        viewModel.title = "Война и мир"
        viewModel.author = ""
        #expect(!viewModel.canSave)
    }

    @Test func invalidCoverURLBlocksSave() {
        let viewModel = AddBookViewModel(repository: InMemoryBookRepository())
        viewModel.title = "Война и мир"
        viewModel.author = "Толстой"
        viewModel.coverURLString = "не адрес"
        #expect(!viewModel.isCoverURLValid)
        #expect(!viewModel.canSave)
    }

    @Test func savesTrimmedBook() throws {
        let repository = InMemoryBookRepository()
        let viewModel = AddBookViewModel(repository: repository)
        viewModel.title = "  Война и мир "
        viewModel.author = "Толстой"
        viewModel.coverURLString = "https://example.com/cover.jpg"
        viewModel.status = .reading

        #expect(viewModel.save())
        let book = try #require(repository.books.first)
        #expect(book.title == "Война и мир")
        #expect(book.coverURL == URL(string: "https://example.com/cover.jpg"))
        #expect(book.status == .reading)
    }
}
