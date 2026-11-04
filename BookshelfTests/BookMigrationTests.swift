import Foundation
import SwiftData
import Testing
@testable import Bookshelf

// Прежние версии модели `Book`. Имя класса совпадает, поэтому SwiftData считает их той же сущностью.

/// Самая первая версия: без прогресса и подробностей.
enum LegacySchemaV1 {
    @Model
    final class Book {
        var title: String
        var author: String
        var coverURL: URL?
        var statusRawValue: String
        var dateAdded: Date

        init(title: String, author: String, statusRawValue: String) {
            self.title = title
            self.author = author
            self.statusRawValue = statusRawValue
            self.dateAdded = .now
        }
    }
}

/// Версия с хранимым `progress` (экран списка по макету) — поле затем удалено.
enum LegacySchemaV2 {
    @Model
    final class Book {
        var title: String
        var author: String
        var coverURL: URL?
        var statusRawValue: String
        var dateAdded: Date
        var progress: Double = 0

        init(title: String, author: String, statusRawValue: String, progress: Double) {
            self.title = title
            self.author = author
            self.statusRawValue = statusRawValue
            self.dateAdded = .now
            self.progress = progress
        }
    }
}

@MainActor
struct BookMigrationTests {
    /// Сохраняет книгу старой версией модели и открывает ту же базу текущей.
    private func migrate(
        legacy: any PersistentModel.Type,
        insert: (ModelContext) -> Void
    ) throws -> [Bookshelf.Book] {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Bookshelf.store")

        do {
            let container = try ModelContainer(for: Schema([legacy]), configurations: ModelConfiguration(url: storeURL))
            let context = ModelContext(container)
            insert(context)
            try context.save()
        }

        let current = try ModelContainer(for: Bookshelf.Book.self, configurations: ModelConfiguration(url: storeURL))
        return try ModelContext(current).fetch(FetchDescriptor<Bookshelf.Book>())
    }

    @Test func firstVersionGetsDefaultsForNewFields() throws {
        let books = try migrate(legacy: LegacySchemaV1.Book.self) { context in
            context.insert(LegacySchemaV1.Book(
                title: "Война и мир",
                author: "Толстой",
                statusRawValue: ReadingStatus.reading.rawValue
            ))
        }

        let book = try #require(books.first)
        #expect(books.count == 1)
        #expect(book.title == "Война и мир")
        #expect(book.author == "Толстой")
        #expect(book.status == .reading)
        #expect(book.pageCount == 0)
        #expect(book.currentPage == nil)
        #expect(book.publicationYear == nil)
        #expect(book.bookDescription == "")
        #expect(!book.isFavorite)
        #expect(book.progress == 0)
    }

    @Test func storedProgressIsDroppedWithoutBreakingStore() throws {
        let books = try migrate(legacy: LegacySchemaV2.Book.self) { context in
            context.insert(LegacySchemaV2.Book(
                title: "Мы",
                author: "Замятин",
                statusRawValue: ReadingStatus.reading.rawValue,
                progress: 0.75
            ))
        }

        let book = try #require(books.first)
        #expect(book.title == "Мы")
        #expect(book.status == .reading)
        // Старый процент не переносится: прогресс теперь считается только по страницам.
        #expect(!book.hasKnownPages)
        #expect(book.progress == 0)
    }
}
