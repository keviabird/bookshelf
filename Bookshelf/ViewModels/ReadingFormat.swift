import Foundation

/// Тексты про прогресс чтения, общие для списка, карточки и формы.
enum ReadingFormat {
    /// «14%»: целые проценты без пробела, как в макете.
    static func percent(_ progress: Double) -> String {
        let clamped = progress.isFinite ? min(max(progress, 0), 1) : 0
        return "\(Int((clamped * 100).rounded()))%"
    }

    /// «Стр. 210 из 498».
    static func pages(current: Int, total: Int) -> String {
        "Стр. \(current) из \(total)"
    }
}
