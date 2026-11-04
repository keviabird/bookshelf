import SwiftUI

/// Процент и полоса прогресса чтения.
struct ReadingProgressBar: View {
    /// Прогресс от 0 до 1.
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Self.percentText(progress))
                .font(Theme.Fonts.progress)
                .tracking(1)
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.ink)
                .accessibilityHidden(true)
            ProgressView(value: Book.clampedProgress(progress))
                .progressViewStyle(ShelfProgressViewStyle())
                .accessibilityLabel("Прогресс чтения")
        }
    }

    /// «14%»: целые проценты, без пробела, как в макете.
    static func percentText(_ progress: Double) -> String {
        "\(Int((Book.clampedProgress(progress) * 100).rounded()))%"
    }
}

/// Тонкая полоса: светлая дорожка и тёмное заполнение со скруглёнными концами.
struct ShelfProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let fraction = configuration.fractionCompleted ?? 0
        let height = Theme.Metrics.progressBarHeight
        Capsule()
            .fill(Theme.Colors.muted)
            .frame(height: height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    // Ненулевой прогресс всегда виден хотя бы точкой, как 2% в макете.
                    let width = fraction > 0 ? max(proxy.size.width * fraction, height) : 0
                    Capsule()
                        .fill(Theme.Colors.ink)
                        .frame(width: width)
                }
            }
    }
}

#Preview {
    VStack(spacing: 24) {
        ReadingProgressBar(progress: 0)
        ReadingProgressBar(progress: 0.02)
        ReadingProgressBar(progress: 0.14)
        ReadingProgressBar(progress: 0.75)
        ReadingProgressBar(progress: 1)
    }
    .frame(width: 165)
    .padding()
}
