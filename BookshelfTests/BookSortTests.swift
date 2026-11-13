import Foundation
import Testing
@testable import Bookshelf

/// Правила сортировки полки: `BookSort` — отдельный тип, View и SwiftData не нужны.
@MainActor
struct BookSortTests {
    private func sorted(_ books: [Book], by key: BookSortKey, _ order: BookSortOrder) -> [String] {
        BookSort(key: key, order: order).sorted(books).map(\.title)
    }

    // MARK: - Значение по умолчанию

    @Test func defaultIsNewestFirst() {
        #expect(BookSort.default == BookSort(key: .dateAdded, order: .descending))
    }

    @Test(arguments: [
        (BookSortKey.dateAdded, "Дата добавления"),
        (.title, "Название"),
        (.author, "Автор"),
        (.progress, "Прогресс")
    ])
    func keyTitles(key: BookSortKey, title: String) {
        #expect(key.title == title)
    }

    @Test func orderToggles() {
        #expect(BookSortOrder.ascending.toggled == .descending)
        #expect(BookSortOrder.descending.toggled == .ascending)
    }

    // MARK: - Дата добавления

    @Test(arguments: [
        (BookSortOrder.descending, ["Новая", "Средняя", "Старая"]),
        (.ascending, ["Старая", "Средняя", "Новая"])
    ])
    func sortsByDateAdded(order: BookSortOrder, expected: [String]) {
        let books = [
            Book(title: "Средняя", author: "А", dateAdded: daysAgo(5)),
            Book(title: "Старая", author: "А", dateAdded: daysAgo(30)),
            Book(title: "Новая", author: "А", dateAdded: daysAgo(0))
        ]
        #expect(sorted(books, by: .dateAdded, order) == expected)
    }

    // MARK: - Название

    /// Регистр не важен, «Ё» стоит рядом с «Е», а не перед «А», как при сравнении кодов символов.
    @Test(arguments: BookSortOrder.allCases)
    func sortsByTitleIgnoringCase(order: BookSortOrder) {
        let books = ["Яма", "бесы", "Ёлка", "Анна Каренина", "Евгений Онегин"]
            .map { Book(title: $0, author: "Автор") }
        let ascending = ["Анна Каренина", "бесы", "Евгений Онегин", "Ёлка", "Яма"]

        #expect(sorted(books, by: .title, order) == (order == .ascending ? ascending : ascending.reversed()))
    }

    @Test func numbersInTitleCompareAsNumbers() {
        let books = ["Том 10", "Том 2", "Том 1"].map { Book(title: $0, author: "Автор") }
        #expect(sorted(books, by: .title, .ascending) == ["Том 1", "Том 2", "Том 10"])
    }

