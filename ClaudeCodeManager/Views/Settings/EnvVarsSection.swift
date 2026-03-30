import SwiftUI

struct EnvVarsSection: View {
    @Binding var settings: ClaudeSettings

    private let knownVars: [(key: String, description: String)] = [
        ("ANTHROPIC_API_KEY", "Anthropic API キー"),
        ("CLAUDE_AUTOCOMPACT_PCT_OVERRIDE", "自動コンパクト閾値 (0-100%)"),
        ("MAX_THINKING_TOKENS", "最大思考トークン数"),
        ("CLAUDE_CODE_USE_BEDROCK", "AWS Bedrock経由で利用 (1=有効)"),
        ("CLAUDE_CODE_USE_VERTEX", "Google Vertex AI経由で利用 (1=有効)"),
        ("CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC", "テレメトリ無効化 (1=有効)"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "環境変数 (env)", icon: "terminal")

            Form {
                Section {
                    Text("settings.json の env オブジェクトに設定した変数は Claude Code 実行時に環境変数として渡されます。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("env 設定") {
                    KeyValueEditor(
                        pairs: Binding(
                            get: { settings.env ?? [:] },
                            set: { settings.env = $0.isEmpty ? nil : $0 }
                        ),
                        keyPlaceholder: "VARIABLE_NAME",
                        valuePlaceholder: "value"
                    )
                }

                Section("よく使う変数") {
                    ForEach(knownVars, id: \.key) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.key)
                                    .font(.system(size: 12, design: .monospaced))
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if settings.env?[item.key] != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button("追加") {
                                    if settings.env == nil { settings.env = [:] }
                                    settings.env?[item.key] = ""
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}
