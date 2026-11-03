#if DEBUG
import Foundation
import SwiftData

/// Примеры книг для превью и скриншотов.
/// `-seedSampleBooks` — запуск с этими книгами в памяти; `-openFirstBook` — сразу открыть карточку первой.
enum SampleData {
    static let launchArgument = "-seedSampleBooks"
    static let openFirstBookArgument = "-openFirstBook"

    static func makeBooks() -> [Book] {
        let now = Date.now
        // Чем раньше в списке, тем новее: список сортируется по дате добавления.
        func added(_ index: Int) -> Date { now.addingTimeInterval(-Double(index) * 86_400) }
        return [
            Book(
                title: "Мастер и Маргарита",
                author: "Михаил Булгаков",
                status: .reading,
                pageCount: 498,
                currentPage: 210,
                publicationYear: 1967,
                bookDescription: "Воланд со свитой приезжает в Москву 1930-х, а Мастер пишет роман о Понтии Пилате. Сатира, мистика и история любви в одной книге.",
                isFavorite: true,
                dateAdded: added(0)
            ),
            Book(
                title: "Преступление и наказание",
                author: "Фёдор Достоевский",
                status: .reading,
                pageCount: 608,
                currentPage: 85,
                publicationYear: 1866,
                dateAdded: added(1)
            ),
            // Старая книга: добавлена до появления числа страниц.
            Book(title: "Пикник на обочине", author: "Аркадий и Борис Стругацкие", status: .reading, dateAdded: added(2)),
            Book(title: "Война и мир", author: "Лев Толстой", status: .wantToRead, pageCount: 1274, dateAdded: added(3)),
            Book(
                title: "Мы",
                author: "Евгений Замятин",
                status: .finished,
                pageCount: 224,
                publicationYear: 1924,
                bookDescription: "Антиутопия о Едином Государстве, где у людей вместо имён номера, а жизнь расписана по Часовой Скрижали.",
                dateAdded: added(4)
            ),
        ]
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
