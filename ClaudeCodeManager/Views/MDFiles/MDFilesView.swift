import SwiftUI

struct MDFilesView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedNode: FileNode?
    @State private var showNewFileSheet = false
    @State private var refreshToken = UUID()

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                // File tree
                VStack(spacing: 0) {
                    HStack {
                        Text("ファイル")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            appState.reloadCurrentScope()
                            refreshToken = UUID()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("再読み込み")

                        Button {
                            showNewFileSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .help("新規ファイル作成")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    Divider()

                    if appState.currentFileNodes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                            Text("ファイルが見つかりません")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            if case .project(_) = appState.sidebarSelection {
                                Text("プロジェクトに CLAUDE.md や\n.claude/ ディレクトリを作成してください")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                FileTreeContent(
                                    nodes: appState.currentFileNodes,
                                    selectedNode: $selectedNode,
                                    depth: 0
                                )
                                .id(refreshToken)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(minWidth: 200, idealWidth: 260, maxWidth: 400)
                .background(Color(NSColor.windowBackgroundColor))

                // Content panel (always same type to prevent HSplitView layout reset)
                MDRightPanel(selectedNode: selectedNode, onDeleted: {
                    selectedNode = nil
                    appState.reloadCurrentScope()
                })
            }

            // Status bar
            Divider()
            HStack(spacing: 6) {
                if let node = selectedNode, !node.isDirectory {
                    Image(systemName: "doc")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text(node.url.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text(" ").font(.system(size: 11))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .sheet(isPresented: $showNewFileSheet) {
            NewFileSheet(baseURL: currentBaseURL) { _ in
                appState.reloadCurrentScope()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    refreshToken = UUID()
                }
            }
        }
        .onChange(of: appState.sidebarSelection) { _, _ in
            selectedNode = nil
        }
    }

    private var currentBaseURL: URL {
        switch appState.sidebarSelection {
        case .global:
            return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
        case .project(let id):
            if let project = appState.projects.first(where: { $0.id == id }) {
                return URL(fileURLWithPath: project.path)
            }
            return FileManager.default.homeDirectoryForCurrentUser
        }
    }
}

// MARK: - File Tree Content

struct FileTreeContent: View {
    let nodes: [FileNode]
    @Binding var selectedNode: FileNode?
    let depth: Int

    var body: some View {
        ForEach(nodes) { node in
            if node.isDirectory {
                DirectoryRow(node: node, selectedNode: $selectedNode, depth: depth)
            } else {
                FileRow(node: node, isSelected: selectedNode?.id == node.id, depth: depth) {
                    selectedNode = node
                    if node.content == nil {
                        FileService.shared.loadContent(for: node)
                    }
                }
            }
        }
    }
}

// MARK: - Directory Row (accordion)

struct DirectoryRow: View {
    let node: FileNode
    @Binding var selectedNode: FileNode?
    let depth: Int
    @State private var isExpanded = false

    private var fileCount: Int {
        countFiles(node.children ?? [])
    }

    private func countFiles(_ nodes: [FileNode]) -> Int {
        nodes.reduce(0) { count, n in
            n.isDirectory ? count + countFiles(n.children ?? []) : count + 1
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 5) {
                    if depth > 0 {
                        Rectangle().fill(.clear).frame(width: CGFloat(depth) * 16)
                    }

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.accentColor.opacity(0.7))
                        .frame(width: 10)

                    Image(systemName: "folder.fill")
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.orange)

                    Text(node.url.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    if fileCount > 0 {
                        Text("\(fileCount)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.5)))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(NSColor.separatorColor).opacity(0.08))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 4)
            .padding(.bottom, 1)

            if isExpanded, let children = node.children {
                FileTreeContent(nodes: children, selectedNode: $selectedNode, depth: depth + 1)
            }
        }
    }
}

// MARK: - File Row

struct FileRow: View {
    @ObservedObject var node: FileNode
    let isSelected: Bool
    let depth: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if depth > 0 {
                    Rectangle().fill(.clear).frame(width: CGFloat(depth) * 16)
                }
                Rectangle().fill(.clear).frame(width: 10)

                Image(systemName: node.role.sfSymbol)
                    .font(.system(size: 13))
                    .foregroundStyle(node.role.color)
                    .frame(width: 16)

                Text(node.name)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                if node.role != .general && node.role != .mainInstruction &&
                   node.role != .rule && node.role != .command &&
                   node.role != .agent && node.role != .skill {
                    Text(node.role.categoryLabel)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(node.role.color)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .strokeBorder(node.role.color.opacity(0.5), lineWidth: 0.5)
                                .background(Capsule().fill(node.role.color.opacity(0.08)))
                        )
                }

                if let dateStr = node.isLoadingContent ? nil : node.modifiedDateString,
                   !dateStr.isEmpty {
                    Text(dateStr)
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}

// MARK: - Right Panel Wrapper (stable type prevents HSplitView layout reset)

struct MDRightPanel: View {
    let selectedNode: FileNode?
    let onDeleted: () -> Void

    var body: some View {
        if let node = selectedNode, !node.isDirectory {
            MDContentPanel(node: node, onDeleted: onDeleted)
        } else {
            MDEmptyState()
        }
    }
}

// MARK: - Empty State

struct MDEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("ファイルを選択してください")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("左のツリーからファイルを選択すると\nプレビューと編集ができます")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
