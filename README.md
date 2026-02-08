# til-capture

![version](https://img.shields.io/badge/version-0.3.0-blue)
![license](https://img.shields.io/badge/license-MIT-green)
![tests](https://img.shields.io/badge/tests-41%20passing-brightgreen)

Claude Code セッション中の「学び」を TIL (Today I Learned) メモとしてキャプチャするプラグイン。

## 概要

til-capture は、Claude Code での調査・開発中に得た知識を自動的に検知し、構造化された Markdown ファイルとして保存するプラグインです。

WebSearch や WebFetch を使った調査の後、セッション終了時に TIL 記録を自動で提案します。手動での記録にも対応しており、`/til-capture:til` コマンドでいつでも学びを保存できます。

保存された TIL はフロントマター付きの Markdown ファイルで、ブログやナレッジベースにそのまま活用できます。

## 機能

- **自動検知**: WebSearch/WebFetch を使った調査後、セッション終了時に TIL 記録を自動提案
- **手動記録**: `/til-capture:til` コマンドでいつでも TIL を記録
- **ストック表示**: セッション開始時に既存 TIL 数をリマインド
- **柔軟な保存先**: CWD 内ディレクトリ → config.json → `~/til/` の優先順で自動解決
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

### 自動キャプチャ

WebSearch や WebFetch を使って調査を行った後、セッション終了時に自動で TIL 記録を提案します。不要な場合はスキップできます。

保存先の信頼度（CWD 内の既存ディレクトリか、未確認のパスか）に応じて動作が変わります:

- **高信頼**（CWD 内ディレクトリ or config の既存パス）: 保存先を明示して記録を実行
- **低信頼**（未存在のパス or フォールバック）: ユーザーに保存先を確認してから記録

### セッション開始時の表示

毎セッション開始時に、TIL の自動キャプチャ状態が表示されます。

```
TIL auto-capture: ON (WebSearch/WebFetch) | Stock: 42 entries (/path/to/til)
```

TIL ディレクトリが未検出の場合:

```
TIL auto-capture: ON (WebSearch/WebFetch) | Save to: ~/til/ (will ask, configurable via ~/.config/til-capture/config.json)
```

## 設定

### config.json

デフォルトの保存先を設定するには `~/.config/til-capture/config.json` を作成します:

```bash
mkdir -p ~/.config/til-capture
cat > ~/.config/til-capture/config.json << 'EOF'
{
  "defaultTilDir": "/home/user/my-knowledge-base/til"
}
EOF
```

`defaultTilDir` には TIL ファイルを保存したいディレクトリの絶対パスを指定してください。

### 保存先の解決順序

以下の順でディレクトリを検索し、最初に見つかった場所に保存します:

| 優先度 | ソース | 信頼度 |
|--------|--------|--------|
| 1 | CWD 内のプロジェクトディレクトリ (`src/content/til/` → `content/til/` → `til/`) | 高（確認なし） |
| 2 | `config.json` の `defaultTilDir`（ディレクトリが存在する場合） | 高（確認なし） |
| 2 | `config.json` の `defaultTilDir`（ディレクトリが存在しない場合） | 低（確認あり） |
| 3 | `~/til/`（フォールバック） | 低（確認あり） |

## 生成されるファイル形式

```markdown
---
title: "学びのタイトル"
date: 2026-01-01
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

- TIL テンプレートのカスタマイズ
- タグの自動補完（既存 TIL から抽出）
- 既存 TIL との重複チェック

## ライセンス

[MIT](LICENSE)
