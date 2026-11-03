import Foundation
import Observation

/// Карточка книги: показ данных, смена статуса, избранное и обновление прогресса.
@Observable
@MainActor
final class BookDetailViewModel {
    /// Колонка статистики: «498 / страниц».
    struct Stat: Identifiable, Equatable {
        let value: String
        let label: String
        var id: String { label }
    }

    private(set) var errorMessage: String?
    var isUpdatingProgress = false
    /// Страница в sheet «Обновить прогресс» до сохранения.
    var draftPage = 0

    private let book: Book
    private let repository: BookRepository
    /// Вызывается после каждого успешного изменения — список перезагружает данные.
    private let onChange: () -> Void

    init(book: Book, repository: BookRepository, onChange: @escaping () -> Void = {}) {
        self.book = book
        self.repository = repository
        self.onChange = onChange
    }

    // MARK: - Данные для экрана

    var title: String { book.title }
    var author: String { book.author }
    var coverURL: URL? { book.coverURL }
    var status: ReadingStatus { book.status }
    var isFavorite: Bool { book.isFavorite }
    var progress: Double { book.progress }
    var progressText: String { ReadingFormat.percent(book.progress) }

    /// Блок прогресса и кнопка «Обновить прогресс» — только если известно число страниц.
    var showsProgress: Bool { book.hasKnownPages }

    var pagesText: String? {
        guard book.hasKnownPages else { return nil }
        return ReadingFormat.pages(current: book.currentPage ?? 0, total: book.pageCount)
    }

    /// Колонки статистики; колонки без данных пропускаются, дата добавления есть всегда.
    var stats: [Stat] {
        var result: [Stat] = []
        if book.hasKnownPages {
            let noun = RussianPlural.form(for: book.pageCount, one: "страница", few: "страницы", many: "страниц")
            result.append(Stat(value: "\(book.pageCount)", label: noun))
        }
        if let year = book.publicationYear {
            result.append(Stat(value: "\(year)", label: "год"))
        }
        result.append(Stat(value: Self.dayMonthFormatter.string(from: book.dateAdded), label: "добавлена"))
        return result
    }

    var bookDescription: String {
        book.bookDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasDescription: Bool { !bookDescription.isEmpty }

    private static let dayMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "dd.MM"
        return formatter
    }()

    // MARK: - Действия

    func setStatus(_ newStatus: ReadingStatus) {
        guard newStatus != book.status else { return }
        perform { $0.setStatus(newStatus) }
    }

    func toggleFavorite() {
        perform { $0.isFavorite.toggle() }
    }

    // MARK: - Обновление прогресса

    var draftPageRange: ClosedRange<Int> { 0...max(book.pageCount, 0) }

    var draftPagesText: String {
        ReadingFormat.pages(current: draftPage, total: book.pageCount)
    }

    var draftProgressText: String {
        guard book.hasKnownPages else { return ReadingFormat.percent(0) }
        return ReadingFormat.percent(Double(draftPage) / Double(book.pageCount))
    }

    func startUpdatingProgress() {
        guard book.hasKnownPages else { return }
        draftPage = book.currentPage ?? 0
        isUpdatingProgress = true
    }

    /// Сохраняет страницу; статус подстраивает модель (последняя страница → «Прочитано» и т. д.).
    @discardableResult
    func saveProgress() -> Bool {
        let page = min(max(draftPage, draftPageRange.lowerBound), draftPageRange.upperBound)
        guard perform({ $0.setCurrentPage(page) }) else { return false }
        isUpdatingProgress = false
        return true
    }

    /// Изменения — только через репозиторий; при ошибке он откатывает их сам.
    @discardableResult
    private func perform(_ change: (Book) -> Void) -> Bool {
        do {
            try repository.update(book, change)
            errorMessage = nil
            onChange()
            return true
        } catch {
            errorMessage = "Не удалось сохранить изменения. Попробуйте ещё раз."
            return false
        }
    }
}
