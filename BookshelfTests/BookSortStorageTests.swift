import Foundation
import Testing
@testable import Bookshelf

/// Выбор сортировки сохраняется между запусками. Каждый тест — в своём наборе UserDefaults.
@MainActor
struct BookSortStorageTests {
    @Test func nothingSavedGivesDefault() {
        let storage = BookSortStorage(defaults: makeIsolatedDefaults())
        #expect(storage.load() == .default)
    }

    nonisolated static let allSorts: [BookSort] = BookSortKey.allCases.flatMap { key in
        BookSortOrder.allCases.map { BookSort(key: key, order: $0) }
    }

    /// «Перезапуск»: сохраняет один экземпляр, читает другой с теми же UserDefaults.
    @Test(arguments: allSorts)
    func savedSortIsLoadedAfterRelaunch(sort: BookSort) {
        let defaults = makeIsolatedDefaults()
        BookSortStorage(defaults: defaults).save(sort)

        #expect(BookSortStorage(defaults: defaults).load() == sort)
    }

    @Test func laterSaveReplacesEarlier() {
        let defaults = makeIsolatedDefaults()
        let storage = BookSortStorage(defaults: defaults)
        storage.save(BookSort(key: .title, order: .ascending))
        storage.save(BookSort(key: .progress, order: .descending))

        #expect(BookSortStorage(defaults: defaults).load() == BookSort(key: .progress, order: .descending))
    }

    /// Значения из старой или чужой версии приложения: если хоть одно не распознано — значение по умолчанию.
    @Test(arguments: [
        ("rating", "ascending"),
        ("title", "sideways"),
        ("title", nil),
        (nil, "ascending"),
        ("", "")
    ] as [(String?, String?)])
    func unknownStoredValuesFallBackToDefault(key: String?, order: String?) {
        let defaults = makeIsolatedDefaults()
        defaults.set(key, forKey: BookSortStorage.keyDefaultsKey)
        defaults.set(order, forKey: BookSortStorage.orderDefaultsKey)

        #expect(BookSortStorage(defaults: defaults).load() == .default)
    }
}
