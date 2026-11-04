import SwiftUI

/// Sheet «Обновить прогресс»: степпер текущей страницы.
struct UpdateProgressView: View {
    @Bindable var viewModel: BookDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $viewModel.draftPage, in: viewModel.draftPageRange) {
                        HStack {
                            Text(viewModel.draftPagesText)
                                .monospacedDigit()
                            Spacer()
                            Text(viewModel.draftProgressText)
                                .monospacedDigit()
                                .foregroundStyle(Theme.Colors.accent)
                        }
                    }
                    .accessibilityLabel("Текущая страница")
                    .accessibilityValue("\(viewModel.draftPagesText), \(viewModel.draftProgressText)")
                } footer: {
                    Text("На последней странице книга станет прочитанной.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Прогресс")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if viewModel.saveProgress() { dismiss() }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
