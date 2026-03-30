import SwiftUI

struct MCPAddSheet: View {
    var onAdd: (String, MCPServer) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var type = "stdio"
    @State private var command = ""
    @State private var argsText = ""
    @State private var url = ""
    @State private var envPairs: [String: String] = [:]
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("MCPサーバーを追加")
                .font(.title3.weight(.semibold))

            Form {
                Section("サーバー名") {
                    TextField("例: my-server", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                Section("タイプ") {
                    Picker("", selection: $type) {
                        Text("stdio").tag("stdio")
                        Text("http").tag("http")
                        Text("sse").tag("sse")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                if type == "stdio" {
                    Section("コマンド") {
                        TextField("例: npx", text: $command)
                            .textFieldStyle(.roundedBorder)
                        TextField("引数 (スペース区切り)", text: $argsText)
                            .textFieldStyle(.roundedBorder)
                        Text("例: -y @modelcontextprotocol/server-filesystem /path")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("エンドポイント URL") {
                        TextField("https://...", text: $url)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Section("環境変数 (任意)") {
                    KeyValueEditor(
                        pairs: $envPairs,
                        keyPlaceholder: "API_KEY",
                        valuePlaceholder: "value"
                    )
                }
            }
            .formStyle(.grouped)

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }

            HStack {
                Spacer()
                Button("キャンセル", role: .cancel) { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Button("追加") { commitAdd() }
                    .keyboardShortcut(.return, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 480, height: 520)
    }

    private func commitAdd() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "サーバー名を入力してください"
            return
        }

        let args = argsText.components(separatedBy: " ").filter { !$0.isEmpty }

        var server = MCPServer(name: trimmedName)
        server.type = type
        if type == "stdio" {
            server.command = command.isEmpty ? nil : command
            server.args = args.isEmpty ? nil : args
        } else {
            server.url = url.isEmpty ? nil : url
        }
        server.env = envPairs.isEmpty ? nil : envPairs

        onAdd(trimmedName, server)
        dismiss()
    }
}

// MARK: - Presets Sheet

struct MCPPresetsSheet: View {
    var projectPath: String?
    var onAdd: (String, MCPServer) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedName: String? = MCPPreset.all.first?.name

    private var selected: MCPPreset? {
        MCPPreset.all.first(where: { $0.name == selectedName })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sheetHeader
            Divider()
            HStack(spacing: 0) {
                presetList
                Divider()
                detailPanel
            }
        }
        .frame(width: 560, height: 440)
    }

    private var sheetHeader: some View {
        HStack {
            Text("プリセットから追加")
                .font(.title3.weight(.semibold))
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }

    private var presetList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(MCPPreset.all, id: \.name) { preset in
                    PresetRow(
                        preset: preset,
                        isSelected: selectedName == preset.name,
                        onTap: { selectedName = preset.name }
                    )
                }
            }
            .padding(8)
        }
        .frame(width: 220)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let preset = selected {
            PresetDetailPanel(preset: preset, projectPath: projectPath) { name, server in
                onAdd(name, server)
                dismiss()
            }
        } else {
            Text("プリセットを選択してください")
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Preset Row

private struct PresetRow: View {
    let preset: MCPPreset
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(preset.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preset Detail Panel

private struct PresetDetailPanel: View {
    let preset: MCPPreset
    let projectPath: String?
    let onAdd: (String, MCPServer) -> Void

    private var resolvedServer: MCPServer {
        projectPath.map { preset.resolved(fromProjectPath: $0) } ?? preset.server
    }

    private var autoFilledKeys: Set<String> {
        projectPath.map { preset.autoFilledKeys(fromProjectPath: $0) } ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(preset.displayName)
                .font(.title3.weight(.semibold))
            Text(preset.description)
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            let server = resolvedServer
            LabeledField(label: "Type", value: server.displayType)
            if let cmd = server.command {
                LabeledField(label: "Command", value: cmd)
            }
            if let args = server.args, !args.isEmpty {
                argsSection(args: args)
            }
            if let env = server.env, !env.isEmpty {
                envSection(env: env)
            }

            if !autoFilledKeys.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "wand.and.stars")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text(".env.local から設定を自動入力しました")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Button("このプリセットを追加") {
                onAdd(preset.name, resolvedServer)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func argsSection(args: [String]) -> some View {
        let filled = autoFilledKeys
        let attrStr = buildArgsDisplay(args: args, filled: filled)
        return VStack(alignment: .leading, spacing: 4) {
            Text("Args")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(attrStr)
                .font(.system(size: 12, design: .monospaced))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }

    private func buildArgsDisplay(args: [String], filled: Set<String>) -> AttributedString {
        var result = AttributedString(args.joined(separator: " "))
        for (flag, _) in preset.argFillKeys {
            guard filled.contains(flag) else { continue }
            if flag.hasSuffix("=") {
                if let flagArg = args.first(where: { $0.hasPrefix(flag) }) {
                    let value = String(flagArg.dropFirst(flag.count))
                    if !value.isEmpty, let range = result.range(of: value) {
                        result[range].foregroundColor = .init(.systemGreen)
                    }
                }
            } else {
                if let idx = args.firstIndex(of: flag), idx + 1 < args.count {
                    let value = args[idx + 1]
                    if !value.isEmpty, let range = result.range(of: value) {
                        result[range].foregroundColor = .init(.systemGreen)
                    }
                }
            }
        }
        return result
    }

    private func envSection(env: [String: String]) -> some View {
        let filled = autoFilledKeys
        return VStack(alignment: .leading, spacing: 4) {
            Text("Env")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(env.keys.sorted(), id: \.self) { key in
                HStack(spacing: 4) {
                    Text(key)
                        .font(.system(size: 12, design: .monospaced))
                    Text("=")
                        .foregroundStyle(.secondary)
                    let val = env[key] ?? ""
                    Text(val.isEmpty ? "(未設定)" : val)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(filled.contains(key) ? Color.green : Color.orange)
                }
            }
            if env.values.contains(where: { $0.isEmpty }) {
                Text("※ 空のAPIキーは追加後に設定してください")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }
}

struct LabeledField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, design: .monospaced))
        }
    }
}

extension MCPPreset: Equatable, Hashable {
    static func == (lhs: MCPPreset, rhs: MCPPreset) -> Bool { lhs.name == rhs.name }
    func hash(into hasher: inout Hasher) { hasher.combine(name) }
}
