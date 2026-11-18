import SwiftUI
import UniformTypeIdentifiers

struct BackupSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var password = ""
    @State private var importPassword = ""
    @State private var showImporter = false
    @State private var shareURL: URL?
    @State private var message: String?
    @State private var isWorking = false
    private let service = BackupService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: SpacingTokens.md) {
                LuneCard {
                    VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                        Label("Шифрованный экспорт", systemImage: "lock.doc")
                            .font(TypographyTokens.titleSmall)
                            .foregroundStyle(ColorTokens.roseDeep)
                        Text("Вся история экспортируется в один файл и шифруется AES-GCM с ключом, выведенным из вашего пароля (PBKDF2). Без пароля файл открыть невозможно.")
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }

                LuneCard {
                    VStack(spacing: SpacingTokens.sm) {
                        LuneTextField(title: "Пароль для экспорта", placeholder: "Минимум 6 символов", text: $password, isMultiline: false)
                        LunePrimaryButton(title: "Создать резервную копию", icon: "square.and.arrow.up", isDisabled: password.count < 6) {
                            createBackup()
                        }
                    }
                }

                LuneCard {
                    VStack(spacing: SpacingTokens.sm) {
                        LuneSectionHeader(title: "Восстановление", subtitle: "Дубликаты по UUID пропускаются")
                        LuneTextField(title: "Пароль резервной копии", placeholder: "Введите пароль", text: $importPassword)
                        LuneSecondaryButton(title: "Выбрать файл копии", icon: "folder") {
                            showImporter = true
                        }
                    }
                }

                if let message {
                    LuneCard(background: ColorTokens.blush.opacity(0.5), showShadow: false) {
                        Text(message)
                            .font(TypographyTokens.bodySmall)
                            .foregroundStyle(ColorTokens.textPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: SpacingTokens.xs) {
                    LuneSectionHeader(title: "Локальные копии")
                    let files = service.existingBackups()
                    if files.isEmpty {
                        LuneCard {
                            LuneEmptyState(
                                symbol: "externaldrive",
                                title: "Копий пока нет",
                                message: "Создайте первую копию и храните файл в безопасном месте."
                            )
                        }
                    } else {
                        ForEach(files, id: \.self) { url in
                            LuneCard {
                                HStack {
                                    Image(systemName: "doc.lock")
                                        .foregroundStyle(ColorTokens.roseDeep)
                                    Text(url.lastPathComponent)
                                        .font(TypographyTokens.bodySmall)
                                        .foregroundStyle(ColorTokens.textPrimary)
                                    Spacer()
                                    Button { shareURL = url } label: {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                    .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                                    Button(role: .destructive) {
                                        service.deleteBackup(at: url)
                                        appState.refresh()
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .frame(width: SpacingTokens.touchMinimum, height: SpacingTokens.touchMinimum)
                                }
                            }
                        }
                    }
                }

                Text("Проверка версии формата, структуры и целостности выполняется при импорте. Неверный пароль не изменяет базу.")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(ColorTokens.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, SpacingTokens.screenHorizontal)
            .padding(.vertical, SpacingTokens.xs)
        }
        .background(ColorTokens.background)
        .navigationTitle("Резервные копии")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [UTType.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                importBackup(from: url)
            case .failure:
                message = "Файл не выбран."
            }
        }
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let shareURL { ShareSheet(items: [shareURL]) }
        }
        .overlay {
            if isWorking { ProgressView().padding().background(ColorTokens.surface.opacity(0.9)).clipShape(RoundedRectangle(cornerRadius: RadiusTokens.md)) }
        }
    }

    private func createBackup() {
        isWorking = true
        do {
            let url = try service.createEncryptedBackup(password: password)
            message = "Копия создана: \(url.lastPathComponent)"
            shareURL = url
            appState.refresh()
            appState.showToast("Копия создана")
        } catch {
            message = error.localizedDescription
        }
        isWorking = false
    }

    private func importBackup(from url: URL) {
        isWorking = true
        do {
            let count = try service.importBackup(from: url, password: importPassword)
            message = "Импортировано записей: \(count). Дубликаты пропущены."
            appState.refresh()
            appState.showToast("Импорт завершён")
        } catch {
            message = error.localizedDescription
            AnimationTokens.errorHaptic()
        }
        isWorking = false
    }
}
