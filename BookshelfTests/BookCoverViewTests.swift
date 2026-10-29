import Foundation
import Testing
@testable import Bookshelf

@MainActor
struct BookCoverViewTests {
    @Test(arguments: ["Я", "Оно", "1984", "  Мы  "])
    func shortTitleGetsLargestFont(title: String) {
        #expect(BookCoverView.placeholderFontSize(for: title) == 18)
    }

    @Test(arguments: ["Война и мир", "Идиот!", "Мастер"])
    func mediumTitleGetsMediumFont(title: String) {
        #expect(BookCoverView.placeholderFontSize(for: title) == 12)
    }

    @Test func longTitleGetsSmallFont() {
        #expect(BookCoverView.placeholderFontSize(for: "Мастер и Маргарита") == 9)
    }

    @Test func fontShrinksAsTitleGrows() {
        let short = BookCoverView.placeholderFontSize(for: "Я")
        let medium = BookCoverView.placeholderFontSize(for: "Война и мир")
        let long = BookCoverView.placeholderFontSize(for: "Сто лет одиночества")
        #expect(short > medium)
        #expect(medium > long)
    }
}
