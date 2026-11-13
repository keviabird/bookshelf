import Foundation
import Testing
@testable import Bookshelf

/// Переходы состояний, отмена и защита от дублей в `BookSearchViewModel`.
/// Сети нет: сервис — `FakeBookSearchService`, ответы придерживаются через `Gate`.
@MainActor
struct BookSearchFlowTests {
    private func makeViewModel(
        service: FakeBookSearchService,
        repository: any BookRepository = InMemoryBookRepository(),
        sleeper: BlockingSleeper? = nil
    ) -> BookSearchViewModel {
        BookSearchViewModel(
            service: service,
            repository: repository,
            sleep: { _ in
                if let sleeper { try await sleeper.sleep() } else { try Task.checkCancellation() }
            }
        )
    }

    nonisolated private static func results(_ count: Int) -> [BookSearchResult] {
        (0..<count).map { searchResult("/works/OL\($0)W", title: "Книга \($0)") }
    }

    // MARK: - Загрузка → результат

    enum Outcome: Sendable, CustomTestStringConvertible {
        case found(Int)
        case nothing
        case fails(any Error)

        var testDescription: String {
            switch self {
            case .found(let count): "найдено \(count)"
            case .nothing: "ничего"
            case .fails(let error): "ошибка \(error)"
            }
        }
    }

    @Test(arguments: [
        Outcome.found(1),
        .found(20),
        .nothing,
        .fails(URLError(.notConnectedToInternet)),
        .fails(BookSearchError.badStatus(500))
    ])
    func loadingThenOutcome(outcome: Outcome) async {
        let gate = Gate()
        let service = FakeBookSearchService { _, _ in
            await gate.wait()
            switch outcome {
            case .found(let count): return Self.results(count)
            case .nothing: return []
            case .fails(let error): throw error
            }
        }
        let viewModel = makeViewModel(service: service)

        viewModel.query = "мастер"
        await waitUntil { await service.queries.count == 1 }
        #expect(viewModel.state == .loading)

        await gate.open()
        await viewModel.waitForSearch()

        switch outcome {
        case .found(let count):
            #expect(viewModel.state == .results(Self.results(count)))
        case .nothing:
            #expect(viewModel.state == .empty)
        case .fails(let error):
            #expect(viewModel.state == .failed(BookSearchViewModel.message(for: error)))
        }
    }

