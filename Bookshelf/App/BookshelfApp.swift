//
//  BookshelfApp.swift
//  Bookshelf
//
//  Created by Elena Gracheva on 26.10.2026.
//

import SwiftUI
import SwiftData

@main
struct BookshelfApp: App {
    /// Режим запуска (боевой, примеры книг, UI-тест) выбирается только в `AppDependencies`.
    private let dependencies = AppDependencies.make()

    var body: some Scene {
        WindowGroup {
            BookListView(
                viewModel: BookListViewModel(
                    repository: SwiftDataBookRepository(context: dependencies.container.mainContext),
                    searchService: dependencies.searchService,
                    sortStorage: dependencies.sortStorage
                )
            )
        }
        .modelContainer(dependencies.container)
    }
}
