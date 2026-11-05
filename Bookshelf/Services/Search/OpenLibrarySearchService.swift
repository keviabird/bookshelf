import Foundation

/// Поиск через Open Library Search API: https://openlibrary.org/dev/docs/api/search
nonisolated struct OpenLibrarySearchService: BookSearchService {
    static let endpoint = URL(string: "https://openlibrary.org/search.json")!
    static let fields = ["key", "title", "author_name", "cover_i", "first_publish_year", "number_of_pages_median"]
    static let limit = 20

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// `@concurrent`: запрос и декодирование JSON идут вне главного потока.
    @concurrent
    func search(_ query: String) async throws -> [BookSearchResult] {
        let (data, response) = try await session.data(for: Self.makeRequest(query: query))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw BookSearchError.badStatus(http.statusCode)
        }
        let dto = try JSONDecoder().decode(OpenLibrarySearchResponseDTO.self, from: data)
        return OpenLibraryMapper.results(from: dto)
    }

    static func makeRequest(query: String) -> URLRequest {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        // `queryItems` не экранирует «&», «=» и «+» в значениях: «C&A» ушло бы как `q=C`,
        // а «+» сервер прочитал бы как пробел. Поэтому значения экранируются вручную.
        components.percentEncodedQueryItems = [
            ("q", query),
            ("fields", fields.joined(separator: ",")),
            ("limit", String(limit)),
        ].map { URLQueryItem(name: $0.0, value: encodeQueryValue($0.1)) }
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        // Open Library просит указывать приложение в User-Agent.
        request.setValue("Bookshelf/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        return request
    }

    private static let queryValueAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+?#"))

    private static func encodeQueryValue(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: queryValueAllowed) ?? value
    }
}
