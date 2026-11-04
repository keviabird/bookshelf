import SwiftUI
import SwiftData

/// Главный экран: тёмная шапка и скруглённый лист со сводкой, фильтром и списком книг.
struct BookListView: View {
    @State private var viewModel: BookListViewModel

    init(viewModel: BookListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ShelfHeaderView { viewModel.isAddingBook = true }

                sheetContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: Theme.Metrics.sheetCornerRadius,
                            topTrailingRadius: Theme.Metrics.sheetCornerRadius
                        )
                        .fill(Theme.Colors.sheet)
                        .ignoresSafeArea(edges: .bottom)
                    }
            }
            .background { Theme.Colors.header.ignoresSafeArea() }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.isAddingBook) {
                AddBookView(viewModel: viewModel.makeAddBookViewModel()) {
                    viewModel.loadBooks()
                }
            }
        }
        .task { viewModel.loadBooks() }
    }

    @ViewBuilder
    private var sheetContent: some View {
        if viewModel.books.isEmpty, let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
            } actions: {
                Button("Повторить") { viewModel.loadBooks() }
                    .buttonStyle(.borderedProminent)
            }
        } else if viewModel.books.isEmpty {
            ContentUnavailableView {
                Label("Полка пуста", systemImage: "books.vertical")
            } description: {
                Text("Добавьте первую книгу, чтобы она появилась здесь.")
            } actions: {
                Button("Добавить книгу") { viewModel.isAddingBook = true }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            VStack(spacing: 16) {
                ShelfSummaryView(count: viewModel.totalCount, noun: viewModel.summaryNoun)
                    .padding(.horizontal)
                    .padding(.top, 24)

                StatusFilterBar(
                    totalCount: viewModel.totalCount,
                    isAllSelected: viewModel.isAllSelected,
                    count: viewModel.count(for:),
                    isSelected: viewModel.isSelected(_:),
                    onSelectAll: viewModel.selectAll,
                    onToggle: viewModel.toggle(_:)
                )

                if viewModel.filteredBooks.isEmpty {
                    ContentUnavailableView {
                        Label("Нет книг в выбранных разделах", systemImage: "line.3.horizontal.decrease.circle")
                    } actions: {
                        Button("Показать все") { viewModel.selectAll() }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    bookList
                }
            }
        }
    }

    private var bookList: some View {
        List {
            ForEach(Array(viewModel.filteredBooks.enumerated()), id: \.element.id) { index, book in
                BookRowView(
                    rank: index + 1,
                    title: book.title,
                    author: book.author,
                    coverURL: book.coverURL,
                    progress: book.progress
                )
                .listRowInsets(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
                .listRowBackground(Color.clear)
                // Разделитель на всю ширину, как в макете.
                .alignmentGuide(.listRowSeparatorLeading) { _ in -24 }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top) {
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Spacer()
                    Button("Повторить") { viewModel.loadBooks() }
                }
                .font(.subheadline)
                .padding(12)
                .background(.bar)
            }
        }
    }
}

#Preview("С книгами") {
    let container = SampleData.makeContainer()
    return BookListView(
        viewModel: BookListViewModel(
            repository: SwiftDataBookRepository(context: container.mainContext)
        )
    )
}

#Preview("Пусто") {
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
