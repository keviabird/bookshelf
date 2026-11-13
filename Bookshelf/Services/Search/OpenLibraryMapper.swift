import Foundation

/// Единственное место, где данные Open Library превращаются в модели приложения.
nonisolated enum OpenLibraryMapper {
    static func results(from response: OpenLibrarySearchResponseDTO) -> [BookSearchResult] {
        response.docs.compactMap(result(from:))
    }

    /// nil — у документа нет названия, показывать нечего.
    static func result(from doc: OpenLibraryDocDTO) -> BookSearchResult? {
        guard let title = doc.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
            return nil
        }
        let authors = (doc.authorName ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return BookSearchResult(
            id: doc.key,
            title: title,
            author: authors.joined(separator: ", "),
            coverURL: doc.coverID.flatMap(coverURL(id:)),
            firstPublishYear: doc.firstPublishYear,
            pageCount: doc.numberOfPagesMedian.flatMap { $0 > 0 ? $0 : nil }
        )
    }

    /// `default=false`: без обложки сервер отвечает 404, и показывается наша заглушка,
    /// а не пустая картинка.
    static func coverURL(id: Int) -> URL? {
        guard id > 0 else { return nil }
        return URL(string: "https://covers.openlibrary.org/b/id/\(id)-M.jpg?default=false")
    }

    /// Книга для полки: всегда «Хочу прочитать».
    @MainActor
    static func book(from result: BookSearchResult) -> Book {
        Book(
            title: result.title,
            author: result.author,
            coverURL: result.coverURL,
            status: .wantToRead,
            pageCount: result.pageCount ?? 0,
            publicationYear: result.firstPublishYear,
            openLibraryKey: result.id
        )
    }
}
