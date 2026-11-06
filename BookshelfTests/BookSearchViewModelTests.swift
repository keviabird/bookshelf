import Foundation
import Testing
@testable import Bookshelf

@MainActor
struct BookSearchViewModelTests {
    /// Debounce без реального ожидания: только проверка отмены.
    private func makeViewModel(
        service: FakeBookSearchService,
        repository: any BookRepository = InMemoryBookRepository(),
        onAdd: @escaping () -> Void = {}
    ) -> BookSearchViewModel {
        BookSearchViewModel(
            service: service,
            repository: repository,
            sleep: { _ in try Task.checkCancellation() },
            onAdd: onAdd
        )
    }

    // MARK: - Состояния

    @Test func shortQueryStaysIdle() async {
        let service = FakeBookSearchService()
        let viewModel = makeViewModel(service: service)

        viewModel.query = " м "
        await viewModel.waitForSearch()

        #expect(viewModel.state == .idle)
        #expect(await service.queries.isEmpty)
    }

    @Test func showsResultsForTrimmedQuery() async {
        let result = searchResult("/works/1")
        let service = FakeBookSearchService { _, _ in [result] }
        let viewModel = makeViewModel(service: service)

        viewModel.query = "  мастер "
        await viewModel.waitForSearch()

        #expect(viewModel.state == .results([result]))
        #expect(await service.queries == ["мастер"])
    }

    @Test func showsEmptyStateWhenNothingFound() async {
        let viewModel = makeViewModel(service: FakeBookSearchService { _, _ in [] })

        viewModel.query = "ывапролд"
        await viewModel.waitForSearch()

        #expect(viewModel.state == .empty)
    }

    @Test func clearingQueryReturnsToIdle() async {
        let viewModel = makeViewModel(service: FakeBookSearchService { _, _ in [searchResult("/works/1")] })
        viewModel.query = "мастер"
        await viewModel.waitForSearch()

        viewModel.query = ""

        #expect(viewModel.state == .idle)
    }

    @Test func offlineErrorThenRetryShowsResults() async {
        let result = searchResult("/works/1")
        let service = FakeBookSearchService { _, call in
            if call == 0 { throw URLError(.notConnectedToInternet) }
            return [result]
        }
        let viewModel = makeViewModel(service: service)

        viewModel.query = "мастер"
        await viewModel.waitForSearch()
        #expect(viewModel.state == .failed("Нет подключения к интернету. Проверьте сеть и попробуйте ещё раз."))

        viewModel.retry()
        await viewModel.waitForSearch()
        #expect(viewModel.state == .results([result]))
        #expect(await service.queries == ["мастер", "мастер"])
    }

    @Test func serverErrorHasItsOwnMessage() async {
        let viewModel = makeViewModel(service: FakeBookSearchService { _, _ in
            throw BookSearchError.badStatus(503)
        })

        viewModel.query = "мастер"
        await viewModel.waitForSearch()

        #expect(viewModel.state == .failed("Сервис поиска недоступен. Попробуйте позже."))
    }

    // MARK: - Debounce и отмена

    @Test func debounceWaits300Milliseconds() async {
        let recorder = DurationRecorder()
        let viewModel = BookSearchViewModel(
            service: FakeBookSearchService(),
            repository: InMemoryBookRepository(),
            sleep: { duration in await recorder.record(duration) }
        )

        viewModel.query = "мастер"
        await viewModel.waitForSearch()

        #expect(await recorder.durations == [.milliseconds(300)])
    }

    @Test func fastTypingSendsOnlyLastQuery() async {
        let service = FakeBookSearchService()
        let viewModel = makeViewModel(service: service)

        // Ввод быстрее паузы: прошлые задачи отменяются, пока ждут.
        viewModel.query = "ма"
        viewModel.query = "мас"
        viewModel.query = "мастер"
        await viewModel.waitForSearch()

        #expect(await service.queries == ["мастер"])
    }

    @Test func retryDoesNotWaitForDebounce() async {
        let recorder = DurationRecorder()
        let service = FakeBookSearchService { _, call in
            if call == 0 { throw URLError(.timedOut) }
            return []
        }
        let viewModel = BookSearchViewModel(
            service: service,
            repository: InMemoryBookRepository(),
            sleep: { duration in await recorder.record(duration) }
        )
        viewModel.query = "мастер"
        await viewModel.waitForSearch()

        viewModel.retry()
        await viewModel.waitForSearch()

        #expect(await recorder.durations.count == 1)
        #expect(viewModel.state == .empty)
    }

