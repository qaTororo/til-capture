---
name: til
description: >
  This skill should be used when the user asks to "record a TIL",
  "capture what I learned", "save today's learning", "TILを記録",
  "学びを保存", or when a Stop hook suggests TIL capture after
  research activity (WebSearch/WebFetch usage detected).
allowed-tools: Read, Write, Glob, Grep, Bash(date:*), Bash(mkdir:*)
---

# TIL Capture

現在の日付: !`date +%Y-%m-%d`

## 手順

会話コンテキストから学びを抽出し、TILメモとして保存する。

### 1. 学びの特定

現在の会話で得られた新しい知識・発見を特定する:
- 技術的な学び、ツールの使い方、デバッグのコツ
- 調査で分かった事実、仕様、ベストプラクティス
- 失敗から得た教訓

### 2. 保存先の解決

以下の順序で保存先を決定する。**Glob での無制限検索は行わないこと。**

#### Step 1: CWD 内のプロジェクトディレクトリ
以下の3つのパスを CWD からの相対パスで**順に**存在確認する:

1. `{CWD}/src/content/til/`
2. `{CWD}/content/til/`
3. `{CWD}/til/`

最初に見つかったディレクトリを使用する。

#### Step 2: config.json の読み取り
`~/.config/til-capture/config.json` を Read で読み取る（Step 1 の結果に関わらず常に読み取る）。

- `author` フィールドが設定されている場合、その値を frontmatter の `author` に使用する。
- Step 1 で保存先が見つかっている場合、`defaultTilDir` は使用しない。
- Step 1 で見つからない場合、`defaultTilDir` フィールドが設定されていれば、そのパスを保存先として使用する。
  - ディレクトリが**存在する**場合: そのまま保存（高信頼）
  - ディレクトリが**存在しない**場合: ユーザーに確認してから `mkdir -p` で作成（低信頼）

ファイルが存在しないまたは読み取りエラーの場合は無視して次へ。

#### 保存先が見つからない場合
Step 1, 2 で保存先が決まらない場合、TIL の保存は行わない。
ユーザーに以下を案内する:
- `~/.config/til-capture/config.json` に `{"defaultTilDir": "/path/to/til", "author": "your-name"}` を設定する
- またはプロジェクト内に `til/` ディレクトリを作成する

設定方法が分からない場合は、ユーザーに保存先を聞いて config.json を生成する手助けをする。

### 2.5. 既存タグの収集（タグ自動補完）

保存先ディレクトリが決まったら、既存 TIL のタグ情報を収集して一貫性を向上させる。

1. **ファイル列挙**: 保存先ディレクトリ内の `.md` ファイルを Glob で列挙する
   - パターン: `{保存先ディレクトリ}/*.md`
   - 上限: 100 ファイル（直近のファイルから優先）

2. **タグ抽出**: 各ファイルの frontmatter `tags:` 行を Grep で抽出する
   - パターン: `^tags:`

3. **タグ集計**: 小文字化して頻度を集計する。表示は最も頻度の高い表記を採用

4. **タグ候補の活用**: 新規 TIL のタグ生成時、既存タグに一致するものがあれば既存の表記を優先使用する

**制約**: 走査上限 100 ファイル。エラー時はスキップして通常のタグ生成に進む。

### 3. ファイル生成

- ファイル名: `YYYY-MM-DD-<slug>.md`（slug はタイトルから英語 kebab-case）
- テンプレート:

```markdown
---
title: "学びのタイトル"
date: YYYY-MM-DD
author: "authorの値"
tags: [tag1, tag2]
draft: true
---

## 概要
（1-2文の要約）

## 詳細
（学びの詳細な説明）

## コード例
（該当する場合のみ）

## 参考
（関連リンクや背景情報）
```

- `author`: config.json に `author` が設定されている場合のみ含める。未設定の場合はこの行自体を省略する。

### 4. 結果報告

保存したファイルパスと内容のサマリーを報告する。

## 引数

$ARGUMENTS が指定された場合、カテゴリやトピックのヒントとして使用する。
