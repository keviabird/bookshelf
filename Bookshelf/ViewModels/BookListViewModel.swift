import Foundation
import Observation

@Observable
@MainActor
final class BookListViewModel {
    private(set) var books: [Book] = []
    private(set) var errorMessage: String?
    var isAddingBook = false
    /// Выбранные статусы фильтра. Пустое множество — «Все».
    private(set) var selectedStatuses: Set<ReadingStatus> = []
    /// Сортировка списка. Меню меняет `sort.key` и `sort.order` по отдельности — сохраняется каждое изменение.
    var sort: BookSort {
        didSet {
            if sort != oldValue { sortStorage.save(sort) }
        }
    }

    private let repository: BookRepository
    private let searchService: BookSearchService
    private let sortStorage: BookSortStorage

    init(
        repository: BookRepository,
        searchService: BookSearchService = OpenLibrarySearchService(),
        sortStorage: BookSortStorage = BookSortStorage()
    ) {
        self.repository = repository
        self.searchService = searchService
        self.sortStorage = sortStorage
        self.sort = sortStorage.load()
    }

    // MARK: - Фильтр по статусу и сортировка

    var isAllSelected: Bool { selectedStatuses.isEmpty }

    /// Книги на экране: сначала фильтр по статусу, затем сортировка.
    /// `books` остаётся в порядке репозитория (новые сверху).
    var filteredBooks: [Book] {
        let visible = isAllSelected ? books : books.filter { selectedStatuses.contains($0.status) }
        return sort.sorted(visible)
    }

    var totalCount: Int { books.count }

    func count(for status: ReadingStatus) -> Int {
        books.filter { $0.status == status }.count
    }

    func isSelected(_ status: ReadingStatus) -> Bool {
        selectedStatuses.contains(status)
    }

    /// Добавляет статус в фильтр или убирает его.
    /// Если выбраны все статусы, это то же самое, что «Все», — фильтр сбрасывается.
    func toggle(_ status: ReadingStatus) {
        if selectedStatuses.contains(status) {
            selectedStatuses.remove(status)
        } else {
            selectedStatuses.insert(status)
        }
        if selectedStatuses.count == ReadingStatus.allCases.count {
            selectedStatuses = []
        }
    }

    func selectAll() {
        selectedStatuses = []
    }

    /// «книга / книги / книг» для общего числа книг.
    var summaryNoun: String {
        RussianPlural.form(for: totalCount, one: "книга", few: "книги", many: "книг")
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

    /// Поиск добавляет книги в тот же репозиторий; после добавления список перезагружается.
    func makeSearchViewModel() -> BookSearchViewModel {
        let search = BookSearchViewModel(service: searchService, repository: repository, onAdd: { [weak self] in
            self?.loadBooks()
        })
        #if DEBUG
        // Для скриншотов: запрос из аргумента запуска `-openSearch`.
        if let query = SampleData.searchQuery { search.query = query }
        #endif
        return search
    }

    /// Карточка книги использует тот же репозиторий; после изменений список перезагружается.
    func makeDetailViewModel(for book: Book) -> BookDetailViewModel {
        BookDetailViewModel(book: book, repository: repository) { [weak self] in
            self?.loadBooks()
        }
    }
}
