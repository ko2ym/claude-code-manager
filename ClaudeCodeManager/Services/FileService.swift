import Foundation

final class FileService {
    static let shared = FileService()

    private let fm = FileManager.default

    // MARK: - Target file detection

    /// .claude/ ディレクトリ内で対象とする拡張子
    private func isClaudeTargetFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "md" || ext == "json"
    }

    /// プロジェクトルート直下で対象とするファイル
    private func isProjectRootTargetFile(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        // .env, .env.local, .env.* など
        if name == ".env" || name.hasPrefix(".env.") { return true }
        // ルートレベルの JSON 設定ファイル（.json）
        if ext == "json" { return true }
        // Markdown ファイル全般（README.md 等）
        if ext == "md" { return true }
        return false
    }

    /// ホームディレクトリで対象とするシェル設定ファイル
    static let homeShellConfigs: [String] = [
        ".zshrc", ".zprofile", ".bashrc", ".bash_profile",
        ".gitconfig"
    ]

    // MARK: - Scan: .claude/ directory (md + json, hierarchical)

    func scanClaudeDirectory(_ url: URL, maxDepth: Int = 5) -> [FileNode] {
        scanHierarchical(url, depth: 0, maxDepth: maxDepth, fileFilter: isClaudeTargetFile)
    }

    // MARK: - Scan: project directory (md + env* + json, recursive, with hierarchy)

    private let skipDirs: Set<String> = [
        "node_modules", ".git", ".next", "dist", "build", "out",
        ".cache", "coverage", ".turbo", "vendor", "__pycache__",
        ".venv", "venv", ".tox", "target", "DerivedData"
    ]

    /// プロジェクトディレクトリを再帰スキャン（階層付き）。.claude/ と CLAUDE.md は除外
    func scanProjectDirectory(_ url: URL, maxDepth: Int = 5) -> [FileNode] {
        scanProjectHierarchical(url, depth: 0, maxDepth: maxDepth, isRoot: true)
    }

    private func isProjectTargetFile(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        if name == ".env" || name.hasPrefix(".env.") { return true }
        if ext == "json" { return true }
        if ext == "md" { return true }
        return false
    }

    // MARK: - Scan: home shell config files

    func scanHomeShellConfigs() -> [FileNode] {
        let home = fm.homeDirectoryForCurrentUser
        return Self.homeShellConfigs.compactMap { name -> FileNode? in
            let url = home.appendingPathComponent(name)
            guard fm.fileExists(atPath: url.path) else { return nil }
            return FileNode(url: url)
        }
    }

    // MARK: - Hierarchical recursive scans

    private func scanHierarchical(
        _ url: URL,
        depth: Int,
        maxDepth: Int,
        fileFilter: (URL) -> Bool
    ) -> [FileNode] {
        guard depth < maxDepth else { return [] }

        let contents = (try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        let sorted = contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
        var nodes: [FileNode] = []

        for item in sorted {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                guard !skipDirs.contains(item.lastPathComponent) else { continue }
                let children = scanHierarchical(item, depth: depth + 1, maxDepth: maxDepth, fileFilter: fileFilter)
                if !children.isEmpty {
                    nodes.append(FileNode(url: item, children: children))
                }
            } else if fileFilter(item) {
                nodes.append(FileNode(url: item))
            }
        }
        return nodes
    }

    private func scanProjectHierarchical(
        _ url: URL,
        depth: Int,
        maxDepth: Int,
        isRoot: Bool
    ) -> [FileNode] {
        guard depth < maxDepth else { return [] }

        let contents = (try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        )) ?? []

        let sorted = contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
        var nodes: [FileNode] = []

        for item in sorted {
            let name = item.lastPathComponent
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                if isRoot && name == ".claude" { continue }
                guard !skipDirs.contains(name) else { continue }
                let children = scanProjectHierarchical(item, depth: depth + 1, maxDepth: maxDepth, isRoot: false)
                if !children.isEmpty {
                    nodes.append(FileNode(url: item, children: children))
                }
            } else {
                if isRoot && name == "CLAUDE.md" { continue }
                if isProjectTargetFile(item) {
                    nodes.append(FileNode(url: item))
                }
            }
        }
        return nodes
    }

    // MARK: - Content

    func loadContent(for node: FileNode) {
        guard !node.isDirectory else { return }
        node.isLoadingContent = true
        DispatchQueue.global(qos: .userInitiated).async {
            let text = (try? String(contentsOf: node.url, encoding: .utf8)) ?? ""
            DispatchQueue.main.async {
                node.content = text
                node.isLoadingContent = false
            }
        }
    }

    func saveContent(_ content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func createFile(at url: URL, content: String = "") throws {
        let dir = url.deletingLastPathComponent()
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func deleteFile(at url: URL) throws {
        try fm.removeItem(at: url)
    }

    func renameFile(at url: URL, to newName: String) throws -> URL {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        try fm.moveItem(at: url, to: newURL)
        return newURL
    }
}
