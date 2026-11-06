# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

«Книжная полка» — iOS app on SwiftUI + SwiftData. Deployment target is **iOS 17.0** (built with Xcode 26), so APIs newer than iOS 17 need `if #available` checks. UI strings are in Russian.

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

# Run unit tests (destination must be passed by id, see notes below)
SIM=$(xcrun simctl list devices available | grep -m1 "iPhone 17 (" | grep -oE '[0-9A-F-]{36}')
xcodebuild -project Bookshelf.xcodeproj -scheme Bookshelf \
  -destination "id=$SIM" -only-testing:BookshelfTests test

# Run a single test (Swift Testing: Target/Suite/testFunction())
xcodebuild -project Bookshelf.xcodeproj -scheme Bookshelf -destination "id=$SIM" \
  -only-testing:'BookshelfTests/AddBookViewModelTests/savesTrimmedBook()' test
```

Simulator notes:
- On this machine `-destination 'platform=iOS Simulator,name=…'` fails with "Unable to find a device matching the provided destination specifier"; pass the simulator by `id=` instead.
- Use the **iPhone 17** simulator (iOS 26.5). The iPhone 17 Pro simulator fails to launch the app ("No such process"), which is a simulator issue, not an app bug. The iOS 16.4 simulators are below the deployment target.
- Don't truncate `simctl list` output when looking for devices.

## Architecture

MVVM with a repository layer:

- `Models/` — SwiftData `@Model` classes. `Book.status` is a computed wrapper over the stored `statusRawValue: String` so that `#Predicate` can filter by status; keep enums stored as raw strings.
- `Services/` — `BookRepository` protocol (`fetchBooks`, `add`, `delete`, `update(book) { change }`) + `SwiftDataBookRepository` (wraps `ModelContext`, calls `save()` after each mutation and `rollback()` if the save fails — see the rule above).
- `Services/Search/` — `BookSearchService` protocol + `OpenLibrarySearchService` (`search.json`, async/await, `URLSession`), DTOs, `BookSearchResult`, `OpenLibraryMapper`. `BookSearchViewModel` debounces input by cancelling the previous `Task` (300 ms, injectable `sleep` for tests); duplicates are checked by `Book.openLibraryKey` or normalized title + author.
- `ViewModels/` — `@Observable` classes that depend only on `BookRepository`, never on `ModelContext` or `@Query`.
- `Views/` — own their ViewModel via `@State`, injected through `init`.

Dependency flow: `App/BookshelfApp` creates the `ModelContainer`, builds `SwiftDataBookRepository(context: mainContext)` and passes it into the root ViewModel. Child ViewModels are created by the parent ViewModel (e.g. `BookListViewModel.makeAddBookViewModel()`) so they share the same repository; after a child saves, the parent reloads via a callback (`onSave` → `loadBooks()`).

Views do not use `@Query` — data goes through ViewModel → repository so ViewModels stay testable. Previews build an in-memory `ModelContainer`.

## Design / Figma

Before implementing UI from Figma (Figma MCP) or adding colors, fonts, icons or assets, read `DESIGN_SYSTEM.md`: Figma output is a reference to rewrite in SwiftUI using system tokens, SF Symbols and `Assets.xcassets`.

## Build settings that affect code

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in the app target: all types are implicitly `@MainActor`. Tests touching ViewModels must be marked `@MainActor`.
- The Xcode project uses file-system-synchronized groups: new files/folders under `Bookshelf/`, `BookshelfTests/` are picked up automatically — don't edit `project.pbxproj` to add files.

## Tests

`BookshelfTests` uses Swift Testing (`@Test`, `#expect`, `#require`, `@Test(arguments:)`), not XCTest. No real network: search tests use `FakeBookSearchService` (actor) with `Gate` / `BlockingSleeper` to hold responses and debounce pauses.

- Unit tests of ViewModels use `InMemoryBookRepository` (a fake that simply doesn't apply changes on failure).
- Anything about storage, sorting or write failures uses `TestStore` (`TestSupport.swift`): the real `SwiftDataBookRepository` on an in-memory `ModelContainer`, with `failSaves` to make `save()` throw after the change is applied. Check what was persisted via `persistedBooks()` (a fresh `ModelContext`), not the working context.
- Swift 6.3 quirk: conform test actors to `nonisolated` protocols in an extension (see `FakeBookSearchService`).

`BookshelfUITests` (XCTest) is still the Xcode template.

## Работа с git

- Каждая фича — отдельная ветка `feature/<название>`
- Коммиты на английском, в повелительном наклонении

Remote `origin` is `git@github.com:keviabird/bookshelf.git` (SSH, key `~/.ssh/id_ed25519_github`), branch `main`.
