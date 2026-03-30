import SwiftUI

struct NewFileSheet: View {
    let baseURL: URL
    var onCreated: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var fileName = ""
    @State private var selectedTemplate: FileTemplate = .blank
    @State private var selectedDirectory: FileDirectory = .root
    @State private var errorMessage: String?

    enum FileTemplate: String, CaseIterable, Identifiable {
        case blank = "空白"
        case claudeMD = "CLAUDE.md テンプレート"
        case rule = "ルールファイル"
        case command = "スラッシュコマンド"
        case agent = "エージェント定義"

        var id: String { rawValue }

        var content: String {
            switch self {
            case .blank: return ""
            case .claudeMD:
                return """
                # プロジェクト指示

                ## 概要
                このプロジェクトの説明をここに書いてください。

                ## コーディング規約
                -

                ## 禁止事項
                -
                """
            case .rule:
                return """
                # ルール名

                ## 概要
                このルールの説明。

                ## 適用条件
                -

                ## 規約
                -
                """
            case .command:
                return """
                # /command-name

                コマンドの説明をここに書きます。

                $ARGUMENTS を受け取って処理します。
                """
            case .agent:
                return """
                ---
                name: agent-name
                description: エージェントの説明
                ---

                # エージェント名

                ## 役割
                このエージェントの役割の説明。

                ## 動作指針
                -
                """
            }
        }

        var defaultDir: FileDirectory {
            switch self {
            case .blank, .claudeMD: return .root
            case .rule: return .claudeRules
            case .command: return .claudeCommands
            case .agent: return .claudeAgents
            }
        }

        var icon: String {
            switch self {
            case .blank: return "doc"
            case .claudeMD: return "doc.fill"
            case .rule: return "ruler"
            case .command: return "terminal"
            case .agent: return "cpu"
            }
        }
    }

    enum FileDirectory: String, CaseIterable, Identifiable {
        case root = "プロジェクトルート"
        case claudeDir = ".claude/"
        case claudeRules = ".claude/rules/"
        case claudeCommands = ".claude/commands/"
        case claudeAgents = ".claude/agents/"

        var id: String { rawValue }

        func url(base: URL) -> URL {
            switch self {
            case .root: return base
            case .claudeDir: return base.appendingPathComponent(".claude")
            case .claudeRules: return base.appendingPathComponent(".claude/rules")
            case .claudeCommands: return base.appendingPathComponent(".claude/commands")
            case .claudeAgents: return base.appendingPathComponent(".claude/agents")
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("新規MDファイル作成")
                .font(.title3.weight(.semibold))

            Form {
                Section("ファイル名") {
                    HStack {
                        TextField("例: my-notes", text: $fileName)
                            .textFieldStyle(.roundedBorder)
                        Text(".md")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("テンプレート") {
                    Picker("", selection: $selectedTemplate) {
                        ForEach(FileTemplate.allCases) { template in
                            Label(template.rawValue, systemImage: template.icon).tag(template)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    .onChange(of: selectedTemplate) { _, newTemplate in
                        selectedDirectory = newTemplate.defaultDir
                    }
                }

                Section("保存先") {
                    Picker("", selection: $selectedDirectory) {
                        ForEach(FileDirectory.allCases) { dir in
                            Text(dir.rawValue).tag(dir)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()

                    Text(finalURL.path.replacingOccurrences(
                        of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            HStack {
                Spacer()
                Button("キャンセル", role: .cancel) { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("作成") { createFile() }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .disabled(fileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private var finalURL: URL {
        let trimmed = fileName.trimmingCharacters(in: .whitespaces)
        let name = trimmed.hasSuffix(".md") ? trimmed : "\(trimmed).md"
        return selectedDirectory.url(base: baseURL).appendingPathComponent(name)
    }

    private func createFile() {
        do {
            try FileService.shared.createFile(at: finalURL, content: selectedTemplate.content)
            onCreated(finalURL)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
