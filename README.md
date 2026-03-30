# Claude Code Manager

Claude Code の設定を管理する macOS ネイティブアプリです。

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.10-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-native-green)

## 概要

Claude Code Manager（CCM）は、Claude Code の設定ファイル・MCPサーバー・プロジェクト管理を GUI で行うための macOS アプリです。コマンドラインや JSON ファイルを直接編集することなく、すべての設定を視覚的に管理できます。

## 機能

### 設定管理
- モデル設定（言語・出力スタイル・プランディレクトリなど）
- パーミッション管理（許可・拒否リスト）
- 環境変数の設定
- API 認証設定
- Agent チーム設定

### MCP サーバー管理
- MCP サーバーの追加・編集・削除
- 豊富なプリセット（GitHub、Supabase、Vercel、Slack、Figma など 15種類以上）
- プロジェクトのファイル（`.vercel/`、`supabase/` など）を検出して MCP を自動提案
- `.env.local` から API キーを自動補完

### ファイル管理
- `CLAUDE.md`、`.claude/` 配下のファイルをツリー表示
- Markdown プレビュー・編集
- ファイル作成・削除

### プロジェクト管理
- 複数プロジェクトをサイドバーで切り替え
- グローバル設定（`~/.claude/`）とプロジェクト設定を統合管理

## 動作環境

- macOS 14.0 (Sonoma) 以上
- Xcode 16 以上（ビルドに必要）

## ビルド方法

### 必要なツール

```bash
# XcodeGen のインストール（Homebrew）
brew install xcodegen
```

### ビルド手順

```bash
git clone https://github.com/ko2ym/claude-code-manager.git
cd claude-code-manager

# Xcode プロジェクトを生成
xcodegen generate

# Xcode で開く
open ClaudeCodeManager.xcodeproj
```

Xcode で `ClaudeCodeManager` スキームを選択して Run（⌘R）します。

## ディレクトリ構成

```
claude-code-manager/
├── ClaudeCodeManager/
│   ├── App/             # アプリエントリポイント・AppState
│   ├── Components/      # 共通UIコンポーネント（TagEditor、FlowLayout など）
│   ├── Models/          # データモデル（ClaudeSettings、MCPConfig、FileNode）
│   ├── Services/        # ファイル読み書き・設定保存
│   ├── Views/
│   │   ├── Settings/    # 設定タブ各セクション
│   │   ├── MCP/         # MCP 管理画面
│   │   ├── MDFiles/     # ファイル管理画面
│   │   └── Sidebar/     # サイドバー
│   └── Resources/       # Info.plist、Entitlements、アイコン
├── scripts/
│   └── generate_icon.swift  # アプリアイコン生成スクリプト
└── project.yml          # XcodeGen 設定ファイル
```

## ライセンス

MIT License
