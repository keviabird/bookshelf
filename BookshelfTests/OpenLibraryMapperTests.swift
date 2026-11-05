import Foundation
import Testing
@testable import Bookshelf

struct OpenLibraryMapperTests {
    /// Фрагмент настоящего ответа search.json (лишние поля API тоже должны игнорироваться).
    private let json = """
    {
      "numFound": 3,
      "docs": [
        {
          "key": "/works/OL676009W",
          "title": "Мастер и Маргарита",
          "author_name": ["Михаил Булгаков"],
          "cover_i": 8231856,
          "first_publish_year": 1967,
          "number_of_pages_median": 384,
          "language": ["rus"]
        },
        {
          "key": "/works/OL2W",
          "title": "  Двенадцать стульев ",
          "author_name": ["Илья Ильф", " ", "Евгений Петров"],
          "number_of_pages_median": 0
        },
        { "key": "/works/OL3W" }
      ]
    }
    """

    private func decodeResults() throws -> [BookSearchResult] {
        let dto = try JSONDecoder().decode(OpenLibrarySearchResponseDTO.self, from: Data(json.utf8))
        return OpenLibraryMapper.results(from: dto)
    }

    @Test func mapsFullDocument() throws {
        let result = try #require(try decodeResults().first)

        #expect(result.id == "/works/OL676009W")
        #expect(result.title == "Мастер и Маргарита")
        #expect(result.author == "Михаил Булгаков")
        #expect(result.coverURL == URL(string: "https://covers.openlibrary.org/b/id/8231856-M.jpg?default=false"))
        #expect(result.firstPublishYear == 1967)
        #expect(result.pageCount == 384)
    }

    @Test func mapsPartialDocument() throws {
        let result = try decodeResults()[1]

        #expect(result.title == "Двенадцать стульев")
        #expect(result.author == "Илья Ильф, Евгений Петров")
        #expect(result.coverURL == nil)
        #expect(result.firstPublishYear == nil)
        // 0 страниц у Open Library значит «неизвестно».
        #expect(result.pageCount == nil)
    }

    @Test func skipsDocumentWithoutTitle() throws {
        #expect(try decodeResults().map(\.id) == ["/works/OL676009W", "/works/OL2W"])
    }

    @Test func ignoresInvalidCoverID() {
        #expect(OpenLibraryMapper.coverURL(id: 0) == nil)
        #expect(OpenLibraryMapper.coverURL(id: -1) == nil)
    }

    @MainActor
    @Test func bookFromResultWantsToRead() {
        let result = BookSearchResult(
            id: "/works/OL2W", title: "Двенадцать стульев", author: "Илья Ильф, Евгений Петров",
            coverURL: nil, firstPublishYear: nil, pageCount: nil
        )

        let book = OpenLibraryMapper.book(from: result)

        #expect(book.status == .wantToRead)
        #expect(book.openLibraryKey == "/works/OL2W")
        #expect(book.pageCount == 0)
        #expect(book.currentPage == nil)
        #expect(book.publicationYear == nil)
    }
}

struct OpenLibrarySearchServiceTests {
    @Test func buildsSearchRequest() throws {
        let request = OpenLibrarySearchService.makeRequest(query: "мастер и маргарита")
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })

        #expect(components.scheme == "https")
        #expect(components.host == "openlibrary.org")
        #expect(components.path == "/search.json")
        #expect(items["q"] == "мастер и маргарита")
        #expect(items["fields"] == "key,title,author_name,cover_i,first_publish_year,number_of_pages_median")
        #expect(items["limit"] == "20")
        // Кириллица и пробелы в адресе экранированы.
        #expect(url.absoluteString.contains("q=%D0%BC%D0%B0%D1%81%D1%82%D0%B5%D1%80%20%D0%B8"))
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "Bookshelf/1.0 (iOS)")
    }

    @Test func escapesReservedCharacters() throws {
        let url = try #require(OpenLibrarySearchService.makeRequest(query: "C&A #1").url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.queryItems?.first { $0.name == "q" }?.value == "C&A #1")
    }
}
