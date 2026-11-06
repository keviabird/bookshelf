import Foundation
import Testing
@testable import Bookshelf

/// Сортировка в списке: настоящий SwiftData-репозиторий (база в памяти) и отдельный набор UserDefaults.
@MainActor
struct BookListSortingTests {
    /// По дате (новые сверху): Мастер(0) · Мы(1) · Идиот(2) · Пикник(3) · Война и мир(4).
    private func makeShelf(defaults: UserDefaults = makeIsolatedDefaults()) throws -> (TestStore, BookListViewModel) {
        let store = try TestStore()
        let books = [
            Book(title: "Война и мир", author: "Лев Толстой", status: .wantToRead, dateAdded: daysAgo(4)),
            Book(title: "Пикник", author: "Стругацкие", status: .reading, pageCount: 100, currentPage: 20, dateAdded: daysAgo(3)),
            Book(title: "Мы", author: "", status: .finished, dateAdded: daysAgo(1)),
            Book(title: "Мастер", author: "Михаил Булгаков", status: .reading, pageCount: 100, currentPage: 70, dateAdded: daysAgo(0)),
            Book(title: "Идиот", author: "Фёдор Достоевский", status: .wantToRead, dateAdded: daysAgo(2)),
        ]
        for book in books { try store.repository.add(book) }
        let viewModel = makeViewModel(store: store, defaults: defaults)
        return (store, viewModel)
    }

    private func makeViewModel(store: TestStore, defaults: UserDefaults) -> BookListViewModel {
        let viewModel = BookListViewModel(
            repository: store.repository,
            searchService: FakeBookSearchService(),
            sortStorage: BookSortStorage(defaults: defaults)
        )
        viewModel.loadBooks()
        return viewModel
    }

    @Test func defaultSortIsNewestFirst() throws {
        let (_, viewModel) = try makeShelf()

        #expect(viewModel.sort == .default)
        #expect(viewModel.filteredBooks.map(\.title) == ["Мастер", "Мы", "Идиот", "Пикник", "Война и мир"])
    }

    @Test(arguments: [
        (BookSort(key: .title, order: .ascending), ["Война и мир", "Идиот", "Мастер", "Мы", "Пикник"]),
        (BookSort(key: .title, order: .descending), ["Пикник", "Мы", "Мастер", "Идиот", "Война и мир"]),
        (BookSort(key: .author, order: .ascending), ["Война и мир", "Мастер", "Пикник", "Идиот", "Мы"]),
        (BookSort(key: .author, order: .descending), ["Идиот", "Пикник", "Мастер", "Война и мир", "Мы"]),
        (BookSort(key: .progress, order: .descending), ["Мы", "Мастер", "Пикник", "Война и мир", "Идиот"]),
        (BookSort(key: .dateAdded, order: .ascending), ["Война и мир", "Пикник", "Идиот", "Мы", "Мастер"]),
    ])
    func changingSortReordersList(sort: BookSort, expected: [String]) throws {
        let (_, viewModel) = try makeShelf()

        viewModel.sort = sort

        #expect(viewModel.filteredBooks.map(\.title) == expected)
    }

    /// Сначала фильтр по статусу, потом сортировка: в списке только нужные статусы и в нужном порядке.
    nonisolated static let filterCases: [(Set<ReadingStatus>, [String])] = [
        ([.reading], ["Мастер", "Пикник"]),
        ([.wantToRead], ["Война и мир", "Идиот"]),
        ([.reading, .finished], ["Мастер", "Мы", "Пикник"]),
    ]

    @Test(arguments: filterCases)
    func sortIsAppliedAfterFilter(statuses: Set<ReadingStatus>, expected: [String]) throws {
        let (_, viewModel) = try makeShelf()
        viewModel.sort = BookSort(key: .title, order: .ascending)

        statuses.forEach { viewModel.toggle($0) }

        #expect(viewModel.filteredBooks.map(\.title) == expected)
    }

    @Test func changingFilterKeepsSort() throws {
        let (_, viewModel) = try makeShelf()
        viewModel.sort = BookSort(key: .progress, order: .descending)
        viewModel.toggle(.reading)
        #expect(viewModel.filteredBooks.map(\.title) == ["Мастер", "Пикник"])

        viewModel.selectAll()

        #expect(viewModel.sort == BookSort(key: .progress, order: .descending))
        #expect(viewModel.filteredBooks.first?.title == "Мы")
    }

