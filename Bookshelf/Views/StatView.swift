import SwiftUI

/// Одна колонка статистики: крупное число с засечками и подпись капслоком.
struct StatView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.Fonts.statValue)
                .foregroundStyle(Theme.Colors.textPrimary)
                .monospacedDigit()
            Text(label)
                .textCase(.uppercase)
                .font(Theme.Fonts.statLabel)
                .tracking(Theme.Fonts.statLabelTracking)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        StatView(value: "498", label: "страниц")
        StatView(value: "2023", label: "год")
        StatView(value: "12.10", label: "добавлена")
    }
    .padding()
}
