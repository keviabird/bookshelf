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

    // MARK: - Фильтр по статусу

    /// 2 «Читаю», 2 «Хочу прочитать», 1 «Прочитано».
    private func makeLoadedViewModel() -> BookListViewModel {
        let repository = InMemoryBookRepository()
        repository.books = [
            Book(title: "Мастер и Маргарита", author: "", status: .reading),
            Book(title: "Пикник на обочине", author: "", status: .reading),
            Book(title: "Война и мир", author: "", status: .wantToRead),
            Book(title: "Анна Каренина", author: "", status: .wantToRead),
            Book(title: "Мы", author: "", status: .finished),
        ]
        let viewModel = BookListViewModel(repository: repository)
        viewModel.loadBooks()
        return viewModel
    }





    @Test func togglingSelectedStatusRemovesIt() {
        let viewModel = makeLoadedViewModel()
        viewModel.toggle(.reading)
        viewModel.toggle(.finished)

        viewModel.toggle(.reading)

        #expect(viewModel.selectedStatuses == [.finished])
    }

    @Test func removingLastStatusReturnsToAll() {
        let viewModel = makeLoadedViewModel()
        viewModel.toggle(.reading)

        viewModel.toggle(.reading)

        #expect(viewModel.isAllSelected)
        #expect(viewModel.filteredBooks.count == 5)
    }

    @Test func selectingEveryStatusReturnsToAll() {
        let viewModel = makeLoadedViewModel()

        ReadingStatus.allCases.forEach { viewModel.toggle($0) }

        #expect(viewModel.isAllSelected)
        #expect(viewModel.selectedStatuses.isEmpty)
    }

    @Test func selectAllClearsFilter() {
        let viewModel = makeLoadedViewModel()
        viewModel.toggle(.reading)
        viewModel.toggle(.finished)

        viewModel.selectAll()

        #expect(viewModel.isAllSelected)
        #expect(viewModel.filteredBooks.count == 5)
    }

    @Test func filterKeepsWorkingAfterReload() {
        let viewModel = makeLoadedViewModel()
        viewModel.toggle(.finished)

        viewModel.loadBooks()

        #expect(viewModel.selectedStatuses == [.finished])
        #expect(viewModel.filteredBooks.count == 1)
    }

    @Test func summaryNounAgreesWithCount() {
        #expect(makeLoadedViewModel().summaryNoun == "книг")

        let repository = InMemoryBookRepository()
        repository.books = [Book(title: "Мы", author: "")]
        let single = BookListViewModel(repository: repository)
        single.loadBooks()
        #expect(single.summaryNoun == "книга")
    }

    @Test func bookAddedFromSearchAppearsInList() {
        let repository = InMemoryBookRepository()
        repository.books = [Book(title: "Война и мир", author: "Толстой")]
        let viewModel = BookListViewModel(repository: repository, searchService: FakeBookSearchService())
        viewModel.loadBooks()

        let search = viewModel.makeSearchViewModel()
        search.loadShelf()
        search.add(searchResult("/works/OL1W"))

        #expect(viewModel.totalCount == 2)
        #expect(viewModel.count(for: .wantToRead) == 2)
        #expect(viewModel.books.contains { $0.openLibraryKey == "/works/OL1W" })
    }
}
