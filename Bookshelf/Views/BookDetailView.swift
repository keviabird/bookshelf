import SwiftUI
import SwiftData

/// Карточка книги (макет Figma «Book Detail»): обложка на тёмном фоне и белый лист
/// с названием, статусом, прогрессом, статистикой и описанием.
struct BookDetailView: View {
    @State private var viewModel: BookDetailViewModel

    init(viewModel: BookDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    cover
                    sheet
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                // Лист тянется до низа экрана, даже если содержимого мало.
                .frame(minHeight: proxy.size.height)
            }
        }
        // Сверху тёмный фон, снизу — цвет листа: так при прокрутке не видно «дыр».
        .background {
            VStack(spacing: 0) {
                Theme.Colors.backgroundDark
                Theme.Colors.surface
            }
            .ignoresSafeArea()
        }
        .shelfNavigationBar(title: "О книге")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Label(
                        viewModel.isFavorite ? "Убрать из избранного" : "Добавить в избранное",
                        systemImage: viewModel.isFavorite ? "bookmark.fill" : "bookmark"
                    )
                    .labelStyle(.iconOnly)
                }
                // Кнопки панели красятся через tint, foregroundStyle они игнорируют.
                .tint(Theme.Colors.accent)
            }
        }
        // Кнопка «назад» на тёмной панели — светлая.
        .tint(Theme.Colors.textOnDark)
        .sheet(isPresented: $viewModel.isUpdatingProgress) {
            UpdateProgressView(viewModel: viewModel)
                .tint(.accentColor)
        }
    }

    private var cover: some View {
        BookCoverView(
            title: viewModel.title,
            coverURL: viewModel.coverURL,
            size: Theme.Metrics.detailCoverSize,
            cornerRadius: Theme.Metrics.detailCoverCornerRadius
        )
        .shadow(color: .black.opacity(0.45), radius: 12, y: 12)
        .accessibilityHidden(true)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.backgroundDark)
    }

    private var sheet: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(viewModel.title)
                    .font(Theme.Fonts.detailTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                if !viewModel.author.isEmpty {
                    Text(viewModel.author)
                        .font(Theme.Fonts.bookAuthor)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            StatusPicker(selected: viewModel.status, onSelect: viewModel.setStatus)

            if viewModel.showsProgress {
                ReadingProgressSection(
                    progress: viewModel.progress,
                    progressText: viewModel.progressText,
                    pagesText: viewModel.pagesText
                )
            }

            HStack(alignment: .top) {
                ForEach(viewModel.stats) { stat in
                    StatView(value: stat.value, label: stat.label)
                }
            }

            if viewModel.hasDescription {
                AboutSection(text: viewModel.bookDescription)
            }

            Spacer(minLength: 24)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if viewModel.showsProgress {
                Button("Обновить прогресс") { viewModel.startUpdatingProgress() }
                    .buttonStyle(.primary)
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity)
        .background(
            Theme.Colors.surface,
            in: UnevenRoundedRectangle(
                topLeadingRadius: Theme.Metrics.detailSheetCornerRadius,
                topTrailingRadius: Theme.Metrics.detailSheetCornerRadius
            )
        )
    }
}

#if DEBUG
#Preview("Читаю") {
    let container = SampleData.makeContainer()
    let book = try! container.mainContext.fetch(FetchDescriptor<Book>()).first { $0.status == .reading }!
    return NavigationStack {
        BookDetailView(viewModel: BookDetailViewModel(
            book: book,
            repository: SwiftDataBookRepository(context: container.mainContext)
        ))
    }
}
#endif

#Preview("Без страниц и описания") {
    let container = try! ModelContainer(for: Book.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let book = Book(title: "Старая книга", author: "Автор")
    container.mainContext.insert(book)
    return NavigationStack {
        BookDetailView(viewModel: BookDetailViewModel(
            book: book,
            repository: SwiftDataBookRepository(context: container.mainContext)
        ))
    }
}
