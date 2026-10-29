import SwiftUI
import SwiftData

struct AddBookView: View {
    @State private var viewModel: AddBookViewModel
    @Environment(\.dismiss) private var dismiss

    /// Вызывается после успешного сохранения.
    private let onSave: () -> Void

    init(viewModel: AddBookViewModel, onSave: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название", text: $viewModel.title)
                    TextField("Автор (необязательно)", text: $viewModel.author)
                        .textContentType(.name)
                } header: {
                    Text("Книга")
                } footer: {
                    if !viewModel.isAuthorValid {
                        Text("Имя автора не может начинаться с цифры")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    TextField("https://…", text: $viewModel.coverURLString)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Обложка (URL)")
                } footer: {
                    if !viewModel.isCoverURLValid {
                        Text("Введите адрес, начинающийся с http:// или https://")
                            .foregroundStyle(.red)
                    }
                }

                Section("Статус") {
                    Picker("Статус", selection: $viewModel.status) {
                        ForEach(ReadingStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Новая книга")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        if viewModel.save() {
                            onSave()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Book.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return AddBookView(
        viewModel: AddBookViewModel(
            repository: SwiftDataBookRepository(context: container.mainContext)
        )
    )
}
