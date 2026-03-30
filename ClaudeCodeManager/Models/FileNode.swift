import Foundation
import SwiftUI

// MARK: - File Role

enum FileRole {
    // Markdown roles
    case mainInstruction  // CLAUDE.md
    case rule             // .claude/rules/
    case command          // .claude/commands/
    case agent            // .claude/agents/
    case skill            // .claude/skills/
    case general          // other .md

    // Config roles (new)
    case jsonConfig       // .json
    case envFile          // .env, .env.local, .env.*
    case shellConfig      // .zshrc, .bashrc, .zprofile, .gitconfig

    var emoji: String {
        switch self {
        case .mainInstruction: return "📋"
        case .rule: return "📏"
        case .command: return "⚡"
        case .agent: return "🤖"
        case .skill: return "🔧"
        case .general: return "📄"
        case .jsonConfig: return "⚙️"
        case .envFile: return "🔑"
        case .shellConfig: return "🐚"
        }
    }

    var sfSymbol: String {
        switch self {
        case .mainInstruction: return "doc.fill"
        case .rule: return "ruler"
        case .command: return "terminal"
        case .agent: return "cpu"
        case .skill: return "wrench.and.screwdriver"
        case .general: return "doc.text"
        case .jsonConfig: return "curlybraces"
        case .envFile: return "key.fill"
        case .shellConfig: return "terminal.fill"
        }
    }

    var color: Color {
        switch self {
        case .mainInstruction: return .blue
        case .rule: return .purple
        case .command: return .yellow
        case .agent: return .green
        case .skill: return .orange
        case .general: return .secondary
        case .jsonConfig: return Color(red: 0.94, green: 0.65, blue: 0.20) // amber
        case .envFile: return .red
        case .shellConfig: return Color(red: 0.20, green: 0.72, blue: 0.60) // teal
        }
    }

    var isMarkdown: Bool {
        switch self {
        case .mainInstruction, .rule, .command, .agent, .skill, .general: return true
        case .jsonConfig, .envFile, .shellConfig: return false
        }
    }

    /// 表示用のカテゴリラベル
    var categoryLabel: String {
        switch self {
        case .mainInstruction, .rule, .command, .agent, .skill, .general:
            return "Markdown"
        case .jsonConfig:
            return "JSON"
        case .envFile:
            return "ENV"
        case .shellConfig:
            return "Shell"
        }
    }
}

// MARK: - FileNode

final class FileNode: Identifiable, ObservableObject {
    let id = UUID()
    let url: URL
    var children: [FileNode]?
    @Published var content: String?
    @Published var isLoadingContent = false

    var name: String { url.lastPathComponent }
    var isDirectory: Bool { children != nil }

    var isEditable: Bool {
        let ext = url.pathExtension.lowercased()
        let name = url.lastPathComponent.lowercased()
        return ext == "md" || ext == "json" || isEnvFile || isShellConfigFile
    }

    private var isEnvFile: Bool {
        let n = url.lastPathComponent
        return n == ".env" || n.hasPrefix(".env.")
    }

    private var isShellConfigFile: Bool {
        let name = url.lastPathComponent.lowercased()
        return [".zshrc", ".zprofile", ".bashrc", ".bash_profile",
                ".gitconfig", ".gitignore"].contains(name)
    }

    var role: FileRole {
        let lname = url.lastPathComponent.lowercased()
        let path = url.path
        let ext = url.pathExtension.lowercased()

        // Shell config files
        if [".zshrc", ".zprofile", ".bashrc", ".bash_profile",
            ".gitconfig", ".gitignore_global"].contains(lname) {
            return .shellConfig
        }

        // Env files
        if lname == ".env" || lname.hasPrefix(".env.") { return .envFile }

        // JSON files
        if ext == "json" { return .jsonConfig }

        // Markdown roles
        if lname == "claude.md" || lname == "claude.local.md" { return .mainInstruction }
        if path.contains("/.claude/rules/") { return .rule }
        if path.contains("/.claude/commands/") { return .command }
        if path.contains("/.claude/agents/") { return .agent }
        if lname == "skill.md" || path.contains("/skills/") { return .skill }
        return .general
    }

    var preview: String {
        guard let content else { return "" }
        // For env files, don't show actual values
        if role == .envFile {
            let lineCount = content.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty && !$0.hasPrefix("#") }
                .count
            return "\(lineCount) 個の変数"
        }
        let lines = content.components(separatedBy: .newlines)
        let nonEmpty = lines.first(where: {
            !$0.trimmingCharacters(in: .whitespaces).isEmpty && !$0.hasPrefix("#")
        }) ?? lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? ""
        return String(nonEmpty.prefix(60))
    }

    var modifiedDate: Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    var modifiedDateString: String {
        guard let date = modifiedDate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    init(url: URL, children: [FileNode]? = nil) {
        self.url = url
        self.children = children
    }
}
