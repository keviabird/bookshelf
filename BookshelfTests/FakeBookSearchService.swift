import Foundation
@testable import Bookshelf

/// Сервис поиска для тестов: записывает запросы и отвечает через `handler`.
/// `handler` получает запрос и номер вызова (с нуля), может бросить ошибку или ждать `Gate`.
actor FakeBookSearchService: BookSearchService {
    typealias Handler = @Sendable (_ query: String, _ call: Int) async throws -> [BookSearchResult]

    private(set) var queries: [String] = []
    private let handler: Handler

    init(_ handler: @escaping Handler = { _, _ in [] }) {
        self.handler = handler
    }

    func search(_ query: String) async throws -> [BookSearchResult] {
        let call = queries.count
        queries.append(query)
        return try await handler(query, call)
    }
}

/// Придерживает ответ сервиса, пока тест не вызовет `open()`. На отмену задачи не реагирует —
/// как сервис, который отмену не поддерживает.
actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }
}

/// Записывает длительности, переданные в `sleep`.
actor DurationRecorder {
    private(set) var durations: [Duration] = []

    func record(_ duration: Duration) {
        durations.append(duration)
    }
}

/// Даёт другим задачам поработать, пока условие не выполнится.
func waitUntil(_ condition: () async -> Bool) async {
    for _ in 0..<1_000 {
        if await condition() { return }
        await Task.yield()
    }
}

func searchResult(
    _ id: String,
    title: String = "Мастер и Маргарита",
    author: String = "Михаил Булгаков",
    pageCount: Int? = 480
) -> BookSearchResult {
    BookSearchResult(
        id: id,
        title: title,
        author: author,
        coverURL: URL(string: "https://covers.openlibrary.org/b/id/1-M.jpg?default=false"),
        firstPublishYear: 1967,
        pageCount: pageCount
    )
}
