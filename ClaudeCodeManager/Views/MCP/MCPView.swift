import SwiftUI

struct MCPView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedServerName: String?
    @State private var showAddSheet = false
    @State private var showPresets = false
    @State private var serverToDelete: String?
    @State private var saveError: String?
    @State private var showSaveError = false

    var config: MCPConfig { appState.currentMCPConfig }
    var servers: [MCPServer] { config.serverList }

    /// 検出済みだがMCP未設定のプリセット候補
    var suggestedPresets: [MCPPreset] {
        guard case .project(let id) = appState.sidebarSelection,
              let project = appState.projects.first(where: { $0.id == id }) else { return [] }
        let configured = Set(servers.map(\.name))
        return project.detectedMCPPresets.filter { !configured.contains($0.name) }
    }

    var currentProjectPath: String? {
        guard case .project(let id) = appState.sidebarSelection,
              let project = appState.projects.first(where: { $0.id == id }) else { return nil }
        return project.path
    }

    var body: some View {
        HSplitView {
            // Server list
            VStack(spacing: 0) {
                HStack {
                    Text("MCPサーバー")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showPresets = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .help("MCPサーバーを追加")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                // 検出された未設定MCP提案
                if !suggestedPresets.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(suggestedPresets, id: \.name) { preset in
                            MCPSuggestionRow(preset: preset) {
                                let resolved = currentProjectPath.map { preset.resolved(fromProjectPath: $0) } ?? preset.server
                                addServer(name: preset.name, server: resolved)
                            }
                        }
                    }
                    .background(Color.orange.opacity(0.06))
                    Divider()
                }

                if servers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("MCPサーバーが設定されていません")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Button("プリセットから追加") {
                            showPresets = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(servers, id: \.name, selection: $selectedServerName) { server in
                        MCPServerRow(server: server)
                            .tag(server.name)
                            .contextMenu {
                                Button("削除", role: .destructive) {
                                    serverToDelete = server.name
                                }
                                Button("コピー (JSON)") {
                                    copyServerJSON(server)
                                }
                            }
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)

            // Detail panel
            if let name = selectedServerName,
               let server = config.mcpServers?[name] {
                MCPDetailPanel(
                    serverName: name,
                    server: server,
                    onSave: { updated in
                        saveServer(name: name, server: updated)
                    },
                    onDelete: {
                        deleteServer(name: name)
                        selectedServerName = nil
                    }
                )
                .id(name)
            } else {
                MCPEmptyState(onAdd: { showAddSheet = true })
            }
        }
        .sheet(isPresented: $showAddSheet) {
            MCPAddSheet { name, server in
                addServer(name: name, server: server)
            }
        }
        .sheet(isPresented: $showPresets) {
            MCPPresetsSheet(projectPath: currentProjectPath) { name, server in
                addServer(name: name, server: server)
            }
        }
        .alert("削除の確認", isPresented: Binding(
            get: { serverToDelete != nil },
            set: { if !$0 { serverToDelete = nil } }
        )) {
            Button("削除", role: .destructive) {
                if let name = serverToDelete { deleteServer(name: name) }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            if let name = serverToDelete {
                Text("「\(name)」を削除しますか？")
            }
        }
        .alert("保存エラー", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "不明なエラー")
        }
    }

    private func addServer(name: String, server: MCPServer) {
        var config = appState.currentMCPConfig
        config.addServer(server)
        appState.currentMCPConfig = config
        saveMCP()
        selectedServerName = name
    }

    private func saveServer(name: String, server: MCPServer) {
        var config = appState.currentMCPConfig
        config.mcpServers?[name] = server
        appState.currentMCPConfig = config
        saveMCP()
    }

    private func deleteServer(name: String) {
        var config = appState.currentMCPConfig
        config.removeServer(named: name)
        appState.currentMCPConfig = config
        saveMCP()
    }

    private func saveMCP() {
        do {
            try appState.saveMCPConfig()
        } catch {
            saveError = error.localizedDescription
            showSaveError = true
        }
    }

    private func copyServerJSON(_ server: MCPServer) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        if let data = try? encoder.encode(server),
           let json = String(data: data, encoding: .utf8) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(json, forType: .string)
        }
    }
}

// MARK: - Server Row

struct MCPServerRow: View {
    let server: MCPServer

    var body: some View {
        HStack(spacing: 10) {
            // Type badge
            Text(server.displayType)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(typeColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .font(.body)
                    .lineLimit(1)
                if let cmd = server.command {
                    Text(cmd)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                } else if let url = server.url {
                    Text(url)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var typeColor: Color {
        switch server.displayType {
        case "stdio": return .blue
        case "http": return .green
        case "sse": return .orange
        default: return .gray
        }
    }
}

// MARK: - Detail Panel

struct MCPDetailPanel: View {
    let serverName: String
    var server: MCPServer
    var onSave: (MCPServer) -> Void
    var onDelete: () -> Void

    @State private var draft: MCPServer
    @State private var isDirty = false

    init(serverName: String, server: MCPServer, onSave: @escaping (MCPServer) -> Void, onDelete: @escaping () -> Void) {
        self.serverName = serverName
        self.server = server
        self.onSave = onSave
        self.onDelete = onDelete
        self._draft = State(initialValue: server)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(serverName)
                        .font(.title3.weight(.semibold))
                    Text("MCPサーバー設定")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("削除", role: .destructive) { onDelete() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            ScrollView {
                Form {
                    Section("基本設定") {
                        Picker("タイプ", selection: Binding(
                            get: { draft.type ?? "stdio" },
                            set: { draft.type = $0 }
                        )) {
                            Text("stdio").tag("stdio")
                            Text("http").tag("http")
                            Text("sse").tag("sse")
                        }
                        .pickerStyle(.segmented)

                        if draft.displayType == "stdio" {
                            TextField("コマンド", text: Binding(
                                get: { draft.command ?? "" },
                                set: { draft.command = $0.isEmpty ? nil : $0 }
                            ))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("引数 (args)")
                                TagEditor(
                                    items: Binding(
                                        get: { draft.args ?? [] },
                                        set: { draft.args = $0.isEmpty ? nil : $0 }
                                    ),
                                    placeholder: "引数を追加..."
                                )
                            }
                        } else {
                            TextField("URL", text: Binding(
                                get: { draft.url ?? "" },
                                set: { draft.url = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }

                    Section("環境変数 (env)") {
                        KeyValueEditor(
                            pairs: Binding(
                                get: { draft.env ?? [:] },
                                set: { draft.env = $0.isEmpty ? nil : $0 }
                            ),
                            keyPlaceholder: "VARIABLE",
                            valuePlaceholder: "value"
                        )
                    }
                }
                .formStyle(.grouped)
                .padding()
            }

            if isDirty {
                Divider()
                HStack {
                    Spacer()
                    Button("元に戻す") {
                        draft = server
                        isDirty = false
                    }
                    Button("保存") {
                        onSave(draft)
                        isDirty = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(12)
            }
        }
        .onChange(of: draft) { _, _ in
            isDirty = true
        }
    }
}

// MARK: - Suggestion Row

struct MCPSuggestionRow: View {
    let preset: MCPPreset
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkle")
                .font(.system(size: 11))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 1) {
                Text(preset.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                Text("プロジェクトで検出されました")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("追加") { onAdd() }
                .font(.system(size: 11))
                .buttonStyle(.bordered)
                .controlSize(.mini)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}

// MARK: - Empty State

struct MCPEmptyState: View {
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("サーバーを選択してください")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("MCPサーバーを追加") { onAdd() }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
