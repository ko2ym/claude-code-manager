import SwiftUI

struct PermissionsSection: View {
    @Binding var settings: ClaudeSettings

    private let defaultModes = ["default", "acceptEdits", "plan", "bypassPermissions"]

    private let allowPresets = [
        "Bash(npm run *)",
        "Bash(git *)",
        "Bash(make *)",
        "Bash(cargo *)",
        "Bash(go *)",
        "Read(*)",
    ]

    private let denyPresets = [
        "Read(.env)",
        "Read(*.pem)",
        "Bash(rm -rf *)",
        "Bash(sudo *)",
        "Bash(curl * | bash)",
        "Bash(wget * | sh)",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "権限設定", icon: "lock.shield")

            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Allow — 確認なしで実行")
                                .font(.headline)
                        }
                        Text("登録したパターンに一致するツール/コマンドは確認なしで実行されます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TagEditor(
                            items: Binding(
                                get: { settings.permissions?.allow ?? [] },
                                set: { v in
                                    settings.ensurePermissions()
                                    settings.permissions?.allow = v.isEmpty ? nil : v
                                }
                            ),
                            placeholder: "例: Bash(npm run *)",
                            presets: allowPresets
                        )
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("Deny — 完全ブロック")
                                .font(.headline)
                        }
                        Text("登録したパターンは常にブロックされます。Allow より優先されます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TagEditor(
                            items: Binding(
                                get: { settings.permissions?.deny ?? [] },
                                set: { v in
                                    settings.ensurePermissions()
                                    settings.permissions?.deny = v.isEmpty ? nil : v
                                }
                            ),
                            placeholder: "例: Read(.env)",
                            presets: denyPresets
                        )

                        HStack(spacing: 8) {
                            Button {
                                addDenyPresets(["Read(.env)", "Read(*.pem)", "Read(*.key)"])
                            } label: {
                                Label(".envファイル保護", systemImage: "lock.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button {
                                addDenyPresets(["Bash(sudo *)", "Bash(rm -rf *)", "Bash(curl * | bash)"])
                            } label: {
                                Label("危険コマンドブロック", systemImage: "exclamationmark.triangle.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Ask — 都度確認")
                                .font(.headline)
                        }
                        Text("登録したパターンは実行前に確認ダイアログを表示します。")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TagEditor(
                            items: Binding(
                                get: { settings.permissions?.ask ?? [] },
                                set: { v in
                                    settings.ensurePermissions()
                                    settings.permissions?.ask = v.isEmpty ? nil : v
                                }
                            ),
                            placeholder: "例: Bash(git push *)"
                        )
                    }
                }

                Section("デフォルトモード") {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("", selection: Binding(
                            get: { settings.permissions?.defaultMode ?? "default" },
                            set: { v in
                                settings.ensurePermissions()
                                settings.permissions?.defaultMode = v
                            }
                        )) {
                            ForEach(defaultModes, id: \.self) { mode in
                                Text(mode).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Group {
                            switch settings.permissions?.defaultMode ?? "default" {
                            case "acceptEdits":
                                Text("ファイル編集を自動承認します（コマンド実行は要確認）")
                            case "plan":
                                Text("すべての操作で計画モードを使用します")
                            case "bypassPermissions":
                                Text("⚠️ すべての権限チェックをバイパスします（開発時のみ推奨）")
                                    .foregroundStyle(.orange)
                            default:
                                Text("標準モード: ファイル編集・コマンドを個別に確認します")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Section("追加アクセスディレクトリ") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("プロジェクト外でアクセスを許可するディレクトリ")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TagEditor(
                            items: Binding(
                                get: { settings.permissions?.additionalDirectories ?? [] },
                                set: { v in
                                    settings.ensurePermissions()
                                    settings.permissions?.additionalDirectories = v.isEmpty ? nil : v
                                }
                            ),
                            placeholder: "例: /Users/me/shared-docs"
                        )
                    }
                }
            }
            .formStyle(.grouped)
        }
    }

    private func addDenyPresets(_ presets: [String]) {
        settings.ensurePermissions()
        var current = settings.permissions?.deny ?? []
        for preset in presets {
            if !current.contains(preset) {
                current.append(preset)
            }
        }
        settings.permissions?.deny = current
    }
}
