import Foundation
import SwiftData

@Model
final class Book {
    var title: String
    var author: String
    var coverURL: URL?
    /// Сырое значение статуса: хранится строкой, чтобы по нему работали #Predicate-фильтры.
    var statusRawValue: String
    var dateAdded: Date

    // У новых полей значения по умолчанию заданы в объявлении,
    // чтобы SwiftData при миграции заполнило ими уже сохранённые книги.

    /// Число страниц; 0 — неизвестно (так у книг, добавленных до появления поля).
    var pageCount: Int = 0
    /// Текущая страница. Меняется только через `setStatus` / `setCurrentPage`.
    var currentPage: Int?
    var publicationYear: Int?
    var bookDescription: String = ""
    var isFavorite: Bool = false
    /// Ключ работы в Open Library, если книга добавлена из поиска. По нему ищутся дубли.
    var openLibraryKey: String?

    var status: ReadingStatus {
        get { ReadingStatus(rawValue: statusRawValue) ?? .wantToRead }
        set { statusRawValue = newValue.rawValue }
    }

    var hasKnownPages: Bool { pageCount > 0 }

    /// Прогресс чтения 0…1. Считается только по страницам; без них — 0.
    var progress: Double {
        guard hasKnownPages, let currentPage else { return 0 }
        return Double(min(max(currentPage, 0), pageCount)) / Double(pageCount)
    }

    init(
        title: String,
        author: String,
        coverURL: URL? = nil,
        status: ReadingStatus = .wantToRead,
        pageCount: Int = 0,
        currentPage: Int? = nil,
        publicationYear: Int? = nil,
        bookDescription: String = "",
        isFavorite: Bool = false,
        openLibraryKey: String? = nil,
        dateAdded: Date = .now
    ) {
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.statusRawValue = status.rawValue
        self.pageCount = max(pageCount, 0)
        self.publicationYear = publicationYear
        self.bookDescription = bookDescription
        self.isFavorite = isFavorite
        self.openLibraryKey = openLibraryKey
        self.dateAdded = dateAdded
        setStatus(status)
        // Текущая страница имеет смысл только для книги, которую читают сейчас.
        if status == .reading {
            setCurrentPage(currentPage)
        }
    }

    // MARK: - Правила статуса и страницы
    // Единственное место, где согласуются статус и текущая страница.
    // Вызывается внутри `BookRepository.update`, чтобы изменение сохранилось.

    /// Смена статуса (чипы, форма добавления):
    /// - «Хочу прочитать» сбрасывает страницу;
    /// - «Прочитано» ставит последнюю страницу, если число страниц известно;
    /// - «Читаю» страницу не трогает.
    func setStatus(_ newStatus: ReadingStatus) {
        switch newStatus {
        case .wantToRead:
            currentPage = nil
        case .reading:
            break
        case .finished:
            if hasKnownPages { currentPage = pageCount }
        }
        status = newStatus
    }

    /// Обновление прогресса (страница ограничивается 0…pageCount), статус подстраивается:
    /// - последняя страница → «Прочитано»;
    /// - страница > 0 у книги «Хочу прочитать» → «Читаю»;
    /// - не последняя страница у прочитанной книги → «Читаю».
    func setCurrentPage(_ newPage: Int?) {
        var page = newPage.map { max($0, 0) }
        if hasKnownPages, let current = page {
            page = min(current, pageCount)
        }
        currentPage = page
        guard let page else { return }

        if hasKnownPages, page == pageCount {
            status = .finished
        } else if status == .finished || (status == .wantToRead && page > 0) {
            status = .reading
        }
    }
}
