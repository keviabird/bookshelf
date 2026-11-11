import SwiftUI
import SwiftData

/// Главный экран: тёмная шапка и скруглённый лист со сводкой, фильтром и списком книг.
struct BookListView: View {
    /// Экраны, которые открываются из списка.
    enum Route: Hashable {
        case book(Book)
        case search
    }

    @State private var viewModel: BookListViewModel
    @State private var path: [Route] = []

    init(viewModel: BookListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack(path: $path) {
            sheetContent
                .shelfSheetBackground()
                // Справа две кнопки — заголовок осознанно слева, сразу после лупы.
                .shelfNavigationBar(title: nil)
                .toolbar {
                    // Кнопки панели красятся через tint, foregroundStyle они игнорируют.
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            path.append(.search)
                        } label: {
                            Label("Найти книгу", systemImage: "magnifyingglass")
                                .labelStyle(.iconOnly)
                        }
                        .tint(Theme.Colors.accent)
                    }
                    ShelfLeadingTitle("Книжная полка")
                    ToolbarItem(placement: .topBarTrailing) {
                        BookSortMenu(sort: $viewModel.sort)
                            .tint(Theme.Colors.accent)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.isAddingBook = true
                        } label: {
                            Label("Добавить книгу", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        }
                        .tint(Theme.Colors.accent)
                    }
                }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .book(let book):
                    BookDetailView(viewModel: viewModel.makeDetailViewModel(for: book))
                case .search:
                    BookSearchView(viewModel: viewModel.makeSearchViewModel())
                }
            }
            .sheet(isPresented: $viewModel.isAddingBook) {
                AddBookView(viewModel: viewModel.makeAddBookViewModel()) {
                    viewModel.loadBooks()
                }
            }
        }
        .task {
            viewModel.loadBooks()
            #if DEBUG
            // Для скриншотов: сразу открыть карточку книги по индексу или поиск.
            if let index = SampleData.openBookIndex, path.isEmpty,
               viewModel.filteredBooks.indices.contains(index) {
                path = [.book(viewModel.filteredBooks[index])]
            } else if SampleData.searchQuery != nil, path.isEmpty {
                path = [.search]
            }
            #endif
        }
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
                // Кнопка, а не NavigationLink: так у строки нет системной стрелки.
                Button {
                    path.append(.book(book))
                } label: {
                    BookRowView(
                        rank: index + 1,
                        title: book.title,
                        author: book.author,
                        coverURL: book.coverURL,
                        progress: book.hasKnownPages ? book.progress : nil
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Открыть карточку книги")
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

#if DEBUG
#Preview("С книгами") {
    let container = SampleData.makeContainer()
    return BookListView(
        viewModel: BookListViewModel(
            repository: SwiftDataBookRepository(context: container.mainContext)
        )
    )
}
#endif

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
