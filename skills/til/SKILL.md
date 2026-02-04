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

### 2. 保存先の検出

Glob を使って以下の順で TIL ディレクトリを検索:
1. `src/content/til/` （Astro/Starlight）
2. `content/til/` （汎用CMS）
3. `til/` （シンプル構成）

**見つからない場合**: ユーザーに保存先を質問する。

### 3. ファイル生成

- ファイル名: `YYYY-MM-DD-<slug>.md`（slug はタイトルから英語 kebab-case）
- テンプレート:

```markdown
---
title: "学びのタイトル"
date: YYYY-MM-DD
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

### 4. 結果報告

保存したファイルパスと内容のサマリーを報告する。

## 引数

$ARGUMENTS が指定された場合、カテゴリやトピックのヒントとして使用する。
