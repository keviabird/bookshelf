import Foundation
import SwiftData
@testable import Bookshelf

/// Настоящий `SwiftDataBookRepository` на базе в памяти. `failSaves` заставляет `save()` упасть —
/// уже после того, как изменение применено к контексту, то есть посередине операции.
@MainActor
final class TestStore {
    struct SaveError: Error {}

    /// Ссылочный флаг: замыкание `save` в репозитории читает его при каждом сохранении.
    private final class Switch {
        var failSaves = false
        var saveAttempts = 0
    }

    let container: ModelContainer
    let context: ModelContext
    let repository: SwiftDataBookRepository
    private let saveSwitch = Switch()

    var failSaves: Bool {
        get { saveSwitch.failSaves }
        set { saveSwitch.failSaves = newValue }
    }

    var saveAttempts: Int { saveSwitch.saveAttempts }

    init() throws {
        container = try ModelContainer(
            for: Book.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = ModelContext(container)
        let saveSwitch = saveSwitch
        repository = SwiftDataBookRepository(context: context) { context in
            saveSwitch.saveAttempts += 1
            if saveSwitch.failSaves { throw SaveError() }
            try context.save()
        }
    }

    /// Что действительно сохранено: читаем через новый контекст, а не из кэша рабочего.
    func persistedBooks() throws -> [Book] {
        try ModelContext(container).fetch(
            FetchDescriptor<Book>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
        )
    }
}

/// Пустой набор UserDefaults для одного теста: тесты не читают и не портят настройки приложения.
func makeIsolatedDefaults() -> UserDefaults {
    let name = "BookshelfTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return defaults
}

/// Дата «N дней назад» от фиксированного момента — чтобы порядок книг не зависел от времени запуска.
func daysAgo(_ days: Int) -> Date {
    Date(timeIntervalSinceReferenceDate: 800_000_000).addingTimeInterval(-Double(days) * 86_400)
}
