import Foundation
@testable import Bookshelf

/// Хранилище в памяти для тестов ViewModel. Флаги `fail…` имитируют ошибки хранилища:
/// при ошибке изменения не применяются, как после rollback в настоящем репозитории.
final class InMemoryBookRepository: BookRepository {
    struct StorageError: Error {}

    var books: [Book] = []
    var failFetch = false
    var failWrites = false

    func fetchBooks() throws -> [Book] {
        if failFetch { throw StorageError() }
        return books
    }

    func add(_ book: Book) throws {
        if failWrites { throw StorageError() }
        books.append(book)
    }

    func delete(_ book: Book) throws {
        if failWrites { throw StorageError() }
        books.removeAll { $0 === book }
    }
}
