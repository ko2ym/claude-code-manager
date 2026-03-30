import SwiftUI

struct APIAuthSection: View {
    @Binding var settings: ClaudeSettings

    private let loginMethods = ["claude.ai", "console"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "API・認証設定", icon: "key.fill")

            Form {
                // MARK: - API Key Helper
                Section("API キーヘルパー") {
                    VStack(alignment: .leading, spacing: 6) {
                        SettingRow(
                            label: "apiKeyHelper スクリプト",
                            key: "apiKeyHelper",
                            description: "/bin/sh で実行され、認証値を生成してリクエストヘッダーに渡すスクリプト"
                        )
                        TextField("/path/to/auth-script.sh", text: Binding(
                            get: { settings.apiKeyHelper ?? "" },
                            set: { settings.apiKeyHelper = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        SettingRow(
                            label: "OpenTelemetry ヘッダーヘルパー",
                            key: "otelHeadersHelper",
                            description: "起動時および定期的に実行され、OTel 動的ヘッダーを生成"
                        )
                        TextField("/path/to/otel-script.sh", text: Binding(
                            get: { settings.otelHeadersHelper ?? "" },
                            set: { settings.otelHeadersHelper = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    }
                }

                // MARK: - Login restrictions
                Section("ログイン制限 (組織向け)") {
                    VStack(alignment: .leading, spacing: 8) {
                        SettingRow(
                            label: "ログイン方法を限定",
                            key: "forceLoginMethod",
                            description: "claude.ai アカウント限定 または Console 限定"
                        )
                        Picker("", selection: Binding(
                            get: { settings.forceLoginMethod ?? "" },
                            set: { settings.forceLoginMethod = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("(制限なし)").tag("")
                            ForEach(loginMethods, id: \.self) { method in
                                Text(method).tag(method)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        SettingRow(
                            label: "組織 UUID を固定 (forceLoginOrgUUID)",
                            key: "forceLoginOrgUUID",
                            description: "ログイン時の組織選択をこの UUID に固定"
                        )
                        TextField("org UUID を入力...", text: Binding(
                            get: { settings.forceLoginOrgUUID ?? "" },
                            set: { settings.forceLoginOrgUUID = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    }
                }

                // MARK: - AWS
                Section("AWS 認証 (上級)") {
                    VStack(alignment: .leading, spacing: 6) {
                        SettingRow(
                            label: "AWS 認証リフレッシュスクリプト",
                            key: "awsAuthRefresh",
                            description: ".aws ディレクトリを更新するスクリプト"
                        )
                        TextField("/path/to/aws-refresh.sh", text: Binding(
                            get: { settings.awsAuthRefresh ?? "" },
                            set: { settings.awsAuthRefresh = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        SettingRow(
                            label: "AWS 認証情報エクスポートスクリプト",
                            key: "awsCredentialExport",
                            description: "AWS 認証情報を JSON で出力するスクリプト"
                        )
                        TextField("/path/to/aws-export.sh", text: Binding(
                            get: { settings.awsCredentialExport ?? "" },
                            set: { settings.awsCredentialExport = $0.isEmpty ? nil : $0 }
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
