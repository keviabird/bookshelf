import Foundation

/// Выбор формы слова после числа по правилам русского языка.
/// Чистая функция без состояния, поэтому не привязана к главному актору.
nonisolated enum RussianPlural {
    /// - Parameters:
    ///   - one: форма для 1, 21, 101… («книга»)
    ///   - few: форма для 2–4, 22–24… («книги»)
    ///   - many: форма для 0, 5–20, 11–14, 25… («книг»)
    static func form(for count: Int, one: String, few: String, many: String) -> String {
        let n = abs(count)
        let lastTwo = n % 100
        let last = n % 10
        if (11...14).contains(lastTwo) { return many }
        switch last {
        case 1: return one
        case 2...4: return few
        default: return many
        }
    }
}
