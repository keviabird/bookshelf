import SwiftUI

/// Белый кружок с номером книги в списке.
struct RankBadge: View {
    let number: Int

    @ScaledMetric(relativeTo: .title) private var size = Theme.Metrics.rankBadgeSize

    var body: some View {
        Text("\(number)")
            .font(Theme.Fonts.rank)
            .foregroundStyle(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(4)
            .frame(width: size, height: size)
            .background(Theme.Colors.textOnDark, in: Circle())
            .shadow(color: .black.opacity(0.25), radius: 4, y: 4)
    }
}

#Preview {
    HStack(spacing: 16) {
        RankBadge(number: 1)
        RankBadge(number: 12)
        RankBadge(number: 128)
    }
    .padding()
}
