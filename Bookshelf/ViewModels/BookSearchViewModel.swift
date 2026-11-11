import Foundation
import Observation

@Observable
@MainActor
final class BookSearchViewModel {
    enum State: Equatable {
        /// Запрос пустой или слишком короткий.
        case idle
        case loading
        case results([BookSearchResult])
        /// Ничего не найдено.
        case empty
        case failed(String)
    }

    static let minQueryLength = 2
    static let debounceInterval: Duration = .milliseconds(300)

    var query = "" {
        didSet { if query != oldValue { scheduleSearch() } }
    }
    private(set) var state: State = .idle
    /// Ошибка добавления на полку.
    private(set) var errorMessage: String?

    private let service: BookSearchService
    private let repository: BookRepository
    private let sleep: @Sendable (Duration) async throws -> Void
    private let onAdd: () -> Void

    private var searchTask: Task<Void, Never>?
    /// Ключи Open Library книг на полке.
    private var shelfKeys: Set<String> = []
    /// Нормализованные пары «название|автор» книг на полке — для книг, добавленных вручную.
    private var shelfTitles: Set<String> = []

    /// - Parameter sleep: ожидание debounce; в тестах подменяется, чтобы не ждать реальное время.
    init(
        service: BookSearchService,
        repository: BookRepository,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        onAdd: @escaping () -> Void = {}
    ) {
        self.service = service
        self.repository = repository
        self.sleep = sleep
        self.onAdd = onAdd
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Поиск

    /// Debounce через отмену: каждый ввод отменяет прошлую задачу. Она либо ещё ждёт паузу
    /// (и до сети не доходит), либо ждёт ответ (отмена прерывает запрос в `URLSession`).
    private func scheduleSearch() {
//        searchTask?.cancel()
        let text = trimmedQuery
        guard text.count >= Self.minQueryLength else {
            searchTask = nil
            state = .idle
            return
        }
        searchTask = Task { [weak self, sleep] in
            do {
                try await sleep(Self.debounceInterval)
            } catch {
                return // ввод изменился во время паузы
            }
            await self?.run(text)
        }
    }

    /// Повторяет текущий запрос сразу, без паузы.
    func retry() {
        searchTask?.cancel()
        let text = trimmedQuery
        guard text.count >= Self.minQueryLength else { return }
        searchTask = Task { [weak self] in
            await self?.run(text)
        }
    }

    /// Уход с экрана: незачем ждать ответ.
    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }

    /// Для тестов: дождаться окончания текущего поиска.
    func waitForSearch() async {
        await searchTask?.value
    }

    private func run(_ text: String) async {
        // «Загрузка» только после паузы: пока пользователь печатает, видны прошлые результаты.
        state = .loading
        do {
            let results = try await service.search(text)
            // Ответ на отменённый запрос не должен перезаписать новый.
            guard !Task.isCancelled else { return }
            state = results.isEmpty ? .empty : .results(results)
        } catch {
            // Отмена задачи (новый ввод, уход с экрана) — не ошибка: новое состояние задаст
            // следующий поиск. По самой ошибке отмену не определяем: `URLError(.cancelled)`
            // без отмены задачи оставил бы экран в «загрузке» навсегда.
            guard !Task.isCancelled else { return }
            state = .failed(Self.message(for: error))
        }
    }

    static func message(for error: Error) -> String {
        let offlineCodes: Set<URLError.Code> = [
            .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
            .internationalRoamingOff, .cannotFindHost, .cannotConnectToHost, .timedOut,
        ]
        if let urlError = error as? URLError, offlineCodes.contains(urlError.code) {
            return "Нет подключения к интернету. Проверьте сеть и попробуйте ещё раз."
        }
        return "Сервис поиска недоступен. Попробуйте позже."
    }

    // MARK: - Полка

    /// Читает книги полки, чтобы отметить уже добавленные.
    func loadShelf() {
        guard let books = try? repository.fetchBooks() else { return }
        shelfKeys = Set(books.compactMap(\.openLibraryKey))
        shelfTitles = Set(books.map { Self.titleKey(title: $0.title, author: $0.author) })
    }

    func isOnShelf(_ result: BookSearchResult) -> Bool {
        shelfKeys.contains(result.id)
            || shelfTitles.contains(Self.titleKey(title: result.title, author: result.author))
    }

    /// Добавляет книгу со статусом «Хочу прочитать». Уже добавленную — повторно не добавляет.
    func add(_ result: BookSearchResult) {
        guard !isOnShelf(result) else { return }
        do {
            try repository.add(OpenLibraryMapper.book(from: result))
            errorMessage = nil
            shelfKeys.insert(result.id)
            shelfTitles.insert(Self.titleKey(title: result.title, author: result.author))
            onAdd()
        } catch {
            errorMessage = "Не удалось добавить книгу. Попробуйте ещё раз."
            loadShelf()
        }
    }

    /// Ключ для сравнения книг без учёта регистра, «ё» и лишних пробелов.
    nonisolated static func titleKey(title: String, author: String) -> String {
        "\(normalized(title))|\(normalized(author))"
    }

    nonisolated static func normalized(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "ё", with: "е")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
