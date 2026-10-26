import Foundation
import SwiftData

/// Доступ к хранилищу книг. Протокол позволяет подменять реализацию в тестах и превью.
protocol BookRepository {
    func fetchBooks() throws -> [Book]
    func add(_ book: Book) throws
    func delete(_ book: Book) throws
}

final class SwiftDataBookRepository: BookRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchBooks() throws -> [Book] {
        let descriptor = FetchDescriptor<Book>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func add(_ book: Book) throws {
        context.insert(book)
        try context.save()
    }

    func delete(_ book: Book) throws {
        context.delete(book)
        try context.save()
    }
}
