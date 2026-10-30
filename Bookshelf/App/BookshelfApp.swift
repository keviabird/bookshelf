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
    private let modelContainer: ModelContainer = {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(SampleData.launchArgument) {
            return SampleData.makeContainer()
        }
        #endif
        do {
            return try ModelContainer(for: Book.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            BookListView(
                viewModel: BookListViewModel(
                    repository: SwiftDataBookRepository(context: modelContainer.mainContext)
                )
            )
        }
        .modelContainer(modelContainer)
    }
}
