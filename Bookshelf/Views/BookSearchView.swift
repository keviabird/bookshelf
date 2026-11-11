import SwiftUI
import SwiftData

/// Поиск книг в Open Library: системное поле поиска и результаты в виде строк полки.
struct BookSearchView: View {
    @State private var viewModel: BookSearchViewModel

    init(viewModel: BookSearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .shelfSheetBackground()
            .shelfNavigationBar(title: "Поиск")
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Название или автор"
            )
            .onAppear { viewModel.loadShelf() }
            .onDisappear { viewModel.cancelSearch() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView {
                Label("Найдите книгу", systemImage: "magnifyingglass")
            } description: {
                Text("Введите название или автора — хотя бы \(BookSearchViewModel.minQueryLength) буквы.")
            }
        case .loading:
            ProgressView("Ищем…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .results(let results):
            resultList(results)
        case .empty:
            // Не `ContentUnavailableView.search`: его текст берётся из локализации приложения,
            // а русской локализации пока нет — было бы «No Results for…».
            ContentUnavailableView {
                Label("Ничего не найдено", systemImage: "magnifyingglass")
            } description: {
                Text("По запросу «\(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines))» книг нет. Проверьте написание или попробуйте другой запрос.")
            }
        case .failed(let message):
            ContentUnavailableView {
                Label(message, systemImage: "wifi.exclamationmark")
            } actions: {
                Button("Повторить") { viewModel.retry() }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private func year(of result: BookSearchResult) -> some View {
        if let year = result.firstPublishYear {
            Text(String(year))
                .font(Theme.Fonts.progress)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private func addButton(for result: BookSearchResult) -> some View {
        AddToShelfButton(isOnShelf: viewModel.isOnShelf(result)) {
            viewModel.add(result)
        }
        // Не сжимать до «На…»: тогда `ViewThatFits` выберет вариант в столбик.
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityIdentifier(AccessibilityID.Search.addButton(result.id))
    }

    private func resultList(_ results: [BookSearchResult]) -> some View {
        List(results) { result in
            BookRowView(title: result.title, author: result.author, coverURL: result.coverURL) {
                // При крупном тексте год и кнопка не влезают в строку — ставим их друг под другом.
                ViewThatFits(in: .horizontal) {
                    HStack {
                        year(of: result)
                        Spacer(minLength: 8)
                        addButton(for: result)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        year(of: result)
                        addButton(for: result)
                    }
                }
                .padding(.bottom, 4)
            }
            .listRowInsets(EdgeInsets(top: 20, leading: 24, bottom: 20, trailing: 24))
            .listRowBackground(Color.clear)
            .alignmentGuide(.listRowSeparatorLeading) { _ in -24 }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .top) {
            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.bar)
            }
        }
    }
}

#if DEBUG
/// Сервис для превью: отдаёт фиксированные результаты без сети.
private struct PreviewSearchService: BookSearchService {
    func search(_ query: String) async throws -> [BookSearchResult] {
        [
            BookSearchResult(id: "/works/1", title: "Мастер и Маргарита", author: "Михаил Булгаков",
                             coverURL: nil, firstPublishYear: 1967, pageCount: 480),
            BookSearchResult(id: "/works/2", title: "Собачье сердце", author: "Михаил Булгаков",
                             coverURL: nil, firstPublishYear: 1987, pageCount: nil),
        ]
    }
}

#Preview {
    let container = SampleData.makeContainer()
    let viewModel = BookSearchViewModel(
        service: PreviewSearchService(),
        repository: SwiftDataBookRepository(context: container.mainContext)
    )
    viewModel.query = "Булгаков"
    return NavigationStack { BookSearchView(viewModel: viewModel) }
}
#endif
