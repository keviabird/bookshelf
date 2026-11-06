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

    // MARK: - Неполные документы

    /// Документ «ключ + название» плюс одно поле. Всё, чего нет в `fields`, ожидается пустым.
    struct PartialDoc: Sendable, CustomTestStringConvertible {
        let name: String
        let fields: String
        var coverURL: URL? = nil
        var author = ""
        var year: Int? = nil
        var pageCount: Int? = nil

        var testDescription: String { name }
    }

    @Test(arguments: [
        PartialDoc(name: "только ключ и название", fields: ""),
        PartialDoc(name: "без обложки, но с годом", fields: #", "first_publish_year": 1928"#, year: 1928),
        PartialDoc(name: "обложка 0", fields: #", "cover_i": 0"#),
        PartialDoc(name: "обложка -1", fields: #", "cover_i": -1"#),
        PartialDoc(name: "есть обложка", fields: #", "cover_i": 42"#,
                   coverURL: URL(string: "https://covers.openlibrary.org/b/id/42-M.jpg?default=false")),
        PartialDoc(name: "пустой список авторов", fields: #", "author_name": []"#),
        PartialDoc(name: "авторы из пробелов", fields: #", "author_name": ["  ", ""]"#),
        PartialDoc(name: "автор с пробелами по краям", fields: #", "author_name": ["  Илья Ильф "]"#, author: "Илья Ильф"),
        PartialDoc(name: "два автора", fields: #", "author_name": ["Илья Ильф", "Евгений Петров"]"#,
                   author: "Илья Ильф, Евгений Петров"),
        PartialDoc(name: "0 страниц", fields: #", "number_of_pages_median": 0"#),
        PartialDoc(name: "отрицательные страницы", fields: #", "number_of_pages_median": -10"#),
        PartialDoc(name: "есть страницы", fields: #", "number_of_pages_median": 250"#, pageCount: 250),
    ])
    func mapsPartialDocuments(doc: PartialDoc) throws {
        let json = #"{"docs": [{"key": "/works/X", "title": "Книга""# + doc.fields + "}]}"
        let response = try JSONDecoder().decode(OpenLibrarySearchResponseDTO.self, from: Data(json.utf8))

        let result = try #require(OpenLibraryMapper.results(from: response).first)

        #expect(result.id == "/works/X")
        #expect(result.title == "Книга")
        #expect(result.coverURL == doc.coverURL)
        #expect(result.author == doc.author)
        #expect(result.firstPublishYear == doc.year)
        #expect(result.pageCount == doc.pageCount)
    }

    @Test(arguments: [nil, "", "   ", "\n"] as [String?])
    func skipsDocumentsWithoutTitle(title: String?) throws {
        let titleField = title.map { #", "title": "# + "\(String(reflecting: $0))" } ?? ""
        let json = #"{"docs": [{"key": "/works/X""# + titleField + "}]}"
        let response = try JSONDecoder().decode(OpenLibrarySearchResponseDTO.self, from: Data(json.utf8))

        #expect(OpenLibraryMapper.results(from: response).isEmpty)
    }

    @Test func emptyDocsGiveNoResults() throws {
        let response = try JSONDecoder().decode(OpenLibrarySearchResponseDTO.self, from: Data(#"{"numFound": 0, "docs": []}"#.utf8))

        #expect(OpenLibraryMapper.results(from: response).isEmpty)
    }

    @Test(arguments: [#"{"numFound": 0}"#, #"{"docs": [{"title": "Без ключа"}]}"#, "<html>502</html>"])
    func malformedResponseFailsToDecode(json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OpenLibrarySearchResponseDTO.self, from: Data(json.utf8))
        }
    }

    // MARK: - DTO → Book

    /// Вся цепочка для «голого» документа: без обложки, автора, года и страниц.
    @MainActor
    @Test func bareDocumentBecomesWantToReadBook() throws {
        let json = #"{"docs": [{"key": "/works/OL9W", "title": "Мы"}]}"#
        let response = try JSONDecoder().decode(OpenLibrarySearchResponseDTO.self, from: Data(json.utf8))
        let result = try #require(OpenLibraryMapper.results(from: response).first)

        let book = OpenLibraryMapper.book(from: result)

        #expect(book.title == "Мы")
        #expect(book.author == "")
        #expect(book.coverURL == nil)
        #expect(book.publicationYear == nil)
        #expect(book.pageCount == 0)
        #expect(!book.hasKnownPages)
        #expect(book.status == .wantToRead)
        #expect(book.currentPage == nil)
        #expect(book.openLibraryKey == "/works/OL9W")
    }

    /// Книга из поиска сохраняется в SwiftData и читается обратно с теми же полями.
    @MainActor
    @Test func mappedBookSurvivesSwiftDataRoundTrip() throws {
        let store = try TestStore()
        let result = searchResult("/works/OL1W", pageCount: nil)

        try store.repository.add(OpenLibraryMapper.book(from: result))

        let saved = try #require(try store.persistedBooks().first)
        #expect(saved.title == result.title)
        #expect(saved.author == result.author)
        #expect(saved.coverURL == result.coverURL)
        #expect(saved.publicationYear == result.firstPublishYear)
        #expect(saved.pageCount == 0)
        #expect(saved.status == .wantToRead)
        #expect(saved.openLibraryKey == "/works/OL1W")
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
