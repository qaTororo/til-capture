# til-capture

![version](https://img.shields.io/badge/version-1.1.0-blue)
![license](https://img.shields.io/badge/license-MIT-green)
![tests](https://img.shields.io/badge/tests-47%20passing-brightgreen)

Claude Code セッション中の「学び」を TIL (Today I Learned) メモとしてキャプチャするプラグイン。

## 概要

til-capture は、Claude Code での調査・開発中に得た知識を自動的に検知し、構造化された Markdown ファイルとして保存するプラグインです。

WebSearch や WebFetch を使った調査の後、セッション終了時に TIL 記録を自動で提案します。手動での記録にも対応しており、`/til-capture:til` コマンドでいつでも学びを保存できます。

保存された TIL はフロントマター付きの Markdown ファイルで、個人の知識整理や振り返りに活用できます。

## 機能

- **自動検知**: WebSearch/WebFetch を使った調査後、セッション終了時に TIL 記録を自動提案
- **手動記録**: `/til-capture:til` コマンドでいつでも TIL を記録
- **TIL 検索・一覧**: `/til-capture:til-list` で蓄積した TIL の検索・一覧表示・タグ集計
- **タグ自動補完**: 既存 TIL のタグを抽出して新規 TIL のタグ表記を統一
- **ストック表示**: セッション開始時に既存 TIL 数をリマインド
- **意図的な保存先設定**: CWD 内ディレクトリ → config.json の 2 段階で保存先を解決（未設定時はアラート表示）
- **信頼度ベースの確認**: 保存先の信頼度に応じてユーザー確認を制御
- **セキュリティ**: 入力バリデーション、パストラバーサル対策、アトミックな状態管理

## 必要環境

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- `jq` コマンド

## インストール

```bash
claude plugin add ~/src/github.com/qaTororo/til-capture
```

## 使い方

### 手動で TIL を記録

```
/til-capture:til
```

カテゴリやトピックを指定:

```
/til-capture:til docker networking
```

### TIL の検索・一覧表示

蓄積した TIL を検索・ブラウズ:

```
/til-capture:til-list                  # 直近 10 件の一覧
/til-capture:til-list search docker    # キーワードで全文検索
/til-capture:til-list tags             # タグ別の件数を表示
```

### 自動キャプチャ

WebSearch や WebFetch を使って調査を行った後、セッション終了時に自動で TIL 記録を提案します。不要な場合はスキップできます。

保存先の信頼度（CWD 内の既存ディレクトリか、未確認のパスか）に応じて動作が変わります:

- **高信頼**（CWD 内ディレクトリ or config の既存パス）: 保存先を明示して記録を実行
- **低信頼**（未存在のパス）: ユーザーに保存先を確認してから記録
- **未設定**: アラートを表示し、設定方法を案内（保存は行わない）

### セッション開始時の表示

毎セッション開始時に、TIL の自動キャプチャ状態が表示されます。

```
TIL auto-capture: ON (WebSearch/WebFetch) | Author: your-username | Stock: 42 entries (/path/to/til)
```

保存先が未設定の場合:

```
TIL auto-capture: ⚠ No save destination configured. Set defaultTilDir in ~/.config/til-capture/config.json or create a til/ directory in your project.
```

## 設定

### config.json

デフォルトの保存先を設定するには `~/.config/til-capture/config.json` を作成します:

```bash
mkdir -p ~/.config/til-capture
cat > ~/.config/til-capture/config.json << 'EOF'
{
  "defaultTilDir": "/home/user/my-knowledge-base/til",
  "author": "your-username"
}
EOF
```

`defaultTilDir` には TIL ファイルを保存したいディレクトリの絶対パスを指定してください。

`author` には TIL の著者名を指定します（省略可）。チームで共有リポジトリを使う場合に「誰が書いたか」を記録するために設定してください。

### 保存先の解決順序

以下の順でディレクトリを検索し、最初に見つかった場所に保存します:

| 優先度 | ソース | 信頼度 |
|--------|--------|--------|
| 1 | CWD 内のプロジェクトディレクトリ (`src/content/til/` → `content/til/` → `til/`) | 高（確認なし） |
| 2 | `config.json` の `defaultTilDir`（ディレクトリが存在する場合） | 高（確認なし） |
| 2 | `config.json` の `defaultTilDir`（ディレクトリが存在しない場合） | 低（確認あり） |
| — | 上記すべて該当なし | アラート表示（保存しない） |

## 生成されるファイル形式

```markdown
---
title: "学びのタイトル"
date: 2026-01-01
author: "your-username"
tags: [tag1, tag2]
draft: true
---

## 概要
...

## 詳細
...
```

## Contributing

### 開発環境のセットアップ

```bash
git clone https://github.com/qaTororo/til-capture.git
cd til-capture
npm install
```

### 開発中のプラグインロード

```bash
claude --plugin-dir ~/src/github.com/qaTororo/til-capture
```

### テスト実行

```bash
npm test
```

テストフレームワークに [bats-core](https://github.com/bats-core/bats-core) を使用しています。テストは完全に隔離された環境で実行されます（HOME、TMPDIR 等を差し替え）。

技術的な詳細は [docs/architecture.md](docs/architecture.md)、セキュリティ対策は [docs/security.md](docs/security.md) を参照してください。

## ロードマップ

### v1.0

- タグの自動補完 — 既存 TIL から抽出し、タグの一貫性を維持（F-102）
- TIL 検索・一覧表示 — `/til-list` でセッション内から過去の TIL を検索・ブラウズ（F-107）
- 保存先の意図的な設定 — `~/til/` フォールバック削除、config.json の設定を推奨（ADR-004）

### v1.1（現行）

- チーム利用対応 — `author` フィールドの追加で「誰が書いたか」を記録（F-111）

### v1.2+

- UX 改善（コンテキスト汚染対策）
- TIL テンプレートのカスタマイズ（F-101）
- 新規 Hook イベント活用（PostToolUse 等）

## ライセンス

[MIT](LICENSE)
