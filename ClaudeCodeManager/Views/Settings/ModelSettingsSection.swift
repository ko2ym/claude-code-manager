import SwiftUI

struct ModelSettingsSection: View {
    @Binding var settings: ClaudeSettings

    private let models = [
        "claude-opus-4-6",
        "claude-sonnet-4-6",
        "claude-haiku-4-5",
    ]
    private let effortLevels = ["low", "medium", "high"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "モデル・動作設定", icon: "cpu")

            Form {
                Section("モデル選択") {
                    Picker("使用モデル", selection: Binding(
                        get: { settings.model ?? "claude-sonnet-4-6" },
                        set: { settings.model = $0 }
                    )) {
                        ForEach(models, id: \.self) { model in
                            HStack {
                                modelIcon(for: model)
                                Text(model)
                            }
                            .tag(model)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("思考深度 (effortLevel)")
                        Picker("", selection: Binding(
                            get: { settings.effortLevel ?? "medium" },
                            set: { settings.effortLevel = $0 }
                        )) {
                            ForEach(effortLevels, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        Text("high: より深い思考、low: 高速な応答")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Toggle(isOn: Binding(
                        get: { settings.alwaysThinkingEnabled ?? false },
                        set: { settings.alwaysThinkingEnabled = $0 }
                    )) {
                        SettingRow(label: "拡張思考を常時有効", key: "alwaysThinkingEnabled")
                    }
                }

                Section("言語・出力スタイル") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Text("デフォルト応答言語")
                            Text("language")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        Picker("", selection: Binding(
                            get: { settings.language ?? "japanese" },
                            set: { settings.language = $0 }
                        )) {
                            Text("日本語 (japanese)").tag("japanese")
                            Text("英語 (english)").tag("english")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(maxWidth: 300)
                    }

                    HStack {
                        SettingRow(label: "出力スタイル", key: "outputStyle")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { settings.outputStyle ?? "auto" },
                            set: { settings.outputStyle = $0 }
                        )) {
                            Text("auto — 自動判断").tag("auto")
                            Text("concise — 簡潔").tag("concise")
                            Text("verbose — 詳細").tag("verbose")
                            Text("brief — 要点のみ").tag("brief")
                        }
                        .frame(width: 180)
                    }
                }

                Section("計画・プラン") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("プランファイル保存先")
                            Text("plansDirectory")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        Picker("", selection: Binding(
                            get: { settings.plansDirectory ?? "plans" },
                            set: { settings.plansDirectory = $0 }
                        )) {
                            Text("plans (推奨)").tag("plans")
                            Text(".claude/plans").tag(".claude/plans")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(maxWidth: 300)
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text("推奨: プロジェクトルートの plans/ に保存することで管理しやすくなります")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("アップデート・セッション") {
                    Toggle(isOn: Binding(
                        get: { settings.autoUpdates ?? true },
                        set: { settings.autoUpdates = $0 }
                    )) {
                        SettingRow(label: "自動アップデートを有効化", key: "autoUpdates")
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("履歴保持日数")
                            Text("cleanupPeriodDays")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        TextField("30", value: Binding(
                            get: { settings.cleanupPeriodDays ?? 30 },
                            set: { settings.cleanupPeriodDays = $0 }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 64)
                        Text("日")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
    }

    @ViewBuilder
    private func modelIcon(for model: String) -> some View {
        if model.contains("opus") {
            Image(systemName: "star.fill").foregroundStyle(.purple)
        } else if model.contains("sonnet") {
            Image(systemName: "bolt.fill").foregroundStyle(.blue)
        } else {
            Image(systemName: "hare.fill").foregroundStyle(.green)
        }
    }
}

// MARK: - Shared header

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .font(.title3)
            Text(title)
                .font(.title3.weight(.semibold))
        }
    }
}

// MARK: - Setting row label (label + JSON key + optional description)

struct SettingRow: View {
    let label: String
    let key: String
    var description: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
            Text(key)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
            if let desc = description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

