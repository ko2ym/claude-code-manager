import SwiftUI

struct MDContentPanel: View {
    @ObservedObject var node: FileNode
    var onDeleted: () -> Void

    @State private var mode: ContentMode = .preview
    @State private var editText: String = ""
    @State private var isEditDirty = false
    @State private var showDeleteAlert = false
    @State private var saveError: String?

    enum ContentMode {
        case preview, edit
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 8) {
                // Role badge
                HStack(spacing: 4) {
                    Text(node.role.emoji)
                    Text(node.name)
                        .font(.system(size: 13, weight: .semibold))
                    if isEditDirty {
                        Text("●")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }

                Spacer()

                // Mode toggle — Markdown のみプレビューあり
                if node.role.isMarkdown {
                    Picker("", selection: $mode) {
                        Label("プレビュー", systemImage: "eye").tag(ContentMode.preview)
                        Label("編集", systemImage: "pencil").tag(ContentMode.edit)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .labelsHidden()
                } else {
                    // JSON / ENV / Shell は常にエディタ
                    Text(node.role.categoryLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(node.role.color.opacity(0.1))
                        )
                }

                if mode == .edit && isEditDirty {
                    Button("保存") {
                        saveEdit()
                    }
                    .keyboardShortcut("s", modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Menu {
                    Button("削除...", role: .destructive) {
                        showDeleteAlert = true
                    }
                    Button("Finderで表示") {
                        NSWorkspace.shared.activateFileViewerSelecting([node.url])
                    }
                    Button("パスをコピー") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(node.url.path, forType: .string)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .frame(width: 20, height: 20)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            Group {
                if node.content == nil {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            FileService.shared.loadContent(for: node)
                        }
                } else if mode == .preview && node.role.isMarkdown {
                    // Markdown → レンダリングプレビュー
                    MarkdownPreviewView(content: node.content ?? "")
                } else {
                    // JSON / ENV / Shell / 編集モード → プレーンテキストエディタ
                    MarkdownEditorView(
                        text: $editText,
                        isDirty: $isEditDirty
                    )
                    .onAppear {
                        if !isEditDirty {
                            editText = node.content ?? ""
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: node.id) { _, _ in
            // Reset when different file selected
            mode = .preview
            editText = node.content ?? ""
            isEditDirty = false
        }
        .onChange(of: node.content) { _, newContent in
            if !isEditDirty {
                editText = newContent ?? ""
            }
        }
        .alert("削除の確認", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive) { deleteFile() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("「\(node.name)」を削除しますか？この操作は元に戻せません。")
        }
    }

    private func saveEdit() {
        do {
            try FileService.shared.saveContent(editText, to: node.url)
            node.content = editText
            isEditDirty = false
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func deleteFile() {
        do {
            try FileService.shared.deleteFile(at: node.url)
            onDeleted()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
