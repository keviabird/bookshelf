import Foundation
import Testing
@testable import Bookshelf

@MainActor
struct BookProgressTests {
    @Test(arguments: [
        (-0.5, 0.0),
        (0.0, 0.0),
        (0.42, 0.42),
        (1.0, 1.0),
        (3.0, 1.0),
        (Double.nan, 0.0),
    ])
    func initClampsProgress(input: Double, expected: Double) {
        let book = Book(title: "Мы", author: "", progress: input)
        #expect(book.progress == expected)
    }

    @Test func progressDefaultsToZero() {
        #expect(Book(title: "Мы", author: "").progress == 0)
    }

    @Test(arguments: [
        (0.0, "0%"),
        (0.02, "2%"),
        (0.146, "15%"),
        (0.75, "75%"),
        (1.0, "100%"),
        (1.5, "100%"),
    ])
    func percentText(progress: Double, expected: String) {
        #expect(ReadingProgressBar.percentText(progress) == expected)
    }
}
