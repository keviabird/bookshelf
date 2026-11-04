import SwiftUI

/// Процент и полоса прогресса чтения (строка списка).
struct ReadingProgressBar: View {
    /// Прогресс от 0 до 1.
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ReadingFormat.percent(progress))
                .font(Theme.Fonts.progress)
                .tracking(1)
                .monospacedDigit()
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityHidden(true)
            ProgressView(value: min(max(progress, 0), 1))
                .progressViewStyle(ShelfProgressViewStyle())
                .accessibilityLabel("Прогресс чтения")
        }
    }
}

/// Тонкая полоса со скруглёнными концами: дорожка `track` и цветное заполнение.
/// В списке — тёмное заполнение высотой 5, в карточке — золотое высотой 4.
struct ShelfProgressViewStyle: ProgressViewStyle {
    var fill: Color = Theme.Colors.textPrimary
    var height: CGFloat = Theme.Metrics.progressBarHeight

    func makeBody(configuration: Configuration) -> some View {
        let fraction = configuration.fractionCompleted ?? 0
        Capsule()
            .fill(Theme.Colors.track)
            .frame(height: height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    // Ненулевой прогресс всегда виден хотя бы точкой, как 2% в макете.
                    let width = fraction > 0 ? max(proxy.size.width * fraction, height) : 0
                    Capsule()
                        .fill(fill)
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
        ProgressView(value: 0.42)
            .progressViewStyle(ShelfProgressViewStyle(fill: Theme.Colors.accent, height: 4))
    }
    .frame(width: 165)
    .padding()
}
