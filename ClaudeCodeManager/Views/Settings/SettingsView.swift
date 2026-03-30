import SwiftUI

enum SettingsCategory: String, CaseIterable, Identifiable {
    case model = "モデル・動作"
    case permissions = "権限設定"
    case security = "セキュリティ"
    case env = "環境変数"
    case display = "表示・UX"
    case agentTeams = "Agent Teams"
    case mcpControl = "MCP制御"
    case apiAuth = "API・認証"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .model: return "cpu"
        case .permissions: return "lock.shield"
        case .security: return "shield.checkerboard"
        case .env: return "terminal"
        case .display: return "paintbrush"
        case .agentTeams: return "person.3.fill"
        case .mcpControl: return "server.rack"
        case .apiAuth: return "key.fill"
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var category: SettingsCategory = .model
    @State private var draft: ClaudeSettings = ClaudeSettings()
    @State private var isDirty = false
    @State private var saveError: String?
    @State private var showSaveError = false

    var body: some View {
        HSplitView {
            // Category sidebar
            List(SettingsCategory.allCases, selection: $category) { cat in
                Label(cat.rawValue, systemImage: cat.icon)
                    .tag(cat)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150, idealWidth: 165, maxWidth: 180)

            // Content + footer
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        categoryView
                            .padding(20)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }

                // Dirty footer
                if isDirty {
                    Divider()
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(.orange)
                        Text("未保存の変更があります")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("元に戻す") {
                            draft = appState.currentSettings
                            isDirty = false
                        }
                        Button("保存") {
                            commitSave()
                        }
                        .keyboardShortcut("s", modifiers: .command)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(NSColor.windowBackgroundColor))
                }
            }
        }
        .onAppear { draft = appState.currentSettings }
        .onChange(of: appState.sidebarSelection) { _, _ in
            draft = appState.currentSettings
            isDirty = false
        }
        .onChange(of: draft) { _, _ in
            isDirty = draft != appState.currentSettings
        }
        .alert("保存エラー", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "不明なエラー")
        }
    }

    @ViewBuilder
    private var categoryView: some View {
        switch category {
        case .model:
            ModelSettingsSection(settings: $draft)
        case .permissions:
            PermissionsSection(settings: $draft)
        case .security:
            SecuritySection(settings: $draft)
        case .env:
            EnvVarsSection(settings: $draft)
        case .display:
            DisplaySettingsSection(settings: $draft)
        case .agentTeams:
            AgentTeamsSection(settings: $draft)
        case .mcpControl:
            MCPControlSection(settings: $draft)
        case .apiAuth:
            APIAuthSection(settings: $draft)
        }
    }

    private func commitSave() {
        appState.currentSettings = draft
        do {
            try appState.saveSettings()
            isDirty = false
        } catch {
            saveError = error.localizedDescription
            showSaveError = true
        }
    }
}
