import Foundation
import Observation

@Observable
@MainActor
final class AddBookViewModel {
    var title = ""
    var author = ""
    var coverURLString = ""
    var status: ReadingStatus = .wantToRead
    var pageCountText = ""
    /// Текущая страница; учитывается только для статуса «Читаю».
    var currentPageText = ""
    var yearText = ""
    var bookDescription = ""
    private(set) var errorMessage: String?

    private let repository: BookRepository
    private let currentYear: Int

    init(repository: BookRepository, currentYear: Int = Calendar.current.component(.year, from: .now)) {
        self.repository = repository
        self.currentYear = currentYear
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedTitle: String { trimmed(title) }
    private var trimmedAuthor: String { trimmed(author) }
    private var trimmedCoverURL: String { trimmed(coverURLString) }

    // MARK: - Обложка и автор

    /// Корректный URL обложки или nil, если поле пустое либо адрес неверный.
    var coverURL: URL? {
        guard let url = URL(string: trimmedCoverURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil
        else { return nil }
        return url
    }

    /// Поле обложки необязательное, но если заполнено — адрес должен быть корректным.
    var isCoverURLValid: Bool {
        trimmedCoverURL.isEmpty || coverURL != nil
    }

    /// Автор необязателен, но если указан — не должен начинаться с цифры.
    var isAuthorValid: Bool {
        guard let first = trimmedAuthor.first else { return true }
        return !first.isWholeNumber
    }

    // MARK: - Страницы и год

    /// Число страниц обязательно для «Читаю» и «Прочитано»: по нему считается прогресс.
    var isPageCountRequired: Bool { status != .wantToRead }

    /// Введённое число страниц, если оно корректно.
    var pageCount: Int? {
        guard let value = Int(trimmed(pageCountText)), value > 0 else { return nil }
        return value
    }

    var isPageCountValid: Bool {
        trimmed(pageCountText).isEmpty ? !isPageCountRequired : pageCount != nil
    }

    /// Поле текущей страницы показывается только для книг, которые читаются сейчас.
    var showsCurrentPage: Bool { status == .reading }

    /// Введённая текущая страница, если она корректна.
    var currentPage: Int? {
        guard let value = Int(trimmed(currentPageText)), value >= 0 else { return nil }
        if let pageCount, value > pageCount { return nil }
        return value
    }

    var isCurrentPageValid: Bool {
        !showsCurrentPage || trimmed(currentPageText).isEmpty || currentPage != nil
    }

    var publicationYear: Int? {
        guard let value = Int(trimmed(yearText)), (1...currentYear).contains(value) else { return nil }
        return value
    }

    var isYearValid: Bool {
        trimmed(yearText).isEmpty || publicationYear != nil
    }

    /// Процент по введённым страницам — показывается рядом с полем текущей страницы.
    var computedProgressText: String? {
        guard showsCurrentPage, let pageCount, let currentPage else { return nil }
        return ReadingFormat.percent(Double(currentPage) / Double(pageCount))
    }

    // MARK: - Подсказки об ошибках (только для заполненных полей)

    var pageCountError: String? {
        guard !trimmed(pageCountText).isEmpty, pageCount == nil else { return nil }
        return "Введите число страниц больше нуля"
    }

    var currentPageError: String? {
        guard showsCurrentPage, !trimmed(currentPageText).isEmpty, currentPage == nil else { return nil }
        if let pageCount { return "Страница должна быть от 0 до \(pageCount)" }
        return "Введите номер страницы"
    }

    var yearError: String? {
        guard !isYearValid else { return nil }
        return "Введите год от 1 до \(currentYear)"
    }

    // MARK: - Сохранение

    /// Обязательно название, а для «Читаю» и «Прочитано» — ещё число страниц.
    var canSave: Bool {
        !trimmedTitle.isEmpty
            && isAuthorValid
            && isCoverURLValid
            && isPageCountValid
            && isCurrentPageValid
            && isYearValid
    }

    /// Сохраняет книгу. Возвращает true при успехе.
    /// Правила статуса и страницы (например, «Прочитано» → последняя страница) применяет модель.
    @discardableResult
    func save() -> Bool {
        guard canSave else { return false }
        let book = Book(
            title: trimmedTitle,
            author: trimmedAuthor,
            coverURL: coverURL,
            status: status,
            pageCount: pageCount ?? 0,
            currentPage: showsCurrentPage ? currentPage : nil,
            publicationYear: publicationYear,
            bookDescription: trimmed(bookDescription)
        )
        do {
            try repository.add(book)
            errorMessage = nil
            return true
        } catch {
            errorMessage = "Не удалось сохранить книгу. Попробуйте ещё раз."
            return false
        }
    }
}
