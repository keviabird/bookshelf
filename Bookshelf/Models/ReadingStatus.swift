import Foundation

/// Статус чтения книги.
enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case wantToRead
    case reading
    case finished

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wantToRead: "Хочу прочитать"
        case .reading: "Читаю"
        case .finished: "Прочитано"
        }
    }
}
