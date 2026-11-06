import Foundation
import SwiftData

/// Доступ к хранилищу книг. Протокол позволяет подменять реализацию в тестах и превью.
protocol BookRepository {
    func fetchBooks() throws -> [Book]
    func add(_ book: Book) throws
    func delete(_ book: Book) throws
    /// Применяет изменение к книге и сохраняет; при ошибке изменение откатывается.
    func update(_ book: Book, _ change: (Book) -> Void) throws
}

final class SwiftDataBookRepository: BookRepository {
    private let context: ModelContext
    private let save: (ModelContext) throws -> Void

    /// - Parameter save: сохранение контекста. Подменяется только в тестах, чтобы проверить
    ///   откат: на базе в памяти настоящий `save()` упасть не может.
    init(context: ModelContext, save: @escaping (ModelContext) throws -> Void = { try $0.save() }) {
        self.context = context
        self.save = save
    }

    func fetchBooks() throws -> [Book] {
        let descriptor = FetchDescriptor<Book>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func add(_ book: Book) throws {
        try saveOrRollback { context.insert(book) }
    }

    func delete(_ book: Book) throws {
        try saveOrRollback { context.delete(book) }
    }

    func update(_ book: Book, _ change: (Book) -> Void) throws {
        try saveOrRollback { change(book) }
    }

    /// Применяет изменение и сразу сохраняет; при ошибке откатывает контекст.
    /// `rollback()` отменяет все несохранённые изменения, поэтому модели меняются
    /// только через репозиторий и каждая операция сохраняется сразу (см. CLAUDE.md).
    private func saveOrRollback(_ change: () -> Void) throws {
        change()
        do {
            try save(context)
        } catch {
            context.rollback()
            // `rollback()` сбрасывает несохранённое состояние контекста, но уже загруженные объекты
            // остаются с неудачным изменением (проверено в `SwiftDataWriteFailureTests`).
            // Повторный запрос перечитывает их из базы — экран снова показывает сохранённые данные.
            _ = try? context.fetch(FetchDescriptor<Book>())
            throw error
        }
    }
}
