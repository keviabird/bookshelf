#if DEBUG
import Foundation
import SwiftData

/// Зависимости для запуска с `-uiTesting`: пустое хранилище в памяти, поиск без сети
/// и отдельные UserDefaults для сортировки — тест не зависит от прошлых запусков.
/// Только DEBUG: в Release этого кода нет.
enum UITestSupport {
    private static let defaultsSuite = "com.gnr.Bookshelf.uitests"

    static func dependencies() -> AppDependencies {
        AppDependencies(
            container: makeContainer(),
            searchService: UITestBookSearchService(),
            sortStorage: makeSortStorage()
        )
    }

    private static func makeContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: Book.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("Could not create in-memory ModelContainer: \(error)")
        }
    }

    private static func makeSortStorage() -> BookSortStorage {
        // Без force unwrap: если набор не создался, хватит и стандартного (в UI-тесте сортировка не важна).
        let defaults = UserDefaults(suiteName: defaultsSuite) ?? .standard
        defaults.removePersistentDomain(forName: defaultsSuite)
        return BookSortStorage(defaults: defaults)
    }
}

/// Поиск для UI-тестов: фиксированные книги, отбор по вхождению запроса в название.
/// Обложек нет, чтобы и картинки не ходили в сеть.
nonisolated struct UITestBookSearchService: BookSearchService {
    static let books = [
        BookSearchResult(
            id: AccessibilityID.UITestFixture.duneID,
            title: "Dune",
            author: "Frank Herbert",
            coverURL: nil,
            firstPublishYear: 1965,
            pageCount: 412
        ),
        BookSearchResult(
            id: AccessibilityID.UITestFixture.duneMessiahID,
            title: "Dune Messiah",
            author: "Frank Herbert",
            coverURL: nil,
            firstPublishYear: 1969,
            pageCount: 256
        ),
    ]

    func search(_ query: String) async throws -> [BookSearchResult] {
        Self.books.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
}
#endif
