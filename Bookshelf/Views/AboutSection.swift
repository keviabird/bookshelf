import SwiftUI

/// Блок «О книге»: заголовок и описание.
struct AboutSection: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("О книге")
                .font(Theme.Fonts.sectionTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(text)
                .font(Theme.Fonts.body)
                .lineSpacing(Theme.Fonts.bodyLineSpacing)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AboutSection(text: "Вайолет готовилась стать писцом, но оказывается в военном училище наездников драконов.")
        .padding()
}
