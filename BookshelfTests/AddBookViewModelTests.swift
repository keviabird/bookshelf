import Foundation
import Testing
@testable import Bookshelf

@MainActor
struct AddBookViewModelTests {
    @Test func failedSaveShowsErrorAndKeepsForm() {
        let repository = InMemoryBookRepository()
        repository.failWrites = true
        let viewModel = AddBookViewModel(repository: repository)
        viewModel.title = "Война и мир"
        viewModel.author = "Толстой"

        #expect(!viewModel.save())
        #expect(viewModel.errorMessage == "Не удалось сохранить книгу. Попробуйте ещё раз.")
        #expect(repository.books.isEmpty)
        // Введённые данные не теряются, можно повторить.
        #expect(viewModel.title == "Война и мир")
        #expect(viewModel.canSave)
    }

    @Test func retryAfterFailureSavesExactlyOneBook() throws {
        let repository = InMemoryBookRepository()
        repository.failWrites = true
        let viewModel = AddBookViewModel(repository: repository)
        viewModel.title = "Война и мир"

        #expect(!viewModel.save())
        repository.failWrites = false
        #expect(viewModel.save())

        #expect(viewModel.errorMessage == nil)
        #expect(repository.books.count == 1)
    }

    @Test(arguments: ["", "   ", "\n", " \t\n "])
    func cannotSaveWithEmptyTitle(title: String) {
        let repository = InMemoryBookRepository()
        let viewModel = AddBookViewModel(repository: repository)
        viewModel.title = title
        viewModel.author = "Толстой"

        #expect(!viewModel.canSave)
        #expect(!viewModel.save())
        #expect(repository.books.isEmpty)
    }

    @Test func canSaveWithTitleOnly() throws {
        let repository = InMemoryBookRepository()
        let viewModel = AddBookViewModel(repository: repository)
        viewModel.title = "Война и мир"
        viewModel.author = "  "

        #expect(viewModel.canSave)
        #expect(viewModel.save())
        let book = try #require(repository.books.first)
        #expect(book.author == "")
        #expect(book.status == .wantToRead)
    }

    @Test(arguments: ["1Толстой", "  2 Толстой", "٣ Автор"])
    func authorStartingWithDigitBlocksSave(author: String) {
        let repository = InMemoryBookRepository()
        let viewModel = AddBookViewModel(repository: repository)
        viewModel.title = "Война и мир"
        viewModel.author = author

        #expect(!viewModel.isAuthorValid)
        #expect(!viewModel.canSave)
        #expect(!viewModel.save())
        #expect(repository.books.isEmpty)
    }

    @Test(arguments: ["", "Толстой", "Лев Толстой 2", "А. Б. 1828"])
    func authorNotStartingWithDigitIsValid(author: String) {
        let viewModel = AddBookViewModel(repository: InMemoryBookRepository())
        viewModel.title = "Война и мир"
        viewModel.author = author

        #expect(viewModel.isAuthorValid)
        #expect(viewModel.canSave)
    }

    @Test func invalidCoverURLBlocksSave() {
        let viewModel = AddBookViewModel(repository: InMemoryBookRepository())
        viewModel.title = "Война и мир"
        viewModel.author = "Толстой"
        viewModel.coverURLString = "не адрес"
        #expect(!viewModel.isCoverURLValid)
        #expect(!viewModel.canSave)
    }

    @Test func savesTrimmedBook() throws {
        let repository = InMemoryBookRepository()
        let viewModel = AddBookViewModel(repository: repository)
        viewModel.title = "  Война и мир "
        viewModel.author = " Толстой  "
        viewModel.coverURLString = "https://example.com/cover.jpg"
        viewModel.status = .reading

        #expect(viewModel.save())
        let book = try #require(repository.books.first)
        #expect(book.title == "Война и мир")
        #expect(book.author == "Толстой")
        #expect(book.coverURL == URL(string: "https://example.com/cover.jpg"))
        #expect(book.status == .reading)
    }

    // MARK: - Прогресс чтения

    @Test func progressSliderShownOnlyWhileReading() {
        let viewModel = AddBookViewModel(repository: InMemoryBookRepository())

        viewModel.status = .wantToRead
        #expect(!viewModel.showsProgress)
        viewModel.status = .reading
        #expect(viewModel.showsProgress)
        viewModel.status = .finished
        #expect(!viewModel.showsProgress)
    }

    @Test(arguments: [
        (ReadingStatus.wantToRead, 0.0),
        (ReadingStatus.reading, 0.4),
        (ReadingStatus.finished, 1.0),
    ])
    func savedProgressDependsOnStatus(status: ReadingStatus, expected: Double) throws {
        let repository = InMemoryBookRepository()
        let viewModel = AddBookViewModel(repository: repository)
        viewModel.title = "Мастер и Маргарита"
        // Значение слайдера учитывается только для «Читаю».
        viewModel.progress = 0.4
        viewModel.status = status

        #expect(viewModel.save())
        let book = try #require(repository.books.first)
        #expect(book.progress == expected)
    }
}
