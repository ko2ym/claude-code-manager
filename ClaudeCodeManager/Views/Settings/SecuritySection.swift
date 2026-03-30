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
