# til-capture

Claude Code セッション中の「学び」を TIL (Today I Learned) メモとしてキャプチャするプラグイン。

## 機能

- **自動検知**: WebSearch/WebFetch を使った調査後、Stop 時に自動で TIL 記録を提案
- **手動記録**: `/til-capture:til` コマンドでいつでも TIL を記録
- **ストック表示**: セッション開始時に既存 TIL 数をリマインド

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

## TIL 保存先

以下の順でディレクトリを検索し、最初に見つかった場所に保存します:

1. `src/content/til/` (Astro/Starlight)
2. `content/til/` (汎用 CMS)
3. `til/` (シンプル構成)

見つからない場合はユーザーに保存先を確認します。

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

### v0.2 (予定)

- TIL テンプレートのカスタマイズ
- タグの自動補完
- 既存 TIL との重複チェック

## ライセンス

MIT
