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
                    ContentUnavailableView {
                        Label("Полка пуста", systemImage: "books.vertical")
                    } description: {
                        Text("Добавьте первую книгу, чтобы она появилась здесь.")
                    } actions: {
                        Button("Добавить книгу") { viewModel.isAddingBook = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(viewModel.books) { book in
                        HStack(spacing: 12) {
                            BookCoverView(title: book.title, coverURL: book.coverURL)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title).font(.headline)
                                if !book.author.isEmpty {
                                    Text(book.author).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Text(book.status.title).font(.caption).foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Книжная полка")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isAddingBook = true
                    } label: {
                        Label("Добавить книгу", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isAddingBook) {
                AddBookView(viewModel: viewModel.makeAddBookViewModel()) {
                    viewModel.loadBooks()
                }
            }
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
