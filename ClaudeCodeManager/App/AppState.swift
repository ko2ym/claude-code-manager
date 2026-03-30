import SwiftUI
import Foundation

// MARK: - Navigation types

enum AppTab: String, CaseIterable {
    case settings = "設定"
    case mcp = "MCP"
    case mdFiles = "ファイル"

    var icon: String {
        switch self {
        case .settings: return "gearshape"
        case .mcp: return "server.rack"
        case .mdFiles: return "doc.text"
        }
    }
}

enum SidebarSelection: Hashable {
    case global
    case project(UUID)
}

struct ProjectEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var path: String

    var name: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var settingsURL: URL {
        URL(fileURLWithPath: path).appendingPathComponent(".claude/settings.json")
    }

    var localSettingsURL: URL {
        URL(fileURLWithPath: path).appendingPathComponent(".claude/settings.local.json")
    }

    var mcpURL: URL {
        URL(fileURLWithPath: path).appendingPathComponent(".mcp.json")
    }

    var claudeDir: URL {
        URL(fileURLWithPath: path).appendingPathComponent(".claude")
    }

    var hasClaudeDir: Bool {
        FileManager.default.fileExists(atPath: claudeDir.path)
    }

    /// プロジェクトファイルから検出されたMCPプリセット候補（presetName順）
    var detectedMCPPresets: [MCPPreset] {
        let fm = FileManager.default
        let base = URL(fileURLWithPath: path)

        func exists(_ rel: String) -> Bool {
            fm.fileExists(atPath: base.appendingPathComponent(rel).path)
        }

        var names: [String] = []
        if exists(".vercel/project.json")              { names.append("vercel") }
        if exists("firebase.json") || exists(".firebaserc") { names.append("firebase") }
        if exists("supabase")                          { names.append("supabase") }
        if exists(".github")                           { names.append("github") }
        if exists("notion.json") || exists(".notion")  { names.append("notion") }

        return names.compactMap { name in MCPPreset.all.first(where: { $0.name == name }) }
    }
}

// MARK: - AppState

@Observable
final class AppState {
    var sidebarSelection: SidebarSelection = .global
    var selectedTab: AppTab = .settings
    var projects: [ProjectEntry] = []
    var isDirty: Bool = false

    // Settings per scope
    var globalSettings: ClaudeSettings = ClaudeSettings()
    var projectSettings: [UUID: ClaudeSettings] = [:]

    // MCP per scope
    var globalMCPConfig: MCPConfig = MCPConfig()
    var projectMCPConfigs: [UUID: MCPConfig] = [:]

    // MD file nodes per scope
    var globalFileNodes: [FileNode] = []
    var projectFileNodes: [UUID: [FileNode]] = [:]

    init() {
        loadProjects()
        loadGlobal()
    }

    // MARK: - Current scope accessors

    var currentProject: ProjectEntry? {
        if case .project(let id) = sidebarSelection {
            return projects.first(where: { $0.id == id })
        }
        return nil
    }

    var currentSettings: ClaudeSettings {
        get {
            switch sidebarSelection {
            case .global: return globalSettings
            case .project(let id): return projectSettings[id] ?? ClaudeSettings()
            }
        }
        set {
            switch sidebarSelection {
            case .global:
                globalSettings = newValue
            case .project(let id):
                projectSettings[id] = newValue
            }
            isDirty = true
        }
    }

    var currentMCPConfig: MCPConfig {
        get {
            switch sidebarSelection {
            case .global: return globalMCPConfig
            case .project(let id): return projectMCPConfigs[id] ?? MCPConfig()
            }
        }
        set {
            switch sidebarSelection {
            case .global:
                globalMCPConfig = newValue
            case .project(let id):
                projectMCPConfigs[id] = newValue
            }
            isDirty = true
        }
    }

    var currentFileNodes: [FileNode] {
        switch sidebarSelection {
        case .global: return globalFileNodes
        case .project(let id): return projectFileNodes[id] ?? []
        }
    }

    // MARK: - Scope label

    var scopeLabel: String {
        switch sidebarSelection {
        case .global: return "Global"
        case .project(let id):
            return projects.first(where: { $0.id == id })?.name ?? "Project"
        }
    }

    // MARK: - Load

