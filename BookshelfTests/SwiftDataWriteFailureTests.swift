import Foundation
import SwiftData
import Testing
@testable import Bookshelf

/// Сбой `save()` посередине операции: изменение уже применено к контексту, сохранение падает.
/// Репозиторий делает `rollback()` — в базе и в контексте не должно остаться следов операции.
@MainActor
struct SwiftDataWriteFailureTests {
    /// Сохранённое состояние книги — для сравнения «до» и «после».
    struct Snapshot: Equatable {
        let title: String
        let status: ReadingStatus
        let currentPage: Int?
        let isFavorite: Bool

        init(_ book: Book) {
            title = book.title
            status = book.status
            currentPage = book.currentPage
            isFavorite = book.isFavorite
        }
    }

    enum Operation: String, CaseIterable, Sendable, CustomTestStringConvertible {
        case add, update, delete
        var testDescription: String { rawValue }
    }

    /// База с двумя сохранёнными книгами.
    private func makeStore() throws -> (TestStore, Book) {
        let store = try TestStore()
        let book = Book(title: "Мы", author: "Замятин", status: .reading, pageCount: 224, currentPage: 10, dateAdded: daysAgo(1))
        try store.repository.add(book)
        try store.repository.add(Book(title: "Идиот", author: "Достоевский", dateAdded: daysAgo(2)))
        return (store, book)
    }

    @Test(arguments: Operation.allCases)
    func failedWriteLeavesStoreUnchanged(operation: Operation) throws {
        let (store, book) = try makeStore()
        let before = try store.persistedBooks().map(Snapshot.init)
        store.failSaves = true

        #expect(throws: TestStore.SaveError.self) {
            switch operation {
            case .add:
                try store.repository.add(Book(title: "Новая", author: ""))
            case .update:
                try store.repository.update(book) {
                    $0.setStatus(.finished)
                    $0.isFavorite = true
                }
            case .delete:
                try store.repository.delete(book)
            }
        }

        // Сохранение действительно вызывалось — то есть сбой был после изменения контекста.
        #expect(store.saveAttempts == 3)
        #expect(!store.context.hasChanges)
        #expect(try store.persistedBooks().map(Snapshot.init) == before)
        // И рабочий контекст, из которого читает приложение, видит то же самое.
        let visible = try store.repository.fetchBooks().map(Snapshot.init)
        #expect(visible == before)
    }

    @Test func failedUpdateRevertsEveryChangedField() throws {
        let (store, book) = try makeStore()
        store.failSaves = true

        try? store.repository.update(book) {
            $0.setCurrentPage(224) // → «Прочитано» и последняя страница
            $0.isFavorite = true
            $0.title = "Мы (переименовано)"
        }

        #expect(book.status == .reading)
        #expect(book.currentPage == 10)
        #expect(!book.isFavorite)
        #expect(book.title == "Мы")
    }

    @Test func failedAddLeavesNothingInContext() throws {
        let store = try TestStore()
        store.failSaves = true

        try? store.repository.add(Book(title: "Новая", author: ""))

        #expect(try store.context.fetch(FetchDescriptor<Book>()).isEmpty)
        #expect(try store.persistedBooks().isEmpty)
    }

    @Test func nextSuccessfulWriteSavesOnlyItsOwnChange() throws {
        let store = try TestStore()
        store.failSaves = true
        try? store.repository.add(Book(title: "Не сохранилась", author: ""))

        store.failSaves = false
        try store.repository.add(Book(title: "Сохранилась", author: ""))

        #expect(try store.persistedBooks().map(\.title) == ["Сохранилась"])
    }

    /// Документирует подвох из CLAUDE.md: `rollback()` отменяет все несохранённые изменения,
    /// в том числе сделанные в обход репозитория. Поэтому модели меняются только через репозиторий.
    @Test func rollbackAlsoDiscardsChangesMadeOutsideRepository() throws {
        let (store, book) = try makeStore()
        book.title = "Изменено напрямую"
        store.failSaves = true

        try? store.repository.add(Book(title: "Новая", author: ""))

        #expect(book.title == "Мы")
    }

    // MARK: - ViewModel с настоящей базой

    @Test func failedAddBookFormKeepsStoreEmpty() throws {
        let store = try TestStore()
        store.failSaves = true
        let viewModel = AddBookViewModel(repository: store.repository)
        viewModel.title = "Война и мир"
        viewModel.author = "Толстой"

        #expect(!viewModel.save())

        #expect(try store.persistedBooks().isEmpty)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.title == "Война и мир")
    }

    @Test func failedStatusChangeInDetailKeepsOldStatus() throws {
        let (store, book) = try makeStore()
        store.failSaves = true
        let viewModel = BookDetailViewModel(book: book, repository: store.repository)

        viewModel.setStatus(.finished)

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.status == .reading)
        #expect(viewModel.pagesText == "Стр. 10 из 224")
        let saved = try #require(try store.persistedBooks().first { $0.title == "Мы" })
        #expect(saved.status == .reading)
        #expect(saved.currentPage == 10)
    }

    @Test func failedSearchAddKeepsStoreUnchanged() throws {
        let (store, _) = try makeStore()
        store.failSaves = true
        let viewModel = BookSearchViewModel(service: FakeBookSearchService(), repository: store.repository)
        viewModel.loadShelf()
        let result = searchResult("/works/OL1W")

        viewModel.add(result)

        #expect(try store.persistedBooks().count == 2)
        #expect(!viewModel.isOnShelf(result))
        #expect(viewModel.errorMessage != nil)
    }
}
