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
- Модели SwiftData меняются только через `BookRepository`, и каждая операция сразу вызывает `save()`. Никаких изменений моделей напрямую из View/биндингов: при ошибке сохранения репозиторий делает `context.rollback()`, который отменяет **все** несохранённые изменения в контексте
- После ошибки записи ViewModel перезагружает данные из репозитория, чтобы состояние в памяти совпало с хранилищем

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
- `Services/` — `BookRepository` protocol + `SwiftDataBookRepository` (wraps `ModelContext`, calls `save()` after each mutation and `rollback()` if the save fails — see the rule above).
- `ViewModels/` — `@Observable` classes that depend only on `BookRepository`, never on `ModelContext` or `@Query`.
- `Views/` — own their ViewModel via `@State`, injected through `init`.

Dependency flow: `App/BookshelfApp` creates the `ModelContainer`, builds `SwiftDataBookRepository(context: mainContext)` and passes it into the root ViewModel. Child ViewModels are created by the parent ViewModel (e.g. `BookListViewModel.makeAddBookViewModel()`) so they share the same repository; after a child saves, the parent reloads via a callback (`onSave` → `loadBooks()`).

Views do not use `@Query` — data goes through ViewModel → repository so ViewModels stay testable. Previews build an in-memory `ModelContainer`.

## Build settings that affect code

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in the app target: all types are implicitly `@MainActor`. Tests touching ViewModels must be marked `@MainActor`.
- The Xcode project uses file-system-synchronized groups: new files/folders under `Bookshelf/`, `BookshelfTests/` are picked up automatically — don't edit `project.pbxproj` to add files.

## Tests

`BookshelfTests` uses Swift Testing (`@Test`, `#expect`, `#require`), not XCTest. ViewModel tests use an in-memory fake `BookRepository` instead of SwiftData. `BookshelfUITests` (XCTest) is still the Xcode template.

## Работа с git

- Каждая фича — отдельная ветка `feature/<название>`
- Коммиты на английском, в повелительном наклонении

Remote `origin` is `git@github.com:keviabird/bookshelf.git` (SSH, key `~/.ssh/id_ed25519_github`), branch `main`.
