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
    /// Прогресс чтения от 0 до 1. Значение по умолчанию задано в объявлении,
    /// чтобы SwiftData при миграции заполнило им уже сохранённые книги.
    var progress: Double = 0

    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRawValue) ?? .wantToRead }
        set { statusRawValue = newValue.rawValue }
    }

    init(
        title: String,
        author: String,
        coverURL: URL? = nil,
        status: ReadingStatus = .wantToRead,
        progress: Double = 0,
        dateAdded: Date = .now
    ) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.statusRawValue = status.rawValue
        self.progress = Self.clampedProgress(progress)
        self.dateAdded = dateAdded
    }

    /// Приводит прогресс к диапазону 0…1 (NaN считается нулём).
    static func clampedProgress(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
