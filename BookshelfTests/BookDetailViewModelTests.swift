import Foundation
import Testing
@testable import Bookshelf

@MainActor
struct BookDetailViewModelTests {
    private static let dateAdded: Date = {
        guard let date = Calendar.current.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 12)) else {
            preconditionFailure("Некорректная дата для тестов")
        }
        return date
    }()

    private func makeBook(
        status: ReadingStatus = .reading,
        pageCount: Int = 498,
        currentPage: Int? = 210,
        year: Int? = 2023,
        description: String = "Описание книги."
    ) -> Book {
        Book(
            title: "Мастер и Маргарита",
            author: "Михаил Булгаков",
            status: status,
            pageCount: pageCount,
            currentPage: currentPage,
            publicationYear: year,
            bookDescription: description,
            dateAdded: Self.dateAdded
        )
    }

    // MARK: - Скрытие блоков

    @Test func fullBookShowsEverything() {
        let viewModel = BookDetailViewModel(book: makeBook(), repository: InMemoryBookRepository())

        #expect(viewModel.showsProgress)
        #expect(viewModel.progressText == "42%")
        #expect(viewModel.pagesText == "Стр. 210 из 498")
        #expect(viewModel.stats == [
            .init(value: "498", label: "страниц"),
            .init(value: "2023", label: "год"),
            .init(value: "12.10", label: "добавлена")
        ])
        #expect(viewModel.hasDescription)
    }

    @Test func bookWithoutPagesHidesProgressAndPagesStat() {
        let viewModel = BookDetailViewModel(
            book: makeBook(pageCount: 0, currentPage: nil),
            repository: InMemoryBookRepository()
        )

        #expect(!viewModel.showsProgress)
        #expect(viewModel.pagesText == nil)
        #expect(viewModel.stats.map(\.label) == ["год", "добавлена"])
    }

    @Test func bookWithoutYearOrDescription() {
        let viewModel = BookDetailViewModel(
            book: makeBook(year: nil, description: "  \n"),
            repository: InMemoryBookRepository()
        )

        #expect(viewModel.stats.map(\.label) == ["страниц", "добавлена"])
        #expect(!viewModel.hasDescription)
    }

    @Test func pagesTextWithoutCurrentPage() {
        let viewModel = BookDetailViewModel(
            book: makeBook(status: .wantToRead, currentPage: nil),
            repository: InMemoryBookRepository()
        )
        #expect(viewModel.pagesText == "Стр. 0 из 498")
    }

    @Test func pagesStatAgreesWithCount() {
        let viewModel = BookDetailViewModel(book: makeBook(pageCount: 221), repository: InMemoryBookRepository())
        #expect(viewModel.stats.first == .init(value: "221", label: "страница"))
    }

    // MARK: - Действия

    @Test func finishedChipSetsLastPage() {
        let book = makeBook()
        var changes = 0
        let viewModel = BookDetailViewModel(book: book, repository: InMemoryBookRepository()) { changes += 1 }

        viewModel.setStatus(.finished)

        #expect(viewModel.status == .finished)
        #expect(book.currentPage == 498)
        #expect(viewModel.progressText == "100%")
        #expect(changes == 1)
    }

    @Test func selectingSameStatusDoesNothing() {
        var changes = 0
        let viewModel = BookDetailViewModel(book: makeBook(), repository: InMemoryBookRepository()) { changes += 1 }

        viewModel.setStatus(.reading)

        #expect(changes == 0)
    }

    @Test func toggleFavorite() {
        let book = makeBook()
        let viewModel = BookDetailViewModel(book: book, repository: InMemoryBookRepository())

        viewModel.toggleFavorite()
        #expect(book.isFavorite)
        viewModel.toggleFavorite()
        #expect(!book.isFavorite)
    }

    // MARK: - Обновление прогресса

    @Test func startUpdatingUsesCurrentPage() {
        let viewModel = BookDetailViewModel(book: makeBook(), repository: InMemoryBookRepository())

        viewModel.startUpdatingProgress()

        #expect(viewModel.isUpdatingProgress)
        #expect(viewModel.draftPage == 210)
        #expect(viewModel.draftPageRange == 0...498)
        #expect(viewModel.draftPagesText == "Стр. 210 из 498")
        #expect(viewModel.draftProgressText == "42%")
    }

    @Test func cannotUpdateProgressWithoutPages() {
        let viewModel = BookDetailViewModel(
            book: makeBook(pageCount: 0, currentPage: nil),
            repository: InMemoryBookRepository()
        )
        viewModel.startUpdatingProgress()
        #expect(!viewModel.isUpdatingProgress)
    }

    @Test func saveProgressUpdatesPage() {
        let book = makeBook()
        let viewModel = BookDetailViewModel(book: book, repository: InMemoryBookRepository())
        viewModel.startUpdatingProgress()

        viewModel.draftPage = 300
        #expect(viewModel.saveProgress())

        #expect(book.currentPage == 300)
        #expect(book.status == .reading)
        #expect(!viewModel.isUpdatingProgress)
    }

    @Test func savingLastPageFinishesBook() {
        let book = makeBook()
        let viewModel = BookDetailViewModel(book: book, repository: InMemoryBookRepository())
        viewModel.startUpdatingProgress()

        viewModel.draftPage = 498
        viewModel.saveProgress()

        #expect(book.status == .finished)
    }

    @Test func savingProgressOnWantToReadStartsReading() {
        let book = makeBook(status: .wantToRead, currentPage: nil)
        let viewModel = BookDetailViewModel(book: book, repository: InMemoryBookRepository())
        viewModel.startUpdatingProgress()

        viewModel.draftPage = 20
        viewModel.saveProgress()

        #expect(book.status == .reading)
        #expect(book.currentPage == 20)
    }

    // MARK: - Ошибки

    @Test func failedWriteShowsErrorAndKeepsData() {
        let book = makeBook()
        let repository = InMemoryBookRepository()
        repository.failWrites = true
        var changes = 0
        let viewModel = BookDetailViewModel(book: book, repository: repository) { changes += 1 }
        viewModel.startUpdatingProgress()
        viewModel.draftPage = 400

        #expect(!viewModel.saveProgress())

        #expect(viewModel.errorMessage == "Не удалось сохранить изменения. Попробуйте ещё раз.")
        #expect(book.currentPage == 210)
        #expect(viewModel.isUpdatingProgress)
        #expect(changes == 0)
    }

    @Test func successAfterFailureClearsError() {
        let repository = InMemoryBookRepository()
        repository.failWrites = true
        let viewModel = BookDetailViewModel(book: makeBook(), repository: repository)
        viewModel.toggleFavorite()
        #expect(viewModel.errorMessage != nil)

        repository.failWrites = false
        viewModel.toggleFavorite()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isFavorite)
    }

    // MARK: - Связь со списком

    @Test func listCreatesDetailThatReloadsList() {
        let repository = InMemoryBookRepository()
        let book = makeBook()
        repository.books = [book]
        let list = BookListViewModel(repository: repository)
        list.loadBooks()
        let detail = list.makeDetailViewModel(for: book)

        detail.setStatus(.finished)

        #expect(list.count(for: .finished) == 1)
        #expect(list.count(for: .reading) == 0)
    }
}
