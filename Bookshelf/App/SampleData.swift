#if DEBUG
import Foundation
import SwiftData

/// Примеры книг для превью и скриншотов (запуск с аргументом `-seedSampleBooks`).
enum SampleData {
    static let launchArgument = "-seedSampleBooks"

    static func makeBooks() -> [Book] {
        let now = Date.now
        let items: [(String, String, ReadingStatus, Double)] = [
            ("Мастер и Маргарита", "Михаил Булгаков", .reading, 0.02),
            ("Преступление и наказание", "Фёдор Достоевский", .reading, 0.14),
            ("Пикник на обочине", "Аркадий и Борис Стругацкие", .reading, 0.75),
            ("Война и мир", "Лев Толстой", .wantToRead, 0),
            ("Мы", "Евгений Замятин", .finished, 1),
        ]
        // Чем раньше в списке, тем новее: список сортируется по дате добавления.
        return items.enumerated().map { index, item in
            Book(
                title: item.0,
                author: item.1,
                status: item.2,
                progress: item.3,
                dateAdded: now.addingTimeInterval(-Double(index) * 60)
            )
        }
    }

    /// Контейнер в памяти с примерами книг.
    static func makeContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: Book.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            makeBooks().forEach { container.mainContext.insert($0) }
            try container.mainContext.save()
            return container
        } catch {
            fatalError("Could not create sample ModelContainer: \(error)")
        }
    }
}
#endif
