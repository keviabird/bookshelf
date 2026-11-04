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

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
    }

    // MARK: - Фильтр по статусу

    var isAllSelected: Bool { selectedStatuses.isEmpty }

    var filteredBooks: [Book] {
        guard !isAllSelected else { return books }
        return books.filter { selectedStatuses.contains($0.status) }
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
}