    @Test(arguments: [
        URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
        .cannotFindHost, .cannotConnectToHost, .timedOut
    ])
    func networkErrorsSayNoConnection(code: URLError.Code) {
        #expect(BookSearchViewModel.message(for: URLError(code))
            == "Нет подключения к интернету. Проверьте сеть и попробуйте ещё раз.")
    }

    @Test(arguments: [
        BookSearchError.badStatus(500) as any Error,
        BookSearchError.badStatus(503),
        URLError(.badServerResponse),
        DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "не JSON"))
    ])
    func otherErrorsSayServiceUnavailable(error: any Error) {
        #expect(BookSearchViewModel.message(for: error) == "Сервис поиска недоступен. Попробуйте позже.")
    }

    /// Пока идёт пауза debounce, на экране прошлые результаты, а не «загрузка».
    @Test func previousResultsStayDuringDebounce() async {
        let first = searchResult("/works/1", title: "Первая")
        let second = searchResult("/works/2", title: "Вторая")
        let service = FakeBookSearchService { query, _ in query == "первый" ? [first] : [second] }
        let sleeper = BlockingSleeper(skipFirst: true)
        let viewModel = makeViewModel(service: service, sleeper: sleeper)
        viewModel.query = "первый"
        await viewModel.waitForSearch()

        viewModel.query = "второй"
        await waitUntil { await sleeper.calls == 2 }
        #expect(viewModel.state == .results([first]))

        await sleeper.release()
        await viewModel.waitForSearch()
        #expect(viewModel.state == .results([second]))
    }

    // MARK: - Отмена предыдущего запроса

    @Test func queryCancelledDuringDebounceNeverReachesService() async {
        let service = FakeBookSearchService()
        let sleeper = BlockingSleeper()
        let viewModel = makeViewModel(service: service, sleeper: sleeper)

        viewModel.query = "первый"
        await waitUntil { await sleeper.calls == 1 }
        viewModel.query = "второй"
        await waitUntil { await sleeper.calls == 2 }
        // Обе паузы заканчиваются одновременно, но первая задача уже отменена.
        await sleeper.release()
        await viewModel.waitForSearch()
        await drainTasks()

        #expect(await service.queries == ["второй"])
    }

    @Test func clearingQueryDuringRequestIgnoresLateResponse() async {
        let gate = Gate()
        let service = FakeBookSearchService { _, _ in
            await gate.wait()
            return [searchResult("/works/1")]
        }
        let viewModel = makeViewModel(service: service)
        viewModel.query = "мастер"
        await waitUntil { await service.queries.count == 1 }

        viewModel.query = ""
        await gate.open()
        await drainTasks()

        #expect(viewModel.state == .idle)
    }

    @Test func leavingScreenIgnoresLateResponse() async {
        let gate = Gate()
        let service = FakeBookSearchService { _, _ in
            await gate.wait()
            return [searchResult("/works/1")]
        }
        let viewModel = makeViewModel(service: service)
        viewModel.query = "мастер"
        await waitUntil { await service.queries.count == 1 }

        viewModel.cancelSearch()
        await gate.open()
        await drainTasks()

        // Ответ пришёл после ухода с экрана и не записан.
        #expect(viewModel.state == .loading)
    }

    @Test func retryReplacesRequestInFlight() async {
        let gate = Gate()
        let old = searchResult("/works/old", title: "Старый ответ")
        let new = searchResult("/works/new", title: "Новый ответ")
        let service = FakeBookSearchService { _, call in
            if call == 0 {
                await gate.wait()
                return [old]
            }
            return [new]
        }
        let viewModel = makeViewModel(service: service)
        viewModel.query = "мастер"
        await waitUntil { await service.queries.count == 1 }

        viewModel.retry()
        await viewModel.waitForSearch()
        await gate.open()
        await drainTasks()

        #expect(viewModel.state == .results([new]))
        #expect(await service.queries == ["мастер", "мастер"])
    }

    // MARK: - Защита от повторного добавления

    @Test(arguments: [
        ("Мастер и Маргарита", "Михаил Булгаков", "мастер и маргарита", "МИХАИЛ БУЛГАКОВ", true),
        ("Идиот", "Фёдор Достоевский", "Идиот", "Федор Достоевский", true),
        ("  Мы ", "Евгений  Замятин", "Мы", "Евгений Замятин", true),
        ("Мастер и Маргарита", "Михаил Булгаков", "Мастер и Маргарита", "Mikhail Bulgakov", false),
        ("Мастер и Маргарита", "Михаил Булгаков", "Собачье сердце", "Михаил Булгаков", false),
        ("Мы", "", "Мы", "Евгений Замятин", false)
    ])
    func manualBookDuplicateRules(
        shelfTitle: String, shelfAuthor: String,
        foundTitle: String, foundAuthor: String,
        isDuplicate: Bool
    ) {
        let repository = InMemoryBookRepository()
        repository.books = [Book(title: shelfTitle, author: shelfAuthor)]
        let viewModel = makeViewModel(service: FakeBookSearchService(), repository: repository)
        viewModel.loadShelf()
        let result = searchResult("/works/OL1W", title: foundTitle, author: foundAuthor)

        #expect(viewModel.isOnShelf(result) == isDuplicate)
        viewModel.add(result)
        #expect(repository.books.count == (isDuplicate ? 1 : 2))
    }

    /// С настоящей базой: повторное нажатие не создаёт вторую строку.
    @Test func addingTwiceStoresOneBook() throws {
        let store = try TestStore()
        let viewModel = makeViewModel(service: FakeBookSearchService(), repository: store.repository)
        viewModel.loadShelf()
        let result = searchResult("/works/OL1W")

        viewModel.add(result)
        viewModel.add(result)

        #expect(try store.persistedBooks().count == 1)
        #expect(store.saveAttempts == 1)
    }

    /// Дубль ищется и среди книг, сохранённых в прошлый раз (новый экран поиска).
    @Test func bookSavedEarlierIsRecognizedOnNewScreen() throws {
        let store = try TestStore()
        let result = searchResult("/works/OL1W")
        makeViewModel(service: FakeBookSearchService(), repository: store.repository).add(result)

        let newScreen = makeViewModel(service: FakeBookSearchService(), repository: store.repository)
        newScreen.loadShelf()

        #expect(newScreen.isOnShelf(result))
    }

    @Test func removedBookCanBeAddedAgain() throws {
        let repository = InMemoryBookRepository()
        let result = searchResult("/works/OL1W")
        repository.books = [Book(title: "Другое название", author: "", openLibraryKey: "/works/OL1W")]
        let viewModel = makeViewModel(service: FakeBookSearchService(), repository: repository)
        viewModel.loadShelf()
        #expect(viewModel.isOnShelf(result))

        repository.books.removeAll()
        viewModel.loadShelf()
        viewModel.add(result)

        #expect(repository.books.count == 1)
        #expect(viewModel.isOnShelf(result))
    }
}
