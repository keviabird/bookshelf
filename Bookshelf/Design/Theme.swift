import SwiftUI

/// Единое место для цветов, шрифтов и размеров (макет Figma «Library-App»).
/// Цвета повторяют переменные коллекции Bookshelf в Figma: `color/<name>` → Color Set
/// `Shelf<Name>` (Any + Dark) в Assets.xcassets → `Theme.Colors.<name>`.
enum Theme {
    enum Colors {
        /// `color/background-dark` — тёмная шапка и фон карточки книги.
        static let backgroundDark = Color(.shelfBackgroundDark)
        /// `color/surface` — скруглённый лист.
        static let surface = Color(.shelfSurface)
        /// `color/text-primary` — основной текст; фон выбранного чипа и главной кнопки.
        static let textPrimary = Color(.shelfTextPrimary)
        /// `color/text-secondary` — автор, подписи, описание.
        static let textSecondary = Color(.shelfTextSecondary)
        /// `color/text-on-dark` — текст и иконки на тёмном фоне.
        static let textOnDark = Color(.shelfTextOnDark)
        /// `color/accent` — крупные цифры, кнопки в шапке, прогресс в карточке.
        static let accent = Color(.shelfAccent)
        /// `color/track` — невыбранный чип, дорожка прогресса.
        static let track = Color(.shelfTrack)
    }

    /// Системные аналоги шрифтов макета; все привязаны к Dynamic Type.
    enum Fonts {
        /// Заголовок шапки (в макете Abel 18).
        static let headerTitle = Font.headline.weight(.regular).width(.condensed)
        static let headerTitleTracking: CGFloat = 4
        /// Крупная цифра в сводке (Alice 40).
        static let summaryNumber = Font.system(.largeTitle, design: .serif)
        /// Текст сводки (Montserrat SemiBold 12).
        static let summaryText = Font.caption.weight(.semibold)
        /// Номер книги в кружке (Alice 32).
        static let rank = Font.system(.title, design: .serif)
        /// Название чипа и его счётчик (Montserrat 12).
        static let chipTitle = Font.caption.weight(.semibold)
        static let chipCount = Font.caption
        /// Название книги в списке (Montserrat SemiBold 18).
        static let bookTitle = Font.headline
        /// Автор (Montserrat Medium 14).
        static let bookAuthor = Font.subheadline.weight(.medium)
        /// Процент прогресса в списке (Montserrat Medium 10).
        static let progress = Font.caption2.weight(.medium)

        // Карточка книги
        /// Название книги (Montserrat SemiBold 22).
        static let detailTitle = Font.title2.weight(.semibold)
        /// Подписи секций: «Прогресс чтения», проценты (Montserrat SemiBold 12).
        static let sectionLabel = Font.caption.weight(.semibold)
        /// Заголовок блока «О книге» (Montserrat SemiBold 14).
        static let sectionTitle = Font.subheadline.weight(.semibold)
        /// Число в статистике (Alice 24).
        static let statValue = Font.system(.title2, design: .serif)
        /// Подпись под числом (Montserrat Medium 10, капслок).
        static let statLabel = Font.caption2.weight(.medium)
        static let statLabelTracking: CGFloat = 0.8
        /// «Стр. 210 из 498» (Montserrat Italic 10).
        static let caption = Font.caption2.italic()
        /// Текст описания (Montserrat Regular 12, интерлиньяж 18).
        static let body = Font.footnote
        static let bodyLineSpacing: CGFloat = 4
        /// Главная кнопка (Montserrat SemiBold 14).
        static let button = Font.subheadline.weight(.semibold)
    }

    enum Metrics {
        static let sheetCornerRadius: CGFloat = 48
        static let coverSize = CGSize(width: 88, height: 133)
        static let rankBadgeSize: CGFloat = 44
        /// Насколько кружок номера заходит на обложку.
        static let rankBadgeOverlap: CGFloat = 14
        static let progressBarHeight: CGFloat = 5
        static let chipPadding = EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)

        // Карточка книги
        static let detailCoverSize = CGSize(width: 140, height: 210)
        static let detailCoverCornerRadius: CGFloat = 6
        static let detailSheetCornerRadius: CGFloat = 40
        static let detailProgressBarHeight: CGFloat = 4
        static let primaryButtonHeight: CGFloat = 52
    }
}