    @Test func countsDoNotDependOnSort() throws {
        let (_, viewModel) = try makeShelf()

        viewModel.sort = BookSort(key: .author, order: .ascending)

        #expect(viewModel.totalCount == 5)
        #expect(viewModel.count(for: .reading) == 2)
        #expect(viewModel.books.map(\.title) == ["Мастер", "Мы", "Идиот", "Пикник", "Война и мир"])
    }

    // MARK: - Сохранение между запусками

    @Test func chosenSortSurvivesRelaunch() throws {
        let defaults = makeIsolatedDefaults()
        let (store, viewModel) = try makeShelf(defaults: defaults)
        viewModel.sort = BookSort(key: .title, order: .descending)

        let relaunched = makeViewModel(store: store, defaults: defaults)

        #expect(relaunched.sort == BookSort(key: .title, order: .descending))
        #expect(relaunched.filteredBooks.map(\.title) == ["Пикник", "Мы", "Мастер", "Идиот", "Война и мир"])
    }

    /// Меню меняет ключ и направление по отдельности (через биндинги `$viewModel.sort.key`):
    /// сохраняется каждое изменение, а не только присваивание целиком.
    @Test func changingOnlyKeyOrOrderIsSaved() throws {
        let defaults = makeIsolatedDefaults()
        let (store, viewModel) = try makeShelf(defaults: defaults)

        viewModel.sort.key = .author
        #expect(makeViewModel(store: store, defaults: defaults).sort == BookSort(key: .author, order: .descending))

        viewModel.sort.order = .ascending
        #expect(makeViewModel(store: store, defaults: defaults).sort == BookSort(key: .author, order: .ascending))
    }

    // MARK: - Изменения полки

    @Test func bookAddedFromSearchFollowsSort() throws {
        let (_, viewModel) = try makeShelf()
        viewModel.sort = BookSort(key: .title, order: .ascending)

        viewModel.makeSearchViewModel().add(searchResult("/works/OL1W", title: "Белая гвардия"))

        #expect(viewModel.filteredBooks.map(\.title) == ["Белая гвардия", "Война и мир", "Идиот", "Мастер", "Мы", "Пикник"])
    }

    /// Книга из формы «+» (без автора, 0%) встаёт на место по текущей сортировке.
    /// Как на экране: форма сохраняет, затем список перезагружается.
    @Test(arguments: [
        (BookSort(key: .title, order: .ascending), ["Белая гвардия", "Война и мир", "Идиот", "Мастер", "Мы", "Пикник"]),
        (BookSort(key: .author, order: .ascending), ["Война и мир", "Мастер", "Пикник", "Идиот", "Белая гвардия", "Мы"]),
        (BookSort(key: .author, order: .descending), ["Идиот", "Пикник", "Мастер", "Война и мир", "Белая гвардия", "Мы"]),
        (BookSort(key: .progress, order: .descending), ["Мы", "Мастер", "Пикник", "Белая гвардия", "Война и мир", "Идиот"]),
        (BookSort(key: .dateAdded, order: .descending), ["Белая гвардия", "Мастер", "Мы", "Идиот", "Пикник", "Война и мир"]),
        (BookSort(key: .dateAdded, order: .ascending), ["Война и мир", "Пикник", "Идиот", "Мы", "Мастер", "Белая гвардия"]),
    ])
    func bookAddedFromFormFollowsSort(sort: BookSort, expected: [String]) throws {
        let (_, viewModel) = try makeShelf()
        viewModel.sort = sort
        let form = viewModel.makeAddBookViewModel()
        form.title = "Белая гвардия"

        #expect(form.save())
        viewModel.loadBooks()

        #expect(viewModel.filteredBooks.map(\.title) == expected)
    }

    @Test func progressChangeInDetailResortsList() throws {
        let (_, viewModel) = try makeShelf()
        viewModel.sort = BookSort(key: .progress, order: .descending)
        viewModel.toggle(.reading)
        let picnic = try #require(viewModel.books.first { $0.title == "Пикник" })

        let detail = viewModel.makeDetailViewModel(for: picnic)
        detail.startUpdatingProgress()
        detail.draftPage = 90
        #expect(detail.saveProgress())

        #expect(viewModel.filteredBooks.map(\.title) == ["Пикник", "Мастер"])
    }
}
