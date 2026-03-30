import Foundation

struct MCPConfig: Codable, Equatable {
    var mcpServers: [String: MCPServer]?

    var serverList: [MCPServer] {
        guard let servers = mcpServers else { return [] }
        return servers.map { key, value in
            var s = value
            s.name = key
            return s
        }.sorted { $0.name < $1.name }
    }

    mutating func addServer(_ server: MCPServer) {
        if mcpServers == nil { mcpServers = [:] }
        mcpServers?[server.name] = server
    }

    mutating func removeServer(named name: String) {
        mcpServers?.removeValue(forKey: name)
    }

    mutating func toggleServer(named name: String) {
        // MCP toggle: remove or restore — for simplicity we track disabled list
    }
}

struct MCPServer: Codable, Equatable, Identifiable {
    var id: String { name }
    var name: String = ""
    var type: String?
    var command: String?
    var args: [String]?
    var env: [String: String]?
    var url: String?
    var headers: [String: String]?

    enum CodingKeys: String, CodingKey {
        case type, command, args, env, url, headers
    }

    var displayType: String {
        if let t = type { return t }
        return url != nil ? "http" : "stdio"
    }

    var typeColor: String {
        switch displayType {
        case "stdio": return "blue"
        case "http": return "green"
        case "sse": return "orange"
        default: return "gray"
        }
    }
}

// MARK: - Presets

struct MCPPreset {
    let name: String
    let displayName: String
    let description: String
    let server: MCPServer
    /// server.env のキー → .env.local / .env で探す環境変数名の候補リスト
    let envFillKeys: [String: [String]]
    /// args 内のフラグ → .env.local / .env で探す環境変数名の候補リスト
    /// "--flag value" 形式: key="--flag", value=["ENV_KEY"]
    /// "--flag=value" 形式: key="--flag=" (prefix), value=["ENV_KEY"]
    let argFillKeys: [String: [String]]

    init(name: String, displayName: String, description: String,
         server: MCPServer,
         envFillKeys: [String: [String]] = [:],
         argFillKeys: [String: [String]] = [:]) {
        self.name = name
        self.displayName = displayName
        self.description = description
        self.server = server
        self.envFillKeys = envFillKeys
        self.argFillKeys = argFillKeys
    }

    // MARK: - .env.local parsing

