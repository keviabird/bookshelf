import Foundation

/// Поиск книг во внешнем каталоге. Протокол позволяет подменять сеть в тестах.
/// `nonisolated` + `Sendable`: сервис не привязан к главному актору и вызывается из любой задачи.
nonisolated protocol BookSearchService: Sendable {
    /// Если задачу отменили, может бросить `CancellationError` / `URLError(.cancelled)`.
    func search(_ query: String) async throws -> [BookSearchResult]
}

nonisolated enum BookSearchError: Error, Equatable {
    /// Сервер ответил не 2xx.
    case badStatus(Int)
    /// Не удалось собрать адрес запроса.
    case invalidRequest
}
