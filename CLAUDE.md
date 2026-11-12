# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

«Книжная полка» — iOS app on SwiftUI + SwiftData. Deployment target is **iOS 17.0** (built with Xcode 27), so APIs newer than iOS 17 need `if #available` checks. UI strings are in Russian.

## Правила проекта

- iOS 17+, только SwiftUI, без UIKit
- Архитектура MVVM: View не обращается к SwiftData напрямую, только через ViewModel
- ViewModel помечены `@Observable` и `@MainActor`
- Тесты: Swift Testing (не XCTest) для логики
- Не добавлять сторонние зависимости без согласования
- Модели SwiftData меняются только через `BookRepository`, и каждая операция сразу вызывает `save()`. Никаких изменений моделей напрямую из View/биндингов: при ошибке сохранения репозиторий делает `context.rollback()`, который отменяет **все** несохранённые изменения в контексте. `rollback()` не возвращает старые значения в уже загруженные объекты — репозиторий после него перечитывает книги из базы (`SwiftDataWriteFailureTests`)
- После ошибки записи ViewModel перезагружает данные из репозитория, чтобы состояние в памяти совпало с хранилищем
- Прогресс чтения вычисляется только по страницам (`currentPage / pageCount`), не хранится. Статус и текущую страницу менять только через `Book.setStatus` / `Book.setCurrentPage` внутри `repository.update { … }` — там все правила (например, «Прочитано» → последняя страница)
- Сеть — только через протокол `BookSearchService`; DTO Open Library не выходят за пределы `Services/Search/`, маппинг DTO → `BookSearchResult` → `Book` только в `OpenLibraryMapper`
- Включён `SWIFT_STRICT_CONCURRENCY = complete`: сборка без предупреждений. Типы без состояния UI (DTO, результаты поиска, сервисы, чистые функции) помечать `nonisolated` и `Sendable`, сетевую работу — `@concurrent`

## Commands

No SPM dependencies, no linter configured.

```sh
# Build app + test targets (no simulator needed)
xcodebuild -project Bookshelf.xcodeproj -scheme Bookshelf \
  -destination 'generic/platform=iOS Simulator' build-for-testing

# Run unit tests
xcodebuild -project Bookshelf.xcodeproj -scheme Bookshelf \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:BookshelfTests test

# Run one suite (after changing logic)
xcodebuild -project Bookshelf.xcodeproj -scheme Bookshelf \
  -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:BookshelfTests/BookSortTests test

# Run a single test (Swift Testing: Target/Suite/testFunction())
xcodebuild -project Bookshelf.xcodeproj -scheme Bookshelf \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:'BookshelfTests/AddBookViewModelTests/savesTrimmedBook()' test
```

