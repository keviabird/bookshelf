import Foundation
import Testing
@testable import Bookshelf

/// Форма добавления: страницы, текущая страница, год, описание.
@MainActor
struct AddBookPagesTests {
    private func makeViewModel(_ repository: InMemoryBookRepository = InMemoryBookRepository()) -> AddBookViewModel {
        let viewModel = AddBookViewModel(repository: repository, currentYear: 2026)
        viewModel.title = "Мастер и Маргарита"
        return viewModel
    }

    // MARK: - Число страниц

    @Test func pageCountOptionalForWantToRead() {
        let viewModel = makeViewModel()
        viewModel.status = .wantToRead

        #expect(!viewModel.isPageCountRequired)
        #expect(viewModel.canSave)
    }

    @Test(arguments: [ReadingStatus.reading, .finished])
    func pageCountRequiredForReadingAndFinished(status: ReadingStatus) {
        let viewModel = makeViewModel()
        viewModel.status = status

        #expect(viewModel.isPageCountRequired)
        #expect(!viewModel.canSave)

        viewModel.pageCountText = "300"
        #expect(viewModel.canSave)
    }

    @Test(arguments: ["0", "-5", "abc", "12.5"])
    func invalidPageCountBlocksSave(text: String) {
        let viewModel = makeViewModel()
        viewModel.pageCountText = text

        #expect(!viewModel.isPageCountValid)
        #expect(viewModel.pageCountError != nil)
        #expect(!viewModel.canSave)
    }

    @Test func emptyRequiredPageCountShowsNoErrorText() {
        let viewModel = makeViewModel()
        viewModel.status = .reading

        // Пустое обязательное поле блокирует сохранение, но не «кричит» красным.
        #expect(!viewModel.canSave)
        #expect(viewModel.pageCountError == nil)
    }

    // MARK: - Текущая страница

    @Test func currentPageShownOnlyWhileReading() {
        let viewModel = makeViewModel()
        viewModel.status = .wantToRead
        #expect(!viewModel.showsCurrentPage)
        viewModel.status = .reading
        #expect(viewModel.showsCurrentPage)
        viewModel.status = .finished
        #expect(!viewModel.showsCurrentPage)
    }

    @Test func currentPageAbovePageCountBlocksSave() {
        let viewModel = makeViewModel()
        viewModel.status = .reading
        viewModel.pageCountText = "300"
        viewModel.currentPageText = "301"

        #expect(!viewModel.isCurrentPageValid)
        #expect(viewModel.currentPageError == "Страница должна быть от 0 до 300")
        #expect(!viewModel.canSave)
    }

    @Test func computedProgressFollowsPages() {
        let viewModel = makeViewModel()
        viewModel.status = .reading
        viewModel.pageCountText = "300"
        #expect(viewModel.computedProgressText == nil)

        viewModel.currentPageText = "150"
        #expect(viewModel.computedProgressText == "50%")
    }

    @Test func readingBookSavesCurrentPageAndProgress() throws {
        let repository = InMemoryBookRepository()
        let viewModel = makeViewModel(repository)
        viewModel.status = .reading
        viewModel.pageCountText = "300"
        viewModel.currentPageText = "150"

        #expect(viewModel.save())
        let book = try #require(repository.books.first)
        #expect(book.pageCount == 300)
        #expect(book.currentPage == 150)
        #expect(book.progress == 0.5)
        #expect(book.status == .reading)
    }

    @Test func readingOnLastPageIsSavedAsFinished() throws {
        let repository = InMemoryBookRepository()
        let viewModel = makeViewModel(repository)
        viewModel.status = .reading
        viewModel.pageCountText = "300"
        viewModel.currentPageText = "300"

        #expect(viewModel.save())
        #expect(try #require(repository.books.first).status == .finished)
    }

    @Test func finishedBookGetsLastPage() throws {
        let repository = InMemoryBookRepository()
        let viewModel = makeViewModel(repository)
        viewModel.status = .finished
        viewModel.pageCountText = "224"

        #expect(viewModel.save())
        let book = try #require(repository.books.first)
        #expect(book.currentPage == 224)
        #expect(book.progress == 1)
    }

    @Test func wantToReadIgnoresEnteredCurrentPage() throws {
        let repository = InMemoryBookRepository()
        let viewModel = makeViewModel(repository)
        // Пользователь начал с «Читаю», ввёл страницу и передумал.
        viewModel.status = .reading
        viewModel.pageCountText = "300"
        viewModel.currentPageText = "120"
        viewModel.status = .wantToRead

        #expect(viewModel.save())
        let book = try #require(repository.books.first)
        #expect(book.currentPage == nil)
        #expect(book.status == .wantToRead)
    }

    // MARK: - Год и описание

    @Test(arguments: ["0", "2027", "год"])
    func invalidYearBlocksSave(text: String) {
        let viewModel = makeViewModel()
        viewModel.yearText = text

        #expect(!viewModel.isYearValid)
        #expect(viewModel.yearError == "Введите год от 1 до 2026")
        #expect(!viewModel.canSave)
    }

    @Test func savesYearAndTrimmedDescription() throws {
        let repository = InMemoryBookRepository()
        let viewModel = makeViewModel(repository)
        viewModel.yearText = "1967"
        viewModel.bookDescription = "  Роман о Мастере.  \n"

        #expect(viewModel.save())
        let book = try #require(repository.books.first)
        #expect(book.publicationYear == 1967)
        #expect(book.bookDescription == "Роман о Мастере.")
    }
}
