import SwiftUI

struct AgentTeamsSection: View {
    @Binding var settings: ClaudeSettings

    private let teammateModes = ["auto", "in-process", "tmux"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Agent Teams", icon: "person.3.fill")

            // Info banner
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Agent Teams は実験的機能です")
                        .font(.subheadline.weight(.semibold))
                    Text("複数の Claude インスタンスがチームとして並列処理を実行します。通常より 5〜7 倍のトークンを消費します。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.06))
                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
            )

            Form {
                Section("有効化") {
                    Toggle(isOn: Binding(
                        get: { settings.agentTeamsEnabled },
                        set: { settings.agentTeamsEnabled = $0 }
                    )) {
                        SettingRow(
                            label: "Agent Teams を有効化",
                            key: "env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS",
                            description: "ON にすると CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 を env に設定します"
                        )
                    }
                }

                if settings.agentTeamsEnabled {
                    Section("表示モード") {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("", selection: Binding(
                                get: { settings.teammateMode ?? "auto" },
                                set: { settings.teammateMode = $0 }
                            )) {
                                ForEach(teammateModes, id: \.self) { mode in
                                    Text(mode).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()

                            Group {
                                switch settings.teammateMode ?? "auto" {
                                case "in-process":
                                    Text("in-process: tmux なしで実行可能。ターミナル内に全メンバーの並列動作が表示される")
                                case "tmux":
                                    Text("tmux: tmux セッション内の独立したペインで各エージェントを実行")
                                default:
                                    Text("auto: 環境に応じて自動選択")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        SettingRow(label: "", key: "teammateMode")
                    }

                    Section("Agent Teams の使い方") {
                        VStack(alignment: .leading, spacing: 6) {
                            UsageTip(icon: "keyboard", text: "Shift+矢印 でメンバー切り替え")
                            UsageTip(icon: "list.bullet", text: "Ctrl+T で共有タスクリストを表示")
                            UsageTip(icon: "message", text: "Mailbox でメンバー間の直接メッセージング")
                            UsageTip(icon: "exclamationmark.triangle", text: "/resume（セッション再開）は非対応")
                            UsageTip(icon: "clock", text: "シャットダウンに 15〜20 秒かかる場合あり")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}

struct UsageTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
