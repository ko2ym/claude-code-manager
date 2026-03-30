import Foundation

final class SettingsService {
    static let shared = SettingsService()

    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    func load(from url: URL) -> ClaudeSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(ClaudeSettings.self, from: data)
    }

    func save(_ settings: ClaudeSettings, to url: URL) throws {
        // Backup existing file
        if FileManager.default.fileExists(atPath: url.path) {
            let backupURL = url.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: url, to: backupURL)
        }

        // Create parent directory if needed
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Remove nil fields by encoding only non-nil values
        let data = try encoder.encode(settings)
        try data.write(to: url, options: .atomic)
    }
}