    func loadGlobal() {
        let home = FileManager.default.homeDirectoryForCurrentUser

        // Settings
        let settingsURL = home.appendingPathComponent(".claude/settings.json")
        globalSettings = SettingsService.shared.load(from: settingsURL) ?? ClaudeSettings()

        // MCP
        let mcpURL = home.appendingPathComponent(".claude.json")
        globalMCPConfig = MCPService.shared.loadUserMCP(from: mcpURL) ?? MCPConfig()

        // Files
        var nodes: [FileNode] = []

        // CLAUDE.md in home
        let claudeMD = home.appendingPathComponent("CLAUDE.md")
        if FileManager.default.fileExists(atPath: claudeMD.path) {
            nodes.append(FileNode(url: claudeMD))
        }

        // ~/.claude/ directory (md + json)
        let claudeDir = home.appendingPathComponent(".claude")
        if FileManager.default.fileExists(atPath: claudeDir.path) {
            nodes.append(contentsOf: FileService.shared.scanClaudeDirectory(claudeDir))
        }

        // Shell config files (.zshrc, .gitconfig, etc.)
        let shellConfigs = FileService.shared.scanHomeShellConfigs()
        if !shellConfigs.isEmpty {
            nodes.append(FileNode(url: home, children: shellConfigs))  // "~" ディレクトリノード
        }

        globalFileNodes = nodes
    }

    func loadProject(_ project: ProjectEntry) {
        // Settings
        projectSettings[project.id] = SettingsService.shared.load(from: project.settingsURL) ?? ClaudeSettings()

        // MCP
        projectMCPConfigs[project.id] = MCPService.shared.loadProjectMCP(from: project.mcpURL) ?? MCPConfig()

        // Files
        let projectURL = URL(fileURLWithPath: project.path)
        var nodes: [FileNode] = []

        // CLAUDE.md in project root
        let claudeMD = projectURL.appendingPathComponent("CLAUDE.md")
        if FileManager.default.fileExists(atPath: claudeMD.path) {
            nodes.append(FileNode(url: claudeMD))
        }

        // .claude/ directory (md + json)
        let claudeDir = projectURL.appendingPathComponent(".claude")
        if FileManager.default.fileExists(atPath: claudeDir.path) {
            nodes.append(contentsOf: FileService.shared.scanClaudeDirectory(claudeDir))
        }

        // プロジェクト全体を再帰スキャン（.md / .env* / .json、ディレクトリ階層付き）
        // .claude/ と CLAUDE.md は scanProjectDirectory 内で除外済み
        let projectFiles = FileService.shared.scanProjectDirectory(projectURL)
        nodes.append(contentsOf: projectFiles)

        projectFileNodes[project.id] = nodes
    }

    func reloadCurrentScope() {
        switch sidebarSelection {
        case .global:
            loadGlobal()
        case .project(let id):
            if let project = projects.first(where: { $0.id == id }) {
                loadProject(project)
            }
        }
        isDirty = false
    }

    // MARK: - Save

    func saveSettings() throws {
        switch sidebarSelection {
        case .global:
            let url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude/settings.json")
            try SettingsService.shared.save(globalSettings, to: url)
        case .project(let id):
            guard let project = projects.first(where: { $0.id == id }),
                  let settings = projectSettings[id] else { return }
            try SettingsService.shared.save(settings, to: project.settingsURL)
        }
        isDirty = false
    }

    func saveMCPConfig() throws {
        switch sidebarSelection {
        case .global:
            let url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".claude.json")
            try MCPService.shared.save(globalMCPConfig, to: url)
        case .project(let id):
            guard let project = projects.first(where: { $0.id == id }),
                  let config = projectMCPConfigs[id] else { return }
            try MCPService.shared.save(config, to: project.mcpURL)
        }
        isDirty = false
    }

    // MARK: - Project management

    func addProject(path: String) {
        guard !projects.contains(where: { $0.path == path }) else {
            // Select existing
            if let existing = projects.first(where: { $0.path == path }) {
                sidebarSelection = .project(existing.id)
            }
            return
        }

        let entry = ProjectEntry(path: path)
        projects.insert(entry, at: 0)
        if projects.count > 10 { projects = Array(projects.prefix(10)) }
        persistProjects()
        loadProject(entry)
        sidebarSelection = .project(entry.id)
    }

    func removeProject(_ entry: ProjectEntry) {
        projects.removeAll(where: { $0.id == entry.id })
        projectSettings.removeValue(forKey: entry.id)
        projectMCPConfigs.removeValue(forKey: entry.id)
        projectFileNodes.removeValue(forKey: entry.id)
        persistProjects()

        if case .project(let id) = sidebarSelection, id == entry.id {
            sidebarSelection = .global
        }
    }

    private func loadProjects() {
        guard let data = UserDefaults.standard.data(forKey: "ccm_projects"),
              let entries = try? JSONDecoder().decode([ProjectEntry].self, from: data)
        else { return }

        projects = entries
        projects.forEach { loadProject($0) }
    }

    private func persistProjects() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: "ccm_projects")
        }
    }
}
