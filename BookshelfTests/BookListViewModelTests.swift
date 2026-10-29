import Foundation
import Testing
@testable import Bookshelf

@MainActor
struct BookListViewModelTests {
    @Test func failedLoadShowsError() {
        let repository = InMemoryBookRepository()
        repository.failFetch = true
        let viewModel = BookListViewModel(repository: repository)

        viewModel.loadBooks()

        #expect(viewModel.errorMessage == "Не удалось загрузить книги.")
        #expect(viewModel.books.isEmpty)
    }

    @Test func failedReloadKeepsPreviousBooks() {
        let repository = InMemoryBookRepository()
        repository.books = [Book(title: "Война и мир", author: "Толстой")]
        let viewModel = BookListViewModel(repository: repository)
        viewModel.loadBooks()

        repository.failFetch = true
        viewModel.loadBooks()

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.books.map(\.title) == ["Война и мир"])
    }

    @Test func successfulRetryClearsError() {
        let repository = InMemoryBookRepository()
        repository.failFetch = true
        let viewModel = BookListViewModel(repository: repository)
        viewModel.loadBooks()

        repository.failFetch = false
        repository.books = [Book(title: "Война и мир", author: "Толстой")]
        viewModel.loadBooks()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.books.count == 1)
    }
}
