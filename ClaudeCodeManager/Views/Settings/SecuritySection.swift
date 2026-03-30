import SwiftUI

struct SecuritySection: View {
    @Binding var settings: ClaudeSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "セキュリティ設定", icon: "shield.checkerboard")

            Form {
                // MARK: - Sandbox
                Section {
                    Toggle(isOn: Binding(
                        get: { settings.sandbox?.enabled ?? false },
                        set: { v in
                            settings.ensureSandbox()
                            settings.sandbox?.enabled = v
                        }
                    )) {
                        SettingRow(label: "サンドボックスモードを有効化",
                                   key: "sandbox.enabled",
                                   description: "Bash コマンドをサンドボックス内で実行しリソースアクセスを制限")
                    }

                    if settings.sandbox?.enabled == true {
                        Toggle(isOn: Binding(
                            get: { settings.sandbox?.autoAllowBashIfSandboxed ?? false },
                            set: { v in
                                settings.ensureSandbox()
                                settings.sandbox?.autoAllowBashIfSandboxed = v
                            }
                        )) {
                            SettingRow(label: "サンドボックス内 Bash を自動許可",
                                       key: "sandbox.autoAllowBashIfSandboxed")
                        }

                        Toggle(isOn: Binding(
                            get: { !(settings.sandbox?.allowUnsandboxedCommands ?? true) },
                            set: { v in
                                settings.ensureSandbox()
                                settings.sandbox?.allowUnsandboxedCommands = !v
                            }
                        )) {
                            SettingRow(label: "サンドボックス外コマンドを禁止",
                                       key: "sandbox.allowUnsandboxedCommands = false",
                                       description: "dangerouslyDisableSandbox の抜け道を封鎖（組織ポリシー向け）")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SettingRow(label: "サンドボックス除外コマンド",
                                       key: "sandbox.excludedCommands",
                                       description: "サンドボックス外で実行したいコマンド (例: git, docker)")
                            TagEditor(
                                items: Binding(
                                    get: { settings.sandbox?.excludedCommands ?? [] },
                                    set: { v in
                                        settings.ensureSandbox()
                                        settings.sandbox?.excludedCommands = v.isEmpty ? nil : v
                                    }
                                ),
                                placeholder: "例: git",
                                presets: ["git", "docker", "brew", "make"]
                            )
                        }
                    }
                } header: {
                    Text("サンドボックス")
                }

                // MARK: - Sandbox filesystem
                if settings.sandbox?.enabled == true {
                    Section("サンドボックス ファイルシステム保護") {
                        VStack(alignment: .leading, spacing: 8) {
                            SettingRow(label: "読み取り拒否パス (sandbox.filesystem.denyRead)",
                                       key: "sandbox.filesystem.denyRead",
                                       description: "サンドボックス内プロセスからも読み取れないパス。AIが動かすプログラムからも .env 等を隠す")
                            TagEditor(
                                items: Binding(
                                    get: { settings.sandbox?.filesystem?.denyRead ?? [] },
                                    set: { v in
                                        settings.ensureSandboxFilesystem()
                                        settings.sandbox?.filesystem?.denyRead = v.isEmpty ? nil : v
                                    }
                                ),
                                placeholder: "例: ./.env",
                                presets: ["./.env", "./.env.*", "./.env.local", "./.env.production"]
                            )
                            Button {
                                settings.ensureSandboxFilesystem()
                                var current = settings.sandbox?.filesystem?.denyRead ?? []
                                for path in ["./.env", "./.env.*"] where !current.contains(path) {
                                    current.append(path)
                                }
                                settings.sandbox?.filesystem?.denyRead = current
                            } label: {
                                Label(".env 系を一括追加", systemImage: "lock.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                // MARK: - Network (sandbox)
                if settings.sandbox?.enabled == true {
                    Section("ネットワーク制御 (sandbox.network)") {
                        Toggle(isOn: Binding(
                            get: { settings.sandbox?.network?.allowLocalBinding ?? true },
                            set: { v in
                                settings.ensureSandboxNetwork()
                                settings.sandbox?.network?.allowLocalBinding = v
                            }
                        )) {
                            SettingRow(label: "ローカルバインドを許可",
                                       key: "sandbox.network.allowLocalBinding")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            SettingRow(label: "アウトバウンド許可ドメイン",
                                       key: "sandbox.network.allowedDomains",
                                       description: "ワイルドカード可 例: *.npmjs.org")
                            TagEditor(
                                items: Binding(
                                    get: { settings.sandbox?.network?.allowedDomains ?? [] },
                                    set: { v in
                                        settings.ensureSandboxNetwork()
                                        settings.sandbox?.network?.allowedDomains = v.isEmpty ? nil : v
                                    }
                                ),
                                placeholder: "例: github.com",
                                presets: ["github.com", "*.npmjs.org", "registry.npmjs.org",
                                          "pypi.org", "crates.io"]
                            )
                        }
                    }
                }

                // MARK: - Telemetry
                Section("テレメトリ・自動更新") {
                    Toggle(isOn: Binding(
                        get: { (settings.env?["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] ?? "0") == "1" },
                        set: { enabled in
                            if settings.env == nil { settings.env = [:] }
                            if enabled {
                                settings.env?["CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"] = "1"
                            } else {
                                settings.env?.removeValue(forKey: "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC")
                                if settings.env?.isEmpty == true { settings.env = nil }
                            }
                        }
                    )) {
                        SettingRow(label: "テレメトリ・自動更新を無効化",
                                   key: "env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC",
                                   description: "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 を env に設定")
                    }
                }

                // MARK: - Hooks
                Section("Hooks") {
                    Toggle(isOn: Binding(
                        get: { settings.disableAllHooks ?? false },
                        set: { settings.disableAllHooks = $0 }
                    )) {
                        SettingRow(label: "すべての Hooks を無効化",
                                   key: "disableAllHooks",
                                   description: "hooks と statusLine を含むすべてのカスタムコマンドを無効化。トラブルシュート時に便利")
                    }
                }

                // MARK: - MCP auto-load
                Section("MCP 自動読み込み") {
                    Toggle(isOn: Binding(
                        get: { !(settings.enableAllProjectMcpServers ?? true) },
                        set: { settings.enableAllProjectMcpServers = !$0 }
                    )) {
                        SettingRow(label: "プロジェクト MCP を自動有効化しない",
                                   key: "enableAllProjectMcpServers: false",
                                   description: "新しいプロジェクトを開いたとき .mcp.json の設定を自動で読み込まない。Check Point 推奨（2026年2月の悪意ある MCP インジェクション対策）")
                    }
                }

                // MARK: - Bypass permissions
                Section("バイパス権限モード") {
                    Toggle(isOn: Binding(
                        get: { settings.permissions?.disableBypassPermissionsMode == "disable" },
                        set: { v in
                            settings.ensurePermissions()
                            settings.permissions?.disableBypassPermissionsMode = v ? "disable" : nil
                        }
                    )) {
                        SettingRow(label: "バイパス権限モードを無効化",
                                   key: "permissions.disableBypassPermissionsMode",
                                   description: "bypass モードへの切替を防止（組織向けセキュリティ強化）")
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}
