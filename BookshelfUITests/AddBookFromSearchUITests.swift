import XCTest

/// Сценарий: найти книгу и добавить её на полку.
/// Приложение запускается с `-uiTesting`: пустое хранилище в памяти, поиск отдаёт фиксированные
/// книги без сети (`UITestSupport`). Элементы ищутся только по `AccessibilityID`.
final class AddBookFromSearchUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testBookAddedFromSearchIsOnShelfAsWantToRead() throws {
        let app = XCUIApplication()
        app.launchArguments = [AccessibilityID.LaunchArgument.uiTesting]
        app.launch()

        // Открыть поиск.
        let searchButton = app.buttons[AccessibilityID.Shelf.searchButton]
        XCTAssertTrue(searchButton.waitForExistence(timeout: timeout), "Нет кнопки поиска")
        searchButton.tap()

        // Ввести запрос. У поля `.searchable` нет своего идентификатора — берём по типу элемента.
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: timeout), "Нет поля поиска")
        searchField.tap()
        // Первое нажатие иногда только включает режим поиска, а фокус поле не получает.
        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: timeout) {
            searchField.tap()
        }
        XCTAssertTrue(keyboard.waitForExistence(timeout: timeout), "Поле поиска не получило фокус")
        app.typeText("dune")

        // Добавить первую книгу из результатов.
        let duneID = AccessibilityID.UITestFixture.duneID
        let addButton = app.buttons[AccessibilityID.Search.addButton(duneID)]
        XCTAssertTrue(addButton.waitForExistence(timeout: timeout), "Нет результата «Dune»")
        addButton.tap()

        // Пока поиск активен, вместо «Назад» в панели только системная кнопка закрытия поиска.
        // Идентификатора у неё нет: это единственная кнопка — прямой потомок панели
        // («Очистить» вложена в само поле поиска).
        let closeSearchButton = app.navigationBars.firstMatch.children(matching: .button).firstMatch
        XCTAssertTrue(closeSearchButton.waitForExistence(timeout: timeout), "Нет кнопки закрытия поиска")
        closeSearchButton.tap()

        // Вернуться на полку системной кнопкой «Назад».
        let backButton = app.navigationBars.buttons["BackButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: timeout), "Нет кнопки «Назад»")
        backButton.tap()

        // Книга на полке.
        let bookRow = app.buttons[AccessibilityID.Shelf.bookRow(duneID)]
        XCTAssertTrue(bookRow.waitForExistence(timeout: timeout), "Книги нет на полке")

        // Статус «Хочу прочитать»: книга видна при фильтре только по этому статусу.
        let wantToReadChip = app.buttons[AccessibilityID.Shelf.filterChip("wantToRead")]
        XCTAssertTrue(wantToReadChip.waitForExistence(timeout: timeout), "Нет фильтра «Хочу прочитать»")
        wantToReadChip.tap()
        XCTAssertTrue(bookRow.exists, "Книги нет среди «Хочу прочитать»")
    }
}
