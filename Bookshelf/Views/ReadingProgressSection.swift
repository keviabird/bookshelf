import SwiftUI

/// Блок прогресса в карточке: «Прогресс чтения» и процент, золотая полоса, «Стр. 210 из 498».
struct ReadingProgressSection: View {
    let progress: Double
    let progressText: String
    let pagesText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Прогресс чтения")
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Text(progressText)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.accent)
            }
            .font(Theme.Fonts.sectionLabel)
            .accessibilityHidden(true)

            ProgressView(value: min(max(progress, 0), 1))
                .progressViewStyle(ShelfProgressViewStyle(
                    fill: Theme.Colors.accent,
                    height: Theme.Metrics.detailProgressBarHeight
                ))
                .accessibilityLabel("Прогресс чтения")
                .accessibilityValue([progressText, pagesText].compactMap { $0 }.joined(separator: ", "))

            if let pagesText {
                Text(pagesText)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

#Preview {
    ReadingProgressSection(progress: 0.42, progressText: "42%", pagesText: "Стр. 210 из 498")
        .padding()
}
