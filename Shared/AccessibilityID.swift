import Foundation

/// Идентификаторы элементов для UI-тестов. Файл входит и в приложение, и в `BookshelfUITests`
/// (папка `Shared/` подключена к обоим таргетам), поэтому строки нигде не дублируются.
nonisolated enum AccessibilityID {
    enum Shelf {
        static let searchButton = "shelf.searchButton"
        static let filterAll = "shelf.filter.all"

        /// Строка книги: ключ Open Library, у книг, добавленных вручную, — название.
        static func bookRow(_ key: String) -> String { "shelf.bookRow.\(key)" }

        /// Чип фильтра по статусу; `statusRawValue` — `ReadingStatus.rawValue`.
        static func filterChip(_ statusRawValue: String) -> String { "shelf.filter.\(statusRawValue)" }
    }

    enum Search {
        /// Кнопка «На полку» у результата поиска; `resultID` — `BookSearchResult.id`.
        static func addButton(_ resultID: String) -> String { "search.addButton.\(resultID)" }
    }

    #if DEBUG
    enum LaunchArgument {
        /// Запуск для UI-тестов: пустое хранилище в памяти и поиск без сети (`UITestSupport`).
        static let uiTesting = "-uiTesting"
    }

    /// Данные мок-сервиса поиска, которые нужны и приложению, и UI-тестам.
    enum UITestFixture {
        static let duneID = "/works/uitest-dune"
        static let duneMessiahID = "/works/uitest-dune-messiah"
    }
    #endif
}
