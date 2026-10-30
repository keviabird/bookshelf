import SwiftUI

/// Единое место для цветов, шрифтов и размеров экрана полки (макет Figma «Library-App»).
/// Новые цвета добавляются как Color Set в Assets.xcassets (Any + Dark) и подключаются здесь.
enum Theme {
    enum Colors {
        /// Фон тёмной шапки.
        static let header = Color(.shelfHeader)
        /// Фон скруглённого листа.
        static let sheet = Color(.shelfSheet)
        /// Основной текст, выбранный чип, заполнение прогресса.
        static let ink = Color(.shelfInk)
        /// Акцент: крупные цифры, кнопка добавления.
        static let gold = Color(.shelfGold)
        /// Невыбранный чип, дорожка прогресса.
        static let muted = Color(.shelfMuted)
        /// Фон кружка с номером книги — всегда светлый, как в макете.
        static let badge = Color.white
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
        /// Название книги (Montserrat SemiBold 18).
        static let bookTitle = Font.headline
        /// Автор (Montserrat Medium 14).
        static let bookAuthor = Font.subheadline.weight(.medium)
        /// Процент прогресса (Montserrat Medium 10).
        static let progress = Font.caption2.weight(.medium)
    }

    enum Metrics {
        static let sheetCornerRadius: CGFloat = 48
        static let coverSize = CGSize(width: 88, height: 133)
        static let rankBadgeSize: CGFloat = 44
        /// Насколько кружок номера заходит на обложку.
        static let rankBadgeOverlap: CGFloat = 14
        static let progressBarHeight: CGFloat = 5
        static let chipPadding = EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
    }
}
