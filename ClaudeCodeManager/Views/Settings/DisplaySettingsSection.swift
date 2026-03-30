import SwiftUI

struct DisplaySettingsSection: View {
    @Binding var settings: ClaudeSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "表示・UX設定", icon: "paintbrush")

            Form {
                Section("ターミナル表示") {
                    Toggle(isOn: Binding(
                        get: { settings.spinnerTipsEnabled ?? true },
                        set: { settings.spinnerTipsEnabled = $0 }
                    )) {
                        SettingRow(label: "スピナーTipsを表示", key: "spinnerTipsEnabled")
                    }

                    Toggle(isOn: Binding(
                        get: { settings.terminalProgressBarEnabled ?? true },
                        set: { settings.terminalProgressBarEnabled = $0 }
                    )) {
                        SettingRow(label: "プログレスバーを表示", key: "terminalProgressBarEnabled")
                    }

                    Toggle(isOn: Binding(
                        get: { settings.showTurnDuration ?? false },
                        set: { settings.showTurnDuration = $0 }
                    )) {
                        SettingRow(label: "ターン処理時間を表示", key: "showTurnDuration")
                    }

                    Toggle(isOn: Binding(
                        get: { settings.prefersReducedMotion ?? false },
                        set: { settings.prefersReducedMotion = $0 }
                    )) {
                        SettingRow(label: "アニメーションを抑制 (アクセシビリティ)", key: "prefersReducedMotion")
                    }
                }

                Section("ステータスライン") {
                    VStack(alignment: .leading, spacing: 6) {
                        SettingRow(label: "ステータスラインコマンド", key: "statusLine",
                                   description: "コマンド出力をステータスラインに表示。例: echo \"$(git branch --show-current)\"")
                        TextField("コマンドを入力...", text: Binding(
                            get: { settings.statusLine ?? "" },
                            set: { settings.statusLine = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    }
                }

                Section("スピナー カスタマイズ") {
                    VStack(alignment: .leading, spacing: 8) {
                        SettingRow(label: "カスタム動詞",
                                   key: "spinnerVerbs",
                                   description: "スピナーに表示するアクション動詞を追加。例: thinking, coding, writing")
                        TagEditor(
                            items: Binding(
                                get: { settings.spinnerVerbs ?? [] },
                                set: { settings.spinnerVerbs = $0.isEmpty ? nil : $0 }
                            ),
                            placeholder: "動詞を追加..."
                        )
                    }
                }

                Section("帰属表記 (Attribution)") {
                    Toggle(isOn: Binding(
                        get: { settings.includeCoAuthoredBy ?? true },
                        set: { settings.includeCoAuthoredBy = $0 }
                    )) {
                        SettingRow(label: "Co-Authored-By を自動追記",
                                   key: "includeCoAuthoredBy",
                                   description: "コミット・PRに Claude の帰属表記を追加")
                    }

                    Toggle(isOn: Binding(
                        get: { settings.attribution?.commits ?? true },
                        set: { v in
                            settings.ensureAttribution()
                            settings.attribution?.commits = v
                        }
                    )) {
                        SettingRow(label: "コミットに帰属表記", key: "attribution.commits")
                    }

                    Toggle(isOn: Binding(
                        get: { settings.attribution?.pr ?? true },
                        set: { v in
                            settings.ensureAttribution()
                            settings.attribution?.pr = v
                        }
                    )) {
                        SettingRow(label: "プルリクエストに帰属表記", key: "attribution.pr")
                    }
                }

                Section("Worktree / コンテキスト") {
                    VStack(alignment: .leading, spacing: 8) {
                        SettingRow(label: "Sparse checkout パス",
                                   key: "worktree.sparsePaths",
                                   description: "大規模モノレポで Claude Code がスキャンするディレクトリを絞り込み")
                        TagEditor(
                            items: Binding(
                                get: { settings.worktree?.sparsePaths ?? [] },
                                set: { v in
                                    if settings.worktree == nil { settings.worktree = ClaudeSettings.Worktree() }
                                    settings.worktree?.sparsePaths = v.isEmpty ? nil : v
                                }
                            ),
                            placeholder: "例: src/backend/"
                        )
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
}
