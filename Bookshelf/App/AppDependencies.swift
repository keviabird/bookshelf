import Foundation
import SwiftData

/// Зависимости приложения. Единственное место, где по аргументам запуска выбирается,
/// с чем работает приложение: боевые хранилище и сеть, примеры книг или UI-тест.
/// ViewModel и View получают готовые зависимости и про режим запуска не знают.
struct AppDependencies {
    let container: ModelContainer
    let searchService: BookSearchService
    let sortStorage: BookSortStorage

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppDependencies {
        #if DEBUG
        if arguments.contains(AccessibilityID.LaunchArgument.uiTesting) {
            return UITestSupport.dependencies()
        }
        if arguments.contains(SampleData.launchArgument) {
            return AppDependencies(
                container: SampleData.makeContainer(),
                searchService: OpenLibrarySearchService(),
                sortStorage: BookSortStorage()
            )
        }
        #endif
        return live()
    }

    private static func live() -> AppDependencies {
        do {
            return AppDependencies(
                container: try ModelContainer(for: Book.self),
                searchService: OpenLibrarySearchService(),
                sortStorage: BookSortStorage()
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
