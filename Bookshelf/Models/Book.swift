import Foundation
import SwiftData

@Model
final class Book {
    var title: String
    var author: String
    var coverURL: URL?
    /// Сырое значение статуса: хранится строкой, чтобы по нему работали #Predicate-фильтры.
    var statusRawValue: String
    var dateAdded: Date

    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRawValue) ?? .wantToRead }
        set { statusRawValue = newValue.rawValue }
    }

    init(
        title: String,
        author: String,
        coverURL: URL? = nil,
        status: ReadingStatus = .wantToRead,
        dateAdded: Date = .now
    ) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.statusRawValue = status.rawValue
        self.dateAdded = dateAdded
    }
}
