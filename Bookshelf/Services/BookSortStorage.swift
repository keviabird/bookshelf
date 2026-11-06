import Foundation

/// Хранит выбранную сортировку между запусками в UserDefaults (ключ и направление — строками).
struct BookSortStorage {
    static let keyDefaultsKey = "bookSort.key"
    static let orderDefaultsKey = "bookSort.order"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Если сохранённое значение пропало или не распознано (например, от другой версии) — сортировка по умолчанию.
    func load() -> BookSort {
        guard
            let key = defaults.string(forKey: Self.keyDefaultsKey).flatMap(BookSortKey.init(rawValue:)),
            let order = defaults.string(forKey: Self.orderDefaultsKey).flatMap(BookSortOrder.init(rawValue:))
        else { return .default }
        return BookSort(key: key, order: order)
    }

    func save(_ sort: BookSort) {
        defaults.set(sort.key.rawValue, forKey: Self.keyDefaultsKey)
        defaults.set(sort.order.rawValue, forKey: Self.orderDefaultsKey)
    }
}