    static func parseEnvFile(at projectPath: String) -> [String: String] {
        var result: [String: String] = [:]
        for filename in [".env.local", ".env"] {
            let path = URL(fileURLWithPath: projectPath).appendingPathComponent(filename).path
            guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            for line in content.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }
                let parts = trimmed.split(separator: "=", maxSplits: 1)
                guard parts.count == 2 else { continue }
                let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let val = String(parts[1]).trimmingCharacters(in: .whitespaces)
                if result[key] == nil { result[key] = val }   // .env.local takes priority
            }
        }
        return result
    }

    /// プロジェクトの .env.local から値を解決して MCPServer を返す
    func resolved(fromProjectPath projectPath: String) -> MCPServer {
        let envVars = MCPPreset.parseEnvFile(at: projectPath)
        return resolved(fromEnvVars: envVars)
    }

    func resolved(fromEnvVars envVars: [String: String]) -> MCPServer {
        var s = server

        // Fill server.env values
        if !envFillKeys.isEmpty, var env = s.env {
            for (serverKey, candidates) in envFillKeys {
                if let found = candidates.compactMap({ envVars[$0] }).first(where: { !$0.isEmpty }) {
                    env[serverKey] = found
                }
            }
            s.env = env
        }

        // Fill args
        if !argFillKeys.isEmpty, var args = s.args {
            for (flag, candidates) in argFillKeys {
                guard let found = candidates.compactMap({ envVars[$0] }).first(where: { !$0.isEmpty }) else { continue }
                if flag.hasSuffix("=") {
                    // "--flag=value" style
                    if let idx = args.firstIndex(where: { $0.hasPrefix(flag) }) {
                        args[idx] = flag + found
                    }
                } else {
                    // "--flag value" style: flag is followed by empty string placeholder
                    if let idx = args.firstIndex(of: flag), idx + 1 < args.count {
                        args[idx + 1] = found
                    }
                }
            }
            s.args = args
        }

        return s
    }

    /// envVarsを使って補完されたフィールドのキーセットを返す（UI表示用）
    func autoFilledKeys(fromProjectPath projectPath: String) -> Set<String> {
        let envVars = MCPPreset.parseEnvFile(at: projectPath)
        var filled = Set<String>()
        for (serverKey, candidates) in envFillKeys {
            if candidates.compactMap({ envVars[$0] }).first(where: { !$0.isEmpty }) != nil {
                filled.insert(serverKey)
            }
        }
        for (flag, candidates) in argFillKeys {
            if candidates.compactMap({ envVars[$0] }).first(where: { !$0.isEmpty }) != nil {
                filled.insert(flag)
            }
        }
        return filled
    }

    static let all: [MCPPreset] = [
        MCPPreset(
            name: "github",
            displayName: "GitHub MCP",
            description: "GitHubリポジトリ・Issue・PR操作",
            server: MCPServer(
                name: "github",
                type: "stdio",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-github"],
                env: ["GITHUB_PERSONAL_ACCESS_TOKEN": ""]
            ),
            envFillKeys: ["GITHUB_PERSONAL_ACCESS_TOKEN": ["GITHUB_TOKEN", "GITHUB_PERSONAL_ACCESS_TOKEN"]]
        ),
        MCPPreset(
            name: "filesystem",
            displayName: "Filesystem MCP",
            description: "ファイルシステムアクセス",
            server: MCPServer(
                name: "filesystem",
                type: "stdio",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-filesystem", "/Users"],
                env: nil
            )
        ),
        MCPPreset(
            name: "supabase",
            displayName: "Supabase MCP",
            description: "Supabaseデータベース操作",
            server: MCPServer(
                name: "supabase",
                type: "stdio",
                command: "npx",
                args: ["-y", "@supabase/mcp-server-supabase@latest", "--access-token", ""],
                env: nil
            ),
            argFillKeys: ["--access-token": ["SUPABASE_ACCESS_TOKEN", "SUPABASE_SERVICE_ROLE_KEY"]]
        ),
        MCPPreset(
            name: "slack",
            displayName: "Slack MCP",
            description: "Slackメッセージ操作",
            server: MCPServer(
                name: "slack",
                type: "stdio",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-slack"],
                env: ["SLACK_BOT_TOKEN": "", "SLACK_TEAM_ID": ""]
            ),
            envFillKeys: [
                "SLACK_BOT_TOKEN": ["SLACK_BOT_TOKEN"],
                "SLACK_TEAM_ID": ["SLACK_TEAM_ID"]
            ]
        ),
        MCPPreset(
            name: "notebooklm",
            displayName: "NotebookLM MCP",
            description: "Google NotebookLM連携",
            server: MCPServer(
                name: "notebooklm",
                type: "stdio",
                command: "nlm",
                args: ["mcp"],
                env: nil
            )
        ),
        MCPPreset(
            name: "brave-search",
            displayName: "Brave Search MCP",
            description: "Brave Search APIによるWeb検索",
            server: MCPServer(
                name: "brave-search",
                type: "stdio",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-brave-search"],
                env: ["BRAVE_API_KEY": ""]
            ),
            envFillKeys: ["BRAVE_API_KEY": ["BRAVE_API_KEY"]]
        ),
        MCPPreset(
            name: "drawio",
            displayName: "Draw.io MCP",
            description: "Draw.ioダイアグラムの作成・編集",
            server: MCPServer(
                name: "drawio",
                type: "stdio",
                command: "npx",
                args: ["-y", "@paulohefagundes/drawio-mcp-server"],
                env: nil
            )
        ),
        MCPPreset(
            name: "sequential-thinking",
            displayName: "Sequential Thinking MCP",
            description: "段階的な思考プロセスのサポート",
            server: MCPServer(
                name: "sequential-thinking",
                type: "stdio",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-sequential-thinking"],
                env: nil
            )
        ),
        MCPPreset(
            name: "puppeteer",
            displayName: "Puppeteer MCP",
            description: "ブラウザ自動操作・スクレイピング",
            server: MCPServer(
                name: "puppeteer",
                type: "stdio",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-puppeteer"],
                env: nil
            )
        ),
        MCPPreset(
            name: "notion",
            displayName: "Notion MCP",
            description: "Notionページ・データベース操作",
            server: MCPServer(
                name: "notion",
                type: "stdio",
                command: "npx",
                args: ["-y", "@notionhq/notion-mcp-server"],
                env: ["OPENAPI_MCP_HEADERS": "{\"Authorization\": \"Bearer \", \"Notion-Version\": \"2022-06-28\"}"]
            ),
            envFillKeys: ["NOTION_API_KEY": ["NOTION_API_KEY", "NOTION_TOKEN"]]
        ),
        MCPPreset(
            name: "memory-bank",
            displayName: "Memory Bank MCP",
            description: "会話を超えた永続的な記憶管理",
            server: MCPServer(
                name: "memory-bank",
                type: "stdio",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-memory"],
                env: nil
            )
        ),
        MCPPreset(
            name: "figma",
            displayName: "Figma MCP",
            description: "FigmaデザインファイルへのアクセスとUI情報取得",
            server: MCPServer(
                name: "figma",
                type: "stdio",
                command: "npx",
                args: ["-y", "figma-developer-mcp", "--figma-api-key=", "--stdio"],
                env: nil
            ),
            argFillKeys: ["--figma-api-key=": ["FIGMA_API_KEY", "FIGMA_TOKEN"]]
        ),
        MCPPreset(
            name: "markitdown",
            displayName: "Markitdown MCP",
            description: "各種ファイルをMarkdownに変換 (PDF, Office等)",
            server: MCPServer(
                name: "markitdown",
                type: "stdio",
                command: "uvx",
                args: ["markitdown-mcp"],
                env: nil
            )
        ),
        MCPPreset(
            name: "youtube",
            displayName: "YouTube MCP",
            description: "YouTube動画の字幕・情報取得",
            server: MCPServer(
                name: "youtube",
                type: "stdio",
                command: "npx",
                args: ["-y", "@kimtaeyoon83/mcp-server-youtube-transcript"],
                env: nil
            )
        ),
        MCPPreset(
            name: "firebase",
            displayName: "Firebase MCP",
            description: "Firebase/Firestoreデータベース操作",
            server: MCPServer(
                name: "firebase",
                type: "stdio",
                command: "npx",
                args: ["-y", "firebase-tools@latest", "experimental:mcp"],
                env: nil
            )
        ),
        MCPPreset(
            name: "vercel",
            displayName: "Vercel MCP",
            description: "Vercelデプロイ・プロジェクト管理",
            server: MCPServer(
                name: "vercel",
                type: "stdio",
                command: "npx",
                args: ["-y", "@vercel/mcp-adapter"],
                env: ["VERCEL_TOKEN": ""]
            ),
            envFillKeys: ["VERCEL_TOKEN": ["VERCEL_TOKEN", "VERCEL_ACCESS_TOKEN"]]
        ),
    ]
}
