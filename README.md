# til-capture

Claude Code セッション中の「学び」を TIL (Today I Learned) メモとしてキャプチャするプラグイン。

## 機能

- **自動検知**: WebSearch/WebFetch を使った調査後、Stop 時に自動で TIL 記録を提案
- **手動記録**: `/til-capture:til` コマンドでいつでも TIL を記録
- **ストック表示**: セッション開始時に既存 TIL 数をリマインド
- **保存先設定**: `~/.config/til-capture/config.json` でデフォルト保存先を設定可能

## 必要環境

- `jq` コマンド

## インストール

```bash
# プラグインとして追加
claude plugin add ~/src/github.com/qaTororo/til-capture
```

開発中は `--plugin-dir` で直接ロード:

```bash
claude --plugin-dir ~/src/github.com/qaTororo/til-capture
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

### 自動 TIL キャプチャ

WebSearch や WebFetch を使って調査を行った後、セッション終了時に自動で TIL 記録を提案します。不要な場合はスキップできます。

### 保存先の設定

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

## TIL 保存先

以下の順でディレクトリを検索し、最初に見つかった場所に保存します:

1. CWD 内のプロジェクトディレクトリ (`src/content/til/` → `content/til/` → `til/`)
2. `~/.config/til-capture/config.json` の `defaultTilDir`
3. `~/til/` (フォールバック)

CWD 内のディレクトリが最優先されます。CWD 内に該当ディレクトリがない場合のみ、config または `~/til/` を使用します（確認付き）。

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

## ロードマップ

### v0.2 (実装済み)

#### 保存先設定機能

`~/.config/til-capture/config.json` でデフォルト保存先を設定可能。

保存先の解決順序:

1. CWD 内のプロジェクトディレクトリ (`src/content/til/` → `content/til/` → `til/`)
2. `config.json` の `defaultTilDir`
3. `~/til/` (フォールバック)

#### 自動キャプチャの可視化

SessionStart hook で自動キャプチャの状態を毎セッション表示。

- TIL ディレクトリが無くても常にステータスを表示
- 表示例: `TIL auto-capture: ON (WebSearch/WebFetch) | Stock: 42 entries`
- 未検出時: `TIL auto-capture: ON | Save to: <defaultTilDir or ~/til/>`

#### Stop hook の改善

- 保存先を hook 側で解決し、REASON メッセージに明示
- ユーザーへの質問が不要に

### v0.3+ (検討中)

- TIL テンプレートのカスタマイズ
- タグの自動補完（既存 TIL から抽出）
- 既存 TIL との重複チェック

## ライセンス

MIT
