import Foundation
import Testing
@testable import Bookshelf

/// Фильтр по статусу и порядок списка вместе с настоящим SwiftData-репозиторием (база в памяти):
/// сортирует репозиторий, фильтрует ViewModel.
@MainActor
struct BookListFilteringTests {
    /// Полка, добавленная вперемешку. По дате (новые сверху):
    /// Мастер(0) · Мы(1) · Идиот(2) · Пикник(3) · Отцы и дети(4) · Война и мир(5).
    private func makeShelf() throws -> (TestStore, BookListViewModel) {
        let store = try TestStore()
        let books = [
            Book(title: "Война и мир", author: "Лев Толстой", status: .wantToRead, dateAdded: daysAgo(5)),
            Book(title: "Пикник", author: "Стругацкие", status: .reading, dateAdded: daysAgo(3)),
            Book(title: "Мы", author: "Евгений Замятин", status: .finished, dateAdded: daysAgo(1)),
            Book(title: "Отцы и дети", author: "Иван Тургенев", status: .finished, dateAdded: daysAgo(4)),
            Book(title: "Мастер", author: "Михаил Булгаков", status: .reading, dateAdded: daysAgo(0)),
            Book(title: "Идиот", author: "Фёдор Достоевский", status: .wantToRead, dateAdded: daysAgo(2))
        ]
        for book in books { try store.repository.add(book) }
        let viewModel = BookListViewModel(
            repository: store.repository,
            searchService: FakeBookSearchService(),
            sortStorage: BookSortStorage(defaults: makeIsolatedDefaults())
        )
        viewModel.loadBooks()
        return (store, viewModel)
    }

    nonisolated private static let newestFirst = ["Мастер", "Мы", "Идиот", "Пикник", "Отцы и дети", "Война и мир"]

    /// Выбранные статусы → ожидаемые книги в ожидаемом порядке.
    /// Явный тип: без него компилятор не успевает вывести тип литерала.
    nonisolated static let filterCases: [(Set<ReadingStatus>, [String])] = [
        ([], newestFirst),
        ([.wantToRead], ["Идиот", "Война и мир"]),
        ([.reading], ["Мастер", "Пикник"]),
        ([.finished], ["Мы", "Отцы и дети"]),
        ([.wantToRead, .reading], ["Мастер", "Идиот", "Пикник", "Война и мир"]),
        ([.reading, .finished], ["Мастер", "Мы", "Пикник", "Отцы и дети"]),
        ([.wantToRead, .finished], ["Мы", "Идиот", "Отцы и дети", "Война и мир"]),
        // Все три статуса — то же самое, что «Все».
        (Set(ReadingStatus.allCases), newestFirst)
    ]

    @Test(arguments: filterCases)
    func filterKeepsNewestFirstOrder(statuses: Set<ReadingStatus>, expected: [String]) throws {
        let (_, viewModel) = try makeShelf()

        statuses.forEach { viewModel.toggle($0) }

        #expect(viewModel.filteredBooks.map(\.title) == expected)
        #expect(viewModel.isAllSelected == (statuses.isEmpty || statuses.count == ReadingStatus.allCases.count))
    }

    @Test(arguments: ReadingStatus.allCases)
    func chipCountMatchesFilteredBooks(status: ReadingStatus) throws {
        let (_, viewModel) = try makeShelf()

        viewModel.toggle(status)

        #expect(viewModel.count(for: status) == viewModel.filteredBooks.count)
        #expect(viewModel.count(for: status) == 2)
        #expect(viewModel.totalCount == 6)
    }

    @Test func statusChangeMovesBookToAnotherFilter() throws {
        let (store, viewModel) = try makeShelf()
        let bulgakov = try #require(viewModel.books.first { $0.title == "Мастер" })
        viewModel.toggle(.reading)

        try store.repository.update(bulgakov) { $0.setStatus(.finished) }
        viewModel.loadBooks()

        #expect(viewModel.filteredBooks.map(\.title) == ["Пикник"])
        viewModel.selectAll()
        viewModel.toggle(.finished)
        #expect(viewModel.filteredBooks.map(\.title) == ["Мастер", "Мы", "Отцы и дети"])
    }

    @Test func filterWithoutMatchesIsEmptyButShelfIsNot() throws {
        let store = try TestStore()
        try store.repository.add(Book(title: "Война и мир", author: "Толстой", status: .wantToRead))
        let viewModel = BookListViewModel(
            repository: store.repository,
            searchService: FakeBookSearchService(),
            sortStorage: BookSortStorage(defaults: makeIsolatedDefaults())
        )
        viewModel.loadBooks()

        viewModel.toggle(.finished)

        #expect(viewModel.filteredBooks.isEmpty)
        #expect(viewModel.totalCount == 1)
    }

    @Test func bookAddedFromSearchComesFirstInWantToRead() throws {
        let (_, viewModel) = try makeShelf()
        viewModel.toggle(.wantToRead)

        viewModel.makeSearchViewModel().add(searchResult("/works/OL1W", title: "Белая гвардия"))

        #expect(viewModel.filteredBooks.map(\.title) == ["Белая гвардия", "Идиот", "Война и мир"])
    }
}
