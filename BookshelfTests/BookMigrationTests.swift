import Foundation
import SwiftData
import Testing
@testable import Bookshelf

/// Модель `Book` в том виде, как она была до появления `progress`.
/// Имя класса совпадает, поэтому SwiftData считает это той же сущностью.
enum LegacySchema {
    @Model
    final class Book {
        var title: String
        var author: String
        var coverURL: URL?
        var statusRawValue: String
        var dateAdded: Date

        init(title: String, author: String, statusRawValue: String, dateAdded: Date) {
            self.title = title
            self.author = author
            self.coverURL = nil
            self.statusRawValue = statusRawValue
            self.dateAdded = dateAdded
        }
    }
}

@MainActor
struct BookMigrationTests {
    @Test func existingBooksSurviveAddingProgress() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Bookshelf.store")

        // 1. Старая версия приложения сохраняет книгу.
        do {
            let legacy = try ModelContainer(
                for: Schema([LegacySchema.Book.self]),
                configurations: ModelConfiguration(url: storeURL)
            )
            let context = ModelContext(legacy)
            context.insert(LegacySchema.Book(
                title: "Война и мир",
                author: "Толстой",
                statusRawValue: ReadingStatus.reading.rawValue,
                dateAdded: .now
            ))
            try context.save()
        }

        // 2. Новая версия открывает ту же базу.
        let current = try ModelContainer(
            for: Bookshelf.Book.self,
            configurations: ModelConfiguration(url: storeURL)
        )
        let books = try ModelContext(current).fetch(FetchDescriptor<Bookshelf.Book>())

        let book = try #require(books.first)
        #expect(books.count == 1)
        #expect(book.title == "Война и мир")
        #expect(book.author == "Толстой")
        #expect(book.status == .reading)
        #expect(book.progress == 0)
    }
}
