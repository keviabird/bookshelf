import Foundation

/// Ответ `https://openlibrary.org/search.json`. Повторяет поля API как есть;
/// в модели приложения превращается только в `OpenLibraryMapper`.
nonisolated struct OpenLibrarySearchResponseDTO: Decodable, Sendable {
    let docs: [OpenLibraryDocDTO]
}

nonisolated struct OpenLibraryDocDTO: Decodable, Sendable {
    let key: String
    let title: String?
    let authorName: [String]?
    let coverID: Int?
    let firstPublishYear: Int?
    let numberOfPagesMedian: Int?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authorName = "author_name"
        case coverID = "cover_i"
        case firstPublishYear = "first_publish_year"
        case numberOfPagesMedian = "number_of_pages_median"
    }
}
