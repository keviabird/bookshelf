import Foundation

/// По какому полю сортируется полка.
nonisolated enum BookSortKey: String, CaseIterable, Identifiable, Sendable {
    case dateAdded
    case title
    case author
    case progress

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dateAdded: "Дата добавления"
        case .title: "Название"
        case .author: "Автор"
        case .progress: "Прогресс"
        }
    }
}

nonisolated enum BookSortOrder: String, CaseIterable, Identifiable, Sendable {
    case ascending
    case descending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ascending: "По возрастанию"
        case .descending: "По убыванию"
        }
    }

    var systemImage: String {
        switch self {
        case .ascending: "arrow.up"
        case .descending: "arrow.down"
        }
    }

    var toggled: BookSortOrder {
        self == .ascending ? .descending : .ascending
    }
}

/// Выбранная сортировка полки. Правила:
/// - названия и авторы сравниваются через `localizedStandardCompare` (регистр, «Ё», числа, разные алфавиты);
/// - при сортировке по автору книги без автора всегда в конце, независимо от направления;
/// - при равных значениях — название по алфавиту, тоже независимо от направления.
nonisolated struct BookSort: Equatable, Hashable, Sendable {
    var key: BookSortKey
    var order: BookSortOrder

    static let `default` = BookSort(key: .dateAdded, order: .descending)
}

extension BookSort {
    @MainActor
    func sorted(_ books: [Book]) -> [Book] {
        books.sorted(by: areInIncreasingOrder)
    }

    @MainActor
    private func areInIncreasingOrder(_ lhs: Book, _ rhs: Book) -> Bool {
        if key == .author {
            let lhsHasAuthor = !Self.author(of: lhs).isEmpty
            let rhsHasAuthor = !Self.author(of: rhs).isEmpty
            if lhsHasAuthor != rhsHasAuthor { return lhsHasAuthor }
        }

        switch primaryComparison(lhs, rhs) {
        case .orderedAscending: return order == .ascending
        case .orderedDescending: return order == .descending
        case .orderedSame: return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    @MainActor
    private func primaryComparison(_ lhs: Book, _ rhs: Book) -> ComparisonResult {
        switch key {
        case .dateAdded: Self.compare(lhs.dateAdded, rhs.dateAdded)
        case .title: lhs.title.localizedStandardCompare(rhs.title)
        case .author: Self.author(of: lhs).localizedStandardCompare(Self.author(of: rhs))
        case .progress: Self.compare(Self.progress(of: lhs), Self.progress(of: rhs))
        }
    }

    @MainActor
    private static func author(of book: Book) -> String {
        book.author.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Прочитанная книга — 100%, даже если число страниц неизвестно и `Book.progress` равен 0.
    @MainActor
    private static func progress(of book: Book) -> Double {
        book.status == .finished ? 1 : book.progress
    }

    private static func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        lhs < rhs ? .orderedAscending : (lhs > rhs ? .orderedDescending : .orderedSame)
    }
}