    /// Кириллица и латиница вперемешку: порядок как у `localizedStandardCompare`,
    /// буквы одного алфавита идут подряд и по алфавиту, регистр не разрывает группу.
    @Test(arguments: BookSortOrder.allCases)
    func mixedScriptsFollowLocalizedStandardCompare(order: BookSortOrder) {
        let titles = ["Мастер", "dune", "Анна", "Zorro", "бесы", "Alice"]
        let books = titles.map { Book(title: $0, author: "Автор") }
        let ascending = titles.sorted { $0.localizedStandardCompare($1) == .orderedAscending }

        let result = sorted(books, by: .title, order)

        #expect(result == (order == .ascending ? ascending : ascending.reversed()))
        let scripts = result.map(Self.isCyrillic)
        #expect(scripts.indices.dropFirst().filter { scripts[$0] != scripts[$0 - 1] }.count == 1)
        #expect(result.filter(Self.isCyrillic).map { $0.lowercased() }
            == (order == .ascending ? ["анна", "бесы", "мастер"] : ["мастер", "бесы", "анна"]))
        #expect(result.filter { !Self.isCyrillic($0) }.map { $0.lowercased() }
            == (order == .ascending ? ["alice", "dune", "zorro"] : ["zorro", "dune", "alice"]))
    }

    nonisolated private static func isCyrillic(_ text: String) -> Bool {
        text.unicodeScalars.first.map { (0x0400...0x04FF).contains($0.value) } ?? false
    }

    // MARK: - Автор

    @Test(arguments: BookSortOrder.allCases)
    func sortsByAuthorIgnoringCase(order: BookSortOrder) {
        let books = [
            Book(title: "Пикник", author: "Ёлкин"),
            Book(title: "Мы", author: "булгаков"),
            Book(title: "Идиот", author: "Елизаров"),
            Book(title: "Бесы", author: "Абрамов")
        ]
        let ascending = ["Бесы", "Мы", "Идиот", "Пикник"] // Абрамов, булгаков, Елизаров, Ёлкин

        #expect(sorted(books, by: .author, order) == (order == .ascending ? ascending : ascending.reversed()))
    }

    /// Пустой автор и автор из пробелов — «без автора»: всегда в конце, между собой по названию.
    @Test(arguments: [
        (BookSortOrder.ascending, ["Бесы", "Война и мир", "Азбука", "Яма"]),
        (.descending, ["Война и мир", "Бесы", "Азбука", "Яма"])
    ])
    func booksWithoutAuthorGoLast(order: BookSortOrder, expected: [String]) {
        let books = [
            Book(title: "Яма", author: ""),
            Book(title: "Война и мир", author: "Толстой"),
            Book(title: "Азбука", author: "   "),
            Book(title: "Бесы", author: "Достоевский")
        ]
        #expect(sorted(books, by: .author, order) == expected)
    }

    /// Правило «без автора — в конце» относится к сортировке по автору, остальные ключи его не трогают.
    @Test func bookWithoutAuthorIsNotMovedForOtherKeys() {
        let books = [
            Book(title: "Бесы", author: "Достоевский", dateAdded: daysAgo(1)),
            Book(title: "Азбука", author: "", dateAdded: daysAgo(0))
        ]
        #expect(sorted(books, by: .title, .ascending) == ["Азбука", "Бесы"])
        #expect(sorted(books, by: .dateAdded, .descending) == ["Азбука", "Бесы"])
    }

    // MARK: - Прогресс

    @Test(arguments: [
        (BookSortOrder.ascending, ["Не начата", "10%", "50%", "Прочитана"]),
        (.descending, ["Прочитана", "50%", "10%", "Не начата"])
    ])
    func sortsByProgress(order: BookSortOrder, expected: [String]) {
        let books = [
            Book(title: "50%", author: "А", status: .reading, pageCount: 100, currentPage: 50),
            Book(title: "Прочитана", author: "А", status: .finished, pageCount: 300),
            Book(title: "Не начата", author: "А", status: .wantToRead, pageCount: 200),
            Book(title: "10%", author: "А", status: .reading, pageCount: 100, currentPage: 10)
        ]
        #expect(sorted(books, by: .progress, order) == expected)
    }

    /// У прочитанной книги без числа страниц `progress == 0`, но для сортировки это 100%.
    /// Книга «Читаю» без страниц — 0%, как не начатая.
    @Test func finishedBookWithoutPagesCountsAsComplete() {
        let books = [
            Book(title: "Прочитана без страниц", author: "А", status: .finished),
            Book(title: "Читаю без страниц", author: "А", status: .reading),
            Book(title: "Половина", author: "А", status: .reading, pageCount: 100, currentPage: 50),
            Book(title: "Аа не начата", author: "А", status: .wantToRead)
        ]
        #expect(sorted(books, by: .progress, .descending)
            == ["Прочитана без страниц", "Половина", "Аа не начата", "Читаю без страниц"])
    }

    // MARK: - Равные значения

    nonisolated static let tieCases: [(BookSortKey, BookSortOrder)] = [
        (.dateAdded, .ascending), (.dateAdded, .descending),
        (.author, .ascending), (.author, .descending),
        (.progress, .ascending), (.progress, .descending)
    ]

    /// При равном основном ключе — название по алфавиту, в любом направлении.
    @Test(arguments: tieCases)
    func tiesAreOrderedByTitle(key: BookSortKey, order: BookSortOrder) {
        let date = daysAgo(3)
        let books = [
            Book(title: "Война", author: "Толстой", status: .reading, pageCount: 100, currentPage: 40, dateAdded: date),
            Book(title: "анна", author: "Толстой", status: .reading, pageCount: 200, currentPage: 80, dateAdded: date),
            Book(title: "Бесы", author: "Толстой", status: .reading, pageCount: 50, currentPage: 20, dateAdded: date)
        ]
        #expect(sorted(books, by: key, order) == ["анна", "Бесы", "Война"])
    }

    /// Книги с равным ключом идут по названию при любом исходном порядке (порядок из базы не гарантирован).
    @Test(arguments: tieCases)
    func tieOrderDoesNotDependOnInputOrder(key: BookSortKey, order: BookSortOrder) {
        let date = daysAgo(3)
        let books = [
            Book(title: "Бесы", author: "Толстой", status: .reading, pageCount: 100, currentPage: 50, dateAdded: date),
            Book(title: "Война", author: "Толстой", status: .reading, pageCount: 100, currentPage: 50, dateAdded: date),
            Book(title: "анна", author: "Толстой", status: .reading, pageCount: 100, currentPage: 50, dateAdded: date)
        ]
        let permutations = [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
        for indices in permutations {
            let input = indices.map { books[$0] }
            #expect(sorted(input, by: key, order) == ["анна", "Бесы", "Война"], "вход: \(input.map(\.title))")
        }
    }

    @Test func tieBreakDoesNotOverrideMainKey() {
        let books = [
            Book(title: "Аа", author: "Яковлев"),
            Book(title: "Яя", author: "Абрамов")
        ]
        #expect(sorted(books, by: .author, .ascending) == ["Яя", "Аа"])
    }
}
