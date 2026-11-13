import Foundation
import Testing
@testable import Bookshelf

/// Модель: прогресс по страницам и правила статуса.
@MainActor
struct BookProgressTests {
    // MARK: - progress

    @Test func progressFollowsPages() {
        let book = Book(title: "Мы", author: "", status: .reading, pageCount: 200, currentPage: 50)
        #expect(book.progress == 0.25)
    }

    @Test func progressIsZeroWithoutPageCount() {
        let book = Book(title: "Мы", author: "", status: .reading, currentPage: 50)
        #expect(!book.hasKnownPages)
        #expect(book.progress == 0)
    }

    @Test func progressIsZeroWithoutCurrentPage() {
        let book = Book(title: "Мы", author: "", status: .reading, pageCount: 200)
        #expect(book.progress == 0)
    }

    @Test func negativePageCountBecomesUnknown() {
        #expect(Book(title: "Мы", author: "", pageCount: -10).pageCount == 0)
    }

    // MARK: - setCurrentPage

    @Test(arguments: [(-5, 0), (120, 120), (999, 200)])
    func currentPageIsClamped(input: Int, expected: Int) {
        let book = Book(title: "Мы", author: "", status: .reading, pageCount: 200)
        book.setCurrentPage(input)
        #expect(book.currentPage == expected)
    }

    @Test func lastPageFinishesBook() {
        let book = Book(title: "Мы", author: "", status: .reading, pageCount: 200)
        book.setCurrentPage(200)
        #expect(book.status == .finished)
        #expect(book.progress == 1)
    }

    @Test func pageOnWantToReadStartsReading() {
        let book = Book(title: "Мы", author: "", status: .wantToRead, pageCount: 200)
        book.setCurrentPage(10)
        #expect(book.status == .reading)
    }

    @Test func zeroPageKeepsWantToRead() {
        let book = Book(title: "Мы", author: "", status: .wantToRead, pageCount: 200)
        book.setCurrentPage(0)
        #expect(book.status == .wantToRead)
    }

    @Test func movingBackFromLastPageResumesReading() {
        let book = Book(title: "Мы", author: "", status: .finished, pageCount: 200)
        book.setCurrentPage(150)
        #expect(book.status == .reading)
        #expect(book.currentPage == 150)
    }

    // MARK: - setStatus

    @Test func finishedSetsLastPage() {
        let book = Book(title: "Мы", author: "", status: .reading, pageCount: 200, currentPage: 50)
        book.setStatus(.finished)
        #expect(book.currentPage == 200)
        #expect(book.progress == 1)
    }

    @Test func finishedWithoutPagesLeavesPageAlone() {
        let book = Book(title: "Мы", author: "", status: .reading)
        book.setStatus(.finished)
        #expect(book.status == .finished)
        #expect(book.currentPage == nil)
    }

    @Test func wantToReadClearsPage() {
        let book = Book(title: "Мы", author: "", status: .reading, pageCount: 200, currentPage: 50)
        book.setStatus(.wantToRead)
        #expect(book.status == .wantToRead)
        #expect(book.currentPage == nil)
        #expect(book.progress == 0)
    }

    @Test func readingKeepsPage() {
        let book = Book(title: "Мы", author: "", status: .finished, pageCount: 200)
        book.setStatus(.reading)
        #expect(book.status == .reading)
        #expect(book.currentPage == 200)
    }

    // MARK: - init

    @Test func initIgnoresPageForWantToRead() {
        let book = Book(title: "Мы", author: "", status: .wantToRead, pageCount: 200, currentPage: 30)
        #expect(book.status == .wantToRead)
        #expect(book.currentPage == nil)
    }

    // MARK: - Форматирование

    @Test(arguments: [
        (0.0, "0%"),
        (0.02, "2%"),
        (0.146, "15%"),
        (0.75, "75%"),
        (1.0, "100%"),
        (1.5, "100%"),
        (Double.nan, "0%")
    ])
    func percentText(progress: Double, expected: String) {
        #expect(ReadingFormat.percent(progress) == expected)
    }

    @Test func pagesText() {
        #expect(ReadingFormat.pages(current: 210, total: 498) == "Стр. 210 из 498")
    }
}
