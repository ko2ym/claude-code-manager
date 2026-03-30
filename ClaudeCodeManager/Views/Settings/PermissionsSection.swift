import SwiftUI

struct PermissionsSection: View {
    @Binding var settings: ClaudeSettings

    private let defaultModes = ["default", "acceptEdits", "plan", "bypassPermissions"]

    private let allowPresets = [
        "Bash(npm run *)",
        "Bash(npm test *)",
        "Bash(npx prettier *)",
        "Bash(npx eslint *)",
        "Bash(git status)",
        "Bash(git diff *)",
        "Bash(git log *)",
        "Bash(git commit *)",
        "Bash(git *)",
        "Bash(make *)",
        "Bash(cargo *)",
        "Bash(go *)",
        "Bash(ls *)",
        "Bash(cat *)",
        "Bash(grep *)",
        "Read(*)",
    ]

    private let denyPresets = [
        "Read(~/.ssh/**)",
        "Read(~/.aws/**)",
        "Read(~/.gnupg/**)",
        "Read(.env)",
        "Read(.env.*)",
        "Read(*.env)",
        "Read(*.pem)",
        "Bash(curl *)",
        "Bash(wget *)",
        "Bash(nc *)",
        "Bash(ssh *)",
        "Bash(git push *)",
        "Bash(rm -rf *)",
        "Bash(sudo *)",
    ]

    // 記事推奨: 機密ファイル保護フルセット
    private let sensitiveFileDenyPresets = [
        "Read(~/.ssh/**)",
        "Read(~/.gnupg/**)",
        "Read(~/.aws/**)",
        "Read(~/.azure/**)",
        "Read(~/.kube/**)",
        "Read(~/.npmrc)",
        "Read(~/.git-credentials)",
        "Read(~/.config/gh/**)",
        "Edit(~/.bashrc)",
        "Edit(~/.zshrc)",
        "Read(*.env)",
        "Read(.env.*)",
    ]

    // 記事推奨: ネットワークコマンドブロック
    private let networkBlockDenyPresets = [
        "Bash(curl *)",
        "Bash(wget *)",
        "Bash(nc *)",
        "Bash(ssh *)",
        "Bash(git push *)",
    ]

    // 記事推奨: 安全な操作の自動許可
    private let safeOperationsAllowPresets = [
        "Bash(npm run *)",
        "Bash(npm test *)",
        "Bash(npx prettier *)",
        "Bash(npx eslint *)",
        "Bash(git status)",
        "Bash(git diff *)",
        "Bash(git log *)",
        "Bash(git commit *)",
        "Bash(ls *)",
        "Bash(cat *)",
        "Bash(grep *)",
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

                        Button {
                            addAllowPresets(safeOperationsAllowPresets)
                        } label: {
                            Label("安全な操作を一括許可（推奨）", systemImage: "checkmark.seal.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
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

                        VStack(alignment: .leading, spacing: 6) {
                            Text("クイック設定")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                Button {
                                    addDenyPresets(sensitiveFileDenyPresets)
                                } label: {
                                    Label("機密ファイルを一括保護", systemImage: "lock.shield.fill")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button {
                                    addDenyPresets(networkBlockDenyPresets)
                                } label: {
                                    Label("ネットワークコマンドをブロック", systemImage: "network.slash")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            Text("機密ファイル: ~/.ssh, ~/.aws, ~/.gnupg 等 + .env 系 / ネットワーク: curl, wget, nc, ssh, git push")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
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
        for preset in presets where !current.contains(preset) {
            current.append(preset)
        }
        settings.permissions?.deny = current
    }

    private func addAllowPresets(_ presets: [String]) {
        settings.ensurePermissions()
        var current = settings.permissions?.allow ?? []
        for preset in presets where !current.contains(preset) {
            current.append(preset)
        }
        settings.permissions?.allow = current
    }
}
