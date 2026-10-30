import Testing
@testable import Bookshelf

struct RussianPluralTests {
    private func books(_ count: Int) -> String {
        RussianPlural.form(for: count, one: "книга", few: "книги", many: "книг")
    }

    @Test(arguments: [1, 21, 101, 1001])
    func one(count: Int) {
        #expect(books(count) == "книга")
    }

    @Test(arguments: [2, 3, 4, 22, 104])
    func few(count: Int) {
        #expect(books(count) == "книги")
    }

    @Test(arguments: [0, 5, 11, 12, 14, 19, 25, 111, 112])
    func many(count: Int) {
        #expect(books(count) == "книг")
    }
}