    @Test func lateResponseToOldQueryIsIgnored() async {
        let gate = Gate()
        let old = searchResult("/works/old", title: "Старое")
        let new = searchResult("/works/new", title: "Новое")
        let service = FakeBookSearchService { query, _ in
            if query == "первый" {
                await gate.wait()
                return [old]
            }
            return [new]
        }
        let viewModel = makeViewModel(service: service)

        viewModel.query = "первый"
        await waitUntil { await service.queries.count == 1 }
        viewModel.query = "второй"
        await viewModel.waitForSearch()
        #expect(viewModel.state == .results([new]))

        // Старый запрос отвечает позже нового.
        await gate.open()
        for _ in 0..<50 { await Task.yield() }
        #expect(viewModel.state == .results([new]))
    }

    @Test func cancelledRequestDoesNotShowError() async {
        let gate = Gate()
        let new = searchResult("/works/new")
        let service = FakeBookSearchService { query, _ in
            if query == "первый" {
                await gate.wait()
                throw URLError(.cancelled)
            }
            return [new]
        }
        let viewModel = makeViewModel(service: service)

        viewModel.query = "первый"
        await waitUntil { await service.queries.count == 1 }
        viewModel.query = "второй"
        await viewModel.waitForSearch()

        await gate.open()
        for _ in 0..<50 { await Task.yield() }
        #expect(viewModel.state == .results([new]))
    }

    // MARK: - Полка

    @Test func addSavesBookAsWantToRead() throws {
        let repository = InMemoryBookRepository()
        var addCount = 0
        let viewModel = makeViewModel(service: FakeBookSearchService(), repository: repository) { addCount += 1 }
        let result = searchResult("/works/OL1W")

        viewModel.add(result)

        let book = try #require(repository.books.first)
        #expect(book.title == "Мастер и Маргарита")
        #expect(book.author == "Михаил Булгаков")
        #expect(book.status == .wantToRead)
        #expect(book.openLibraryKey == "/works/OL1W")
        #expect(book.pageCount == 480)
        #expect(book.publicationYear == 1967)
        #expect(viewModel.isOnShelf(result))
        #expect(addCount == 1)
    }

    @Test func sameBookIsNotAddedTwice() {
        let repository = InMemoryBookRepository()
        var addCount = 0
        let viewModel = makeViewModel(service: FakeBookSearchService(), repository: repository) { addCount += 1 }
        let result = searchResult("/works/OL1W")

        viewModel.add(result)
        viewModel.add(result)

        #expect(repository.books.count == 1)
        #expect(addCount == 1)
    }

    @Test func manuallyAddedBookMatchesByTitleAndAuthor() {
        let repository = InMemoryBookRepository()
        repository.books = [Book(title: "мастер и  Маргарита ", author: "михаил булгаков")]
        let viewModel = makeViewModel(service: FakeBookSearchService(), repository: repository)
        viewModel.loadShelf()
        let result = searchResult("/works/OL1W")

        #expect(viewModel.isOnShelf(result))
        viewModel.add(result)
        #expect(repository.books.count == 1)
    }

    @Test func bookFromSearchMatchesByKey() {
        let repository = InMemoryBookRepository()
        repository.books = [Book(title: "The Master and Margarita", author: "Mikhail Bulgakov", openLibraryKey: "/works/OL1W")]
        let viewModel = makeViewModel(service: FakeBookSearchService(), repository: repository)
        viewModel.loadShelf()

        #expect(viewModel.isOnShelf(searchResult("/works/OL1W")))
        #expect(!viewModel.isOnShelf(searchResult("/works/OL2W", title: "Собачье сердце")))
    }

    @Test func failedAddShowsErrorAndKeepsBookOffShelf() {
        let repository = InMemoryBookRepository()
        repository.failWrites = true
        var addCount = 0
        let viewModel = makeViewModel(service: FakeBookSearchService(), repository: repository) { addCount += 1 }
        let result = searchResult("/works/OL1W")

        viewModel.add(result)

        #expect(viewModel.errorMessage == "Не удалось добавить книгу. Попробуйте ещё раз.")
        #expect(!viewModel.isOnShelf(result))
        #expect(addCount == 0)

        repository.failWrites = false
        viewModel.add(result)
        #expect(viewModel.errorMessage == nil)
        #expect(repository.books.count == 1)
    }

    @Test func normalizationIgnoresCaseYoAndSpaces() {
        #expect(BookSearchViewModel.normalized("  Фёдор   ДОСТОЕВСКИЙ ") == "федор достоевский")
    }
}
