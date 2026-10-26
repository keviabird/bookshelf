import SwiftUI
import SwiftData

struct BookListView: View {
    @State private var viewModel: BookListViewModel

    init(viewModel: BookListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.books.isEmpty {
                    ContentUnavailableView(
                        "Полка пуста",
                        systemImage: "books.vertical",
                        description: Text("Добавьте первую книгу, чтобы она появилась здесь.")
                    )
                } else {
                    List(viewModel.books) { book in
                        VStack(alignment: .leading) {
                            Text(book.title).font(.headline)
                            Text(book.author).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Книжная полка")
        }
        .task { viewModel.loadBooks() }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Book.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return BookListView(
        viewModel: BookListViewModel(
            repository: SwiftDataBookRepository(context: container.mainContext)
        )
    )
}
