import Foundation
import SwiftData
import Testing
@testable import Bookshelf

/// Проверяет настоящий репозиторий на базе в памяти.
/// Ветку с rollback так не проверить: заставить `save()` упасть на базе в памяти не удаётся.
@MainActor
struct SwiftDataBookRepositoryTests {
    private func makeRepository() throws -> (SwiftDataBookRepository, ModelContext) {
        let container = try ModelContainer(
            for: Book.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        return (SwiftDataBookRepository(context: context), context)
    }

    @Test func addSavesBook() throws {
        let (repository, context) = try makeRepository()

        try repository.add(Book(title: "Война и мир", author: "Толстой"))

        #expect(!context.hasChanges)
        #expect(try repository.fetchBooks().map(\.title) == ["Война и мир"])
    }

    @Test func fetchSortsNewestFirst() throws {
        let (repository, _) = try makeRepository()
        try repository.add(Book(title: "Старая", author: "", dateAdded: .distantPast))
        try repository.add(Book(title: "Новая", author: "", dateAdded: .now))

        #expect(try repository.fetchBooks().map(\.title) == ["Новая", "Старая"])
    }

    @Test func deleteRemovesBook() throws {
        let (repository, context) = try makeRepository()
        let book = Book(title: "Война и мир", author: "Толстой")
        try repository.add(book)

        try repository.delete(book)

        #expect(!context.hasChanges)
        #expect(try repository.fetchBooks().isEmpty)
    }
}
