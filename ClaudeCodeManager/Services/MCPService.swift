import Foundation

final class MCPService {
    static let shared = MCPService()

    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    /// Load from .mcp.json (project scope)
    func loadProjectMCP(from url: URL) -> MCPConfig? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(MCPConfig.self, from: data)
    }

    /// Load from ~/.claude.json (user scope — has additional fields)
    func loadUserMCP(from url: URL) -> MCPConfig? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let serversAny = json["mcpServers"],
              let serversData = try? JSONSerialization.data(withJSONObject: ["mcpServers": serversAny])
        else { return nil }
        return try? decoder.decode(MCPConfig.self, from: serversData)
    }

    func save(_ config: MCPConfig, to url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            let backupURL = url.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: url, to: backupURL)
        }

        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let data = try encoder.encode(config)
        try data.write(to: url, options: .atomic)
    }
}
