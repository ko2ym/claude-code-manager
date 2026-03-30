import SwiftUI
import AppKit

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var showFolderPicker = false
    @State private var projectToRemove: ProjectEntry?

    var body: some View {
        @Bindable var appState = appState

        List(selection: $appState.sidebarSelection) {
            // GLOBAL section
            Section("GLOBAL") {
                NavigationLink(value: SidebarSelection.global) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("グローバル設定")
                                .font(.body)
                            Text("~/.claude/")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundStyle(.blue)
                    }
                }
                .tag(SidebarSelection.global)
            }

            // PROJECTS section
            Section {
                ForEach(appState.projects) { project in
                    NavigationLink(value: SidebarSelection.project(project.id)) {
                        ProjectRow(project: project)
                    }
                    .tag(SidebarSelection.project(project.id))
                    .contextMenu {
                        Button("削除", role: .destructive) {
                            projectToRemove = project
                        }
                        Button("Finderで開く") {
                            NSWorkspace.shared.open(URL(fileURLWithPath: project.path))
                        }
                    }
                }
            } header: {
                HStack {
                    Text("PROJECTS")
                    Spacer()
                    Button {
                        showFolderPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("プロジェクトフォルダを追加")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Claude Code Manager")
        .alert("プロジェクトを削除", isPresented: Binding(
            get: { projectToRemove != nil },
            set: { if !$0 { projectToRemove = nil } }
        )) {
            Button("削除", role: .destructive) {
                if let p = projectToRemove {
                    appState.removeProject(p)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            if let p = projectToRemove {
                Text("「\(p.name)」を一覧から削除しますか？\nファイルは削除されません。")
            }
        }
        .onChange(of: showFolderPicker) { _, newValue in
            if newValue { pickFolder() }
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "プロジェクトフォルダを選択してください"
        panel.prompt = "選択"

        panel.begin { response in
            showFolderPicker = false
            if response == .OK, let url = panel.url {
                appState.addProject(path: url.path)
            }
        }
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: ProjectEntry

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body)
                    .lineLimit(1)
                Text(project.path.replacingOccurrences(
                    of: FileManager.default.homeDirectoryForCurrentUser.path,
                    with: "~"
                ))
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
            }
        } icon: {
            Image(systemName: "folder.fill")
                .foregroundStyle(project.hasClaudeDir ? Color.accentColor : .secondary)
        }
    }
}
