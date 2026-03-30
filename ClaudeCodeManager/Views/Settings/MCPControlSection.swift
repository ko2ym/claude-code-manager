import SwiftUI

/// settings.json レベルの MCP 制御設定（.mcp.json のサーバー管理は MCP タブで行う）
struct MCPControlSection: View {
    @Binding var settings: ClaudeSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "MCP制御設定", icon: "server.rack")

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.secondary)
                Text("ここでは settings.json 内の MCP 承認ポリシーを設定します。\n個々のサーバーの追加・削除は「MCP」タブで行ってください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.08))
            )

            Form {
                Section("プロジェクト MCP 自動承認") {
                    Toggle(isOn: Binding(
                        get: { settings.enableAllProjectMcpServers ?? false },
                        set: { settings.enableAllProjectMcpServers = $0 }
                    )) {
                        SettingRow(
                            label: "プロジェクトの .mcp.json を全て自動承認",
                            key: "enableAllProjectMcpServers",
                            description: "フォルダ信頼時に .mcp.json 内の全サーバーを確認なしで有効化"
                        )
                    }
                }

                if !(settings.enableAllProjectMcpServers ?? false) {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            SettingRow(
                                label: "承認するサーバー名",
                                key: "enabledMcpjsonServers",
                                description: "列挙したサーバーのみを自動承認"
                            )
                            TagEditor(
                                items: Binding(
                                    get: { settings.enabledMcpjsonServers ?? [] },
                                    set: { settings.enabledMcpjsonServers = $0.isEmpty ? nil : $0 }
                                ),
                                placeholder: "サーバー名を追加..."
                            )
                        }
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            SettingRow(
                                label: "拒否するサーバー名",
                                key: "disabledMcpjsonServers",
                                description: "列挙したサーバーは自動承認しない"
                            )
                            TagEditor(
                                items: Binding(
                                    get: { settings.disabledMcpjsonServers ?? [] },
                                    set: { settings.disabledMcpjsonServers = $0.isEmpty ? nil : $0 }
                                ),
                                placeholder: "サーバー名を追加..."
                            )
                        }
                    }
                }

                Section("ファイル候補補完 (fileSuggestion)") {
                    VStack(alignment: .leading, spacing: 6) {
                        SettingRow(
                            label: "@ ファイル補完コマンド",
                            key: "fileSuggestion",
                            description: "stdin で {\"query\":\"...\"} を受け取り、候補パスを改行区切りで返すコマンド"
                        )
                        TextField("コマンドを入力...", text: Binding(
                            get: { settings.fileSuggestion ?? "" },
                            set: { settings.fileSuggestion = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}
