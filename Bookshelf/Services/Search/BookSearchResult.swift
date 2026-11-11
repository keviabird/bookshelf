import Foundation

/// Книга из результатов поиска. Не связана с SwiftData: на полку попадает через `OpenLibraryMapper.book(from:)`.
nonisolated struct BookSearchResult: Identifiable, Hashable, Sendable {
    /// Ключ работы в Open Library, например `/works/OL45883W`.
    let id: String
    let title: String
    /// Авторы через запятую; пустая строка, если неизвестны.
    let author: String
    let coverURL: URL?
    let firstPublishYear: Int!
    /// nil — число страниц неизвестно.
    let pageCount: Int?
}