Simulator notes:
- Use the **iPhone 17** simulator (iOS 27.2, Xcode 27.2): all unit tests pass on it. Passing it by name works; the `id=` workaround is no longer needed.
- iOS 27.2 is the only installed runtime: the old iOS 26.5 and 16.4 runtimes are unavailable. After an Xcode update, check `xcrun simctl list devices available` (don't truncate the output) and `xcodebuild -showdestinations`.
- Parallel testing is off in the shared scheme (`parallelizable = "NO"`): otherwise Xcode boots a fresh simulator clone for every run, which takes ~6.5 minutes on iOS 27.2. Swift Testing still runs tests in parallel inside one process. Don't turn it back on.
- A full run of `BookshelfTests` takes about 1 minute (the tests themselves ~2 s; the first run after the simulator was shut down ~2 minutes). In this mode the log counts a parameterized test once ("164 tests"), not per argument.

## Architecture

MVVM with a repository layer:

- `Models/` — SwiftData `@Model` classes. `Book.status` is a computed wrapper over the stored `statusRawValue: String` so that `#Predicate` can filter by status; keep enums stored as raw strings.
- `Services/` — `BookRepository` protocol (`fetchBooks`, `add`, `delete`, `update(book) { change }`) + `SwiftDataBookRepository` (wraps `ModelContext`, calls `save()` after each mutation and `rollback()` if the save fails — see the rule above).
- `Services/Search/` — `BookSearchService` protocol + `OpenLibrarySearchService` (`search.json`, async/await, `URLSession`), DTOs, `BookSearchResult`, `OpenLibraryMapper`. `BookSearchViewModel` debounces input by cancelling the previous `Task` (300 ms, injectable `sleep` for tests); duplicates are checked by `Book.openLibraryKey` or normalized title + author.
- `ViewModels/` — `@Observable` classes that depend only on `BookRepository`, never on `ModelContext` or `@Query`.
- Sorting the shelf: `BookSort` (`ViewModels/BookSort.swift`) holds all rules — `localizedStandardCompare` for title/author, books without an author last when sorting by author, ties by title A→Z in either direction, a finished book counts as 100% even without pages. `BookListViewModel.filteredBooks` filters by status first, then sorts; `books` stays in repository order. The choice is saved in UserDefaults by `BookSortStorage` (`Services/`), unknown stored values fall back to `BookSort.default` (date added, newest first).
- `Views/` — own their ViewModel via `@State`, injected through `init`.

Dependency flow: `App/AppDependencies.make()` is the only place that picks dependencies by launch arguments (live, `-seedSampleBooks`, `-uiTesting`): `ModelContainer`, `BookSearchService`, `BookSortStorage`. Don't add launch-mode checks to ViewModels or Views — add a branch there. `App/BookshelfApp` calls it once, builds `SwiftDataBookRepository(context: mainContext)` and passes everything into the root ViewModel. Child ViewModels are created by the parent ViewModel (e.g. `BookListViewModel.makeAddBookViewModel()`) so they share the same repository; after a child saves, the parent reloads via a callback (`onSave` → `loadBooks()`).

Views do not use `@Query` — data goes through ViewModel → repository so ViewModels stay testable. Previews build an in-memory `ModelContainer`.

## Design / Figma

Before implementing UI from Figma (Figma MCP) or adding colors, fonts, icons or assets, read `DESIGN_SYSTEM.md`: Figma output is a reference to rewrite in SwiftUI using system tokens, SF Symbols and `Assets.xcassets`.

## Build settings that affect code

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in the app target: all types are implicitly `@MainActor`. Tests touching ViewModels must be marked `@MainActor`.
- The Xcode project uses file-system-synchronized groups: new files/folders under `Bookshelf/`, `BookshelfTests/`, `BookshelfUITests/` are picked up automatically — don't edit `project.pbxproj` to add files.
- `Shared/` is a synchronized folder in both `Bookshelf` and `BookshelfUITests` (UI tests can't import the app module). Put code both need there (now `AccessibilityID`); it compiles in the app's Release build too, so test-only parts go under `#if DEBUG`.

## Tests

- После изменения логики — прогоняй тесты затронутого модуля:
  `xcodebuild test -project Bookshelf.xcodeproj -scheme Bookshelf -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:BookshelfTests/<Suite>`
- Перед коммитом — полный прогон. Не коммить с падающими тестами.
- Логика — Swift Testing. UI-тесты — XCTest (XCUITest): Swift Testing не умеет UI-тесты.
- Если UI-тест не находит элемент — сначала выведи `app.debugDescription` (`print` в тесте, вывод — в логе `xcodebuild`), потом ищи элемент по фактическому дереву, а не по догадкам. Отладочный `print` перед коммитом убрать.

`BookshelfTests` uses Swift Testing (`@Test`, `#expect`, `#require`, `@Test(arguments:)`), not XCTest. No real network: search tests use `FakeBookSearchService` (actor) with `Gate` / `BlockingSleeper` to hold responses and debounce pauses.

- Unit tests of ViewModels use `InMemoryBookRepository` (a fake that simply doesn't apply changes on failure).
- Anything about storage, sorting or write failures uses `TestStore` (`TestSupport.swift`): the real `SwiftDataBookRepository` on an in-memory `ModelContainer`, with `failSaves` to make `save()` throw after the change is applied. Check what was persisted via `persistedBooks()` (a fresh `ModelContext`), not the working context.
- `BookListViewModel` reads the saved sort from UserDefaults: in tests pass `sortStorage: BookSortStorage(defaults: makeIsolatedDefaults())`, otherwise the sort chosen in the simulator leaks into tests.
- Swift 6.3 quirk: conform test actors to `nonisolated` protocols in an extension (see `FakeBookSearchService`).

`BookshelfUITests` (XCTest):
- Launch with `AccessibilityID.LaunchArgument.uiTesting`: `UITestSupport` (DEBUG only) gives an empty in-memory store, isolated UserDefaults for the sort and `UITestBookSearchService` with fixed books (ids in `AccessibilityID.UITestFixture`, no covers) — no network, no state from earlier runs.
- Find elements only by `AccessibilityID` constants (`Shared/AccessibilityID.swift`), never by on-screen text. Exceptions without a SwiftUI identifier API: the `.searchable` field (`app.searchFields.firstMatch`), the close-search button (the only direct button child of the navigation bar while search is active; iOS hides Back until search is closed) and the system Back button (`navigationBars.buttons["BackButton"]`).
- No `sleep`: only `waitForExistence(timeout:)`. After tapping the search field wait for `app.keyboards.firstMatch`: the first tap sometimes only activates search without focus, then tap again.
- One UI test run takes ~2–6 minutes (app launch and automation setup in the simulator are slow): run it alone with `-only-testing:BookshelfUITests/<Class>`, timeout 10 minutes. `BookshelfUITests.swift` / `BookshelfUITestsLaunchTests.swift` are still the Xcode template.

## Работа с git

- Каждая фича — отдельная ветка `feature/<название>`
- Каждое исправление ошибки — отдельная ветка `bugfix/<название>`
- Коммиты на английском, в повелительном наклонении

Remote `origin` is `git@github.com:keviabird/bookshelf.git` (SSH, key `~/.ssh/id_ed25519_github`), branch `main`.
