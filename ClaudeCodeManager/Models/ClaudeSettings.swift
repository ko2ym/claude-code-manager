import Foundation

struct ClaudeSettings: Codable, Equatable {

    // MARK: - Model
    var model: String?
    var effortLevel: String?
    var alwaysThinkingEnabled: Bool?
    var availableModels: [String]?
    var language: String?
    var outputStyle: String?
    var plansDirectory: String?
    var autoUpdates: Bool?

    // MARK: - Session
    var cleanupPeriodDays: Int?
    var companyAnnouncements: [String]?

    // MARK: - Display / UX
    var spinnerTipsEnabled: Bool?
    var spinnerTipsOverride: SpinnerTipsOverride?
    var spinnerVerbs: [String]?
    var terminalProgressBarEnabled: Bool?
    var showTurnDuration: Bool?
    var prefersReducedMotion: Bool?
    var statusLine: String?

    // MARK: - Attribution
    var attribution: Attribution?
    var includeCoAuthoredBy: Bool?

    // MARK: - Permissions
    var permissions: Permissions?

    // MARK: - Hooks
    var hooks: CodableAny?
    var disableAllHooks: Bool?

    // MARK: - Sandbox
    var sandbox: Sandbox?

    // MARK: - Env
    var env: [String: String]?

    // MARK: - Worktree
    var worktree: Worktree?

    // MARK: - Agent Teams
    var teammateMode: String?

    // MARK: - MCP control (settings.json level)
    var enableAllProjectMcpServers: Bool?
    var enabledMcpjsonServers: [String]?
    var disabledMcpjsonServers: [String]?

    // MARK: - API / Auth
    var apiKeyHelper: String?
    var otelHeadersHelper: String?
    var forceLoginMethod: String?
    var forceLoginOrgUUID: String?

    // MARK: - File suggestion
    var fileSuggestion: String?

    // MARK: - AWS (advanced)
    var awsAuthRefresh: String?
    var awsCredentialExport: String?

    // MARK: - Nested types

    struct Attribution: Codable, Equatable {
        var commits: Bool?
        var pr: Bool?
    }

    struct Permissions: Codable, Equatable {
        var allow: [String]?
        var ask: [String]?
        var deny: [String]?
        var defaultMode: String?
        var disableBypassPermissionsMode: String?
        var additionalDirectories: [String]?
    }

    struct Sandbox: Codable, Equatable {
        var enabled: Bool?
        var autoAllowBashIfSandboxed: Bool?
        var excludedCommands: [String]?
        var allowUnsandboxedCommands: Bool?
        var network: SandboxNetwork?
        var filesystem: SandboxFilesystem?

        struct SandboxNetwork: Codable, Equatable {
            var allowedDomains: [String]?
            var allowLocalBinding: Bool?
        }

        struct SandboxFilesystem: Codable, Equatable {
            var denyRead: [String]?
        }
    }

    struct Worktree: Codable, Equatable {
        var sparsePaths: [String]?
    }

    struct SpinnerTipsOverride: Codable, Equatable {
        var tips: [String]?
        var mergeWithDefaults: Bool?
    }

    // MARK: - Convenience accessors

    mutating func ensurePermissions() {
        if permissions == nil { permissions = Permissions() }
    }

    mutating func ensureAttribution() {
        if attribution == nil { attribution = Attribution() }
    }

    mutating func ensureSandbox() {
        if sandbox == nil { sandbox = Sandbox() }
    }

    mutating func ensureSandboxNetwork() {
        ensureSandbox()
        if sandbox?.network == nil { sandbox?.network = Sandbox.SandboxNetwork() }
    }

    mutating func ensureSandboxFilesystem() {
        ensureSandbox()
        if sandbox?.filesystem == nil { sandbox?.filesystem = Sandbox.SandboxFilesystem() }
    }

    // MARK: - Agent Teams helpers

    var agentTeamsEnabled: Bool {
        get { env?["CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"] == "1" }
        set {
            if env == nil { env = [:] }
            if newValue {
                env?["CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"] = "1"
            } else {
                env?.removeValue(forKey: "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS")
                if env?.isEmpty == true { env = nil }
            }
        }
    }
}

// MARK: - CodableAny (hooks フィールドなど任意JSON用)

struct CodableAny: Codable, Equatable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v }
        else if let v = try? container.decode(Int.self) { value = v }
        else if let v = try? container.decode(Double.self) { value = v }
        else if let v = try? container.decode(String.self) { value = v }
        else if let v = try? container.decode([String: CodableAny].self) { value = v }
        else if let v = try? container.decode([CodableAny].self) { value = v }
        else { value = NSNull() }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [String: CodableAny]: try container.encode(v)
        case let v as [CodableAny]: try container.encode(v)
        default: try container.encodeNil()
        }
    }

    static func == (lhs: CodableAny, rhs: CodableAny) -> Bool { true } // hooks 比較は常にtrue
}
