# 機能インベントリ

> **ステータス**: `[Draft]`
> **最終更新**: 2026-02-08

## 概要

til-capture の全機能を一覧化し、v1.0 に向けた優先度を管理する。

## 現行機能（v0.3.0）

| ID | 機能名 | 種別 | 実装 | ステータス | 仕様 |
|----|--------|------|------|-----------|------|
| F-001 | 自動キャプチャ提案 | Stop hook | `hooks/stop-hook.sh` | `[Implemented]` | [03-auto-capture.md](./03-auto-capture.md) |
| F-002 | ストック表示 | SessionStart hook | `hooks/session-start-hook.sh` | `[Implemented]` | [03-auto-capture.md](./03-auto-capture.md) |
| F-003 | 手動 TIL 記録 | Skill | `skills/til/SKILL.md` | `[Implemented]` | [04-manual-capture.md](./04-manual-capture.md) |
| F-004 | 保存先解決（3段階） | ロジック | stop-hook.sh / SKILL.md | `[Implemented]` | [05-config.md](./05-config.md) |
| F-005 | 信頼度ベースの確認 | UX | stop-hook.sh / SKILL.md | `[Implemented]` | [05-config.md](./05-config.md) |
| F-006 | セキュリティ対策 | 基盤 | 全 hook | `[Implemented]` | [security.md](../security.md) |

### 現行機能の詳細

#### F-001: 自動キャプチャ提案

セッション終了時に WebSearch/WebFetch の使用を検知し、TIL 記録を提案する。Stop hook で実装。

- **トリガー**: セッション終了（Stop イベント）
- **検知対象**: トランスクリプト内の `"WebSearch"` / `"WebFetch"` 文字列
- **出力**: `decision: "block"` の JSON レスポンス + TIL 記録指示のメッセージ
- **テスト**: 24 テストケース（`test/stop-hook.bats`）

#### F-002: ストック表示

セッション開始時に TIL の蓄積状況を表示する。SessionStart hook で実装。

- **トリガー**: セッション開始（SessionStart イベント）
- **表示内容**: TIL ディレクトリのパスと .md ファイル数
- **出力**: `hookSpecificOutput` フィールドにステータス文字列
- **テスト**: 12 テストケース（`test/session-start-hook.bats`）

#### F-003: 手動 TIL 記録

`/til` スキルによる任意タイミングでの TIL 記録。

- **トリガー**: ユーザーが `/til` コマンドを実行、または Stop hook からの提案を承認
- **処理**: 学びの特定 → 保存先解決 → Markdown ファイル生成 → 結果報告
- **許可ツール**: Read, Write, Glob, Grep, Bash(date), Bash(mkdir)

#### F-004: 保存先解決（3段階）

CWD → config.json → フォールバック の優先順位で保存先を決定する。

- **優先順位**: `src/content/til/` > `content/til/` > `til/`（CWD内） → `config.json` → `~/til/`
- **設定ファイル**: `~/.config/til-capture/config.json`

#### F-005: 信頼度ベースの確認

保存先の信頼度に応じて、ユーザー確認の要否を切り替える。

- **高信頼**: CWD 内に存在するディレクトリ、config.json 設定 + 存在するディレクトリ
- **低信頼**: config.json 設定 + 未存在、フォールバック `~/til/`

#### F-006: セキュリティ対策

入力バリデーション、パストラバーサル対策、無限ループ防止、TOCTOU 防止。

- 詳細は [security.md](../security.md) を参照

## v1.0 候補機能

| ID | 機能名 | 種別 | リリース | 複雑度 | 依存 | ステータス | 仕様 |
|----|--------|------|---------|--------|------|-----------|------|
| F-102 | タグ自動補完 | UX 改善 | **v1.0** | 中 | F-003 | `[Accepted]` | [06-future-features.md](./06-future-features.md#f-102-タグ自動補完) |
| F-107 | TIL 検索・一覧表示 | Skill 追加 | **v1.0** | 低 | F-004 | `[Accepted]` | [06-future-features.md](./06-future-features.md#f-107-til-検索一覧表示) |
| F-101 | テンプレートカスタマイズ | 設定拡張 | v1.1+ | 中 | F-004 | `[Draft]` | [06-future-features.md](./06-future-features.md#f-101-テンプレートカスタマイズ) |
| F-103 | 重複チェック | 品質向上 | v1.1+ | 高 | F-001, F-003 | `[Draft]` | [06-future-features.md](./06-future-features.md#f-103-重複チェック) |
| F-104 | PostToolUse(Write) 連携 | Hook 拡張 | v1.1+ | 低 | F-001 | `[Draft]` | [06-future-features.md](./06-future-features.md#f-104-posttoolusewrit-連携) |
| F-105 | UserPromptSubmit 連携 | Hook 拡張 | v2+ | 低 | — | `[Draft]` | [06-future-features.md](./06-future-features.md#f-105-userpromptsubmit-連携) |
| F-106 | PostToolUse(WebSearch) 連携 | Hook 拡張 | v1.1+ | 中 | F-001 | `[Draft]` | [06-future-features.md](./06-future-features.md#f-106-posttooluse-websearch-連携) |
| F-108 | Draft → Publish ワークフロー | UX 改善 | v2+ | 中 | F-003 | `[Draft]` | [06-future-features.md](./06-future-features.md#f-108-draft--publish-ワークフロー) |
| F-109 | エクスポート機能 | Skill 追加 | v2+ | 中 | F-004 | `[Draft]` | [06-future-features.md](./06-future-features.md#f-109-エクスポート機能) |
| F-110 | 統計・サマリー表示の強化 | UX 改善 | v1.1+ | 低 | F-002 | `[Draft]` | [06-future-features.md](./06-future-features.md#f-110-統計サマリー表示の強化) |

> **決定根拠**: [ADR-002](../adr/ADR-002-v1-feature-priority.md)（v1.0 機能の優先順位）、[ADR-003](../adr/ADR-003-new-hook-event-strategy.md)（新規 Hook 慎重待機）

## 優先度マトリクス

### 評価軸

| 軸 | 説明 | スケール |
|----|------|---------|
| **ユーザー価値** | ユーザーの日常利用に与えるインパクト | 高 / 中 / 低 |
| **実装複雑度** | 実装に必要な工数・技術的難易度 | 高 / 中 / 低 |
| **依存関係** | 他機能への依存・前提条件 | あり / なし |

### マトリクス（ADR-002 で更新）

> **価値の定義**: 「学びなおし・知識整理」への貢献度で評価（SSG 公開向け機能は降格）

```
参照効率への貢献: 高
  ┌──────────────────────────────────────────┐
  │  F-107 検索・一覧    │  F-102 タグ補完      │
  │  (複雑度: 低)        │  (複雑度: 中)        │
  │  ★ v1.0 確定         │  ★ v1.0 確定         │
  ├──────────────────────┼─────────────────────┤
参照効率への貢献: 中
  │  F-110 統計強化      │  F-103 重複チェック  │
  │  F-104 Write連携     │  F-106 WebSearch連携 │
  │  (複雑度: 低)        │  (複雑度: 中〜高)    │
  │  ◎ v1.1+             │  ◎ v1.1+             │
  ├──────────────────────┼─────────────────────┤
参照効率への貢献: 低（公開前提）
  │  F-105 Prompt連携    │  F-101 テンプレート  │
  │  (複雑度: 低)        │  F-108 Draft/Publish │
  │  △ v2+               │  F-109 エクスポート  │
  │                      │  (複雑度: 中)        │
  │                      │  △ v1.1+ / v2+       │
  └──────────────────────┴─────────────────────┘
    実装複雑度: 低          実装複雑度: 中〜高
```

## 機能間の依存関係

```mermaid
graph TD
    F004[F-004: 保存先解決] --> F001[F-001: 自動キャプチャ]
    F004 --> F003[F-003: 手動記録]
    F005[F-005: 信頼度判定] --> F001
    F005 --> F003
    F006[F-006: セキュリティ] --> F001
    F006 --> F002[F-002: ストック表示]

    F004 --> F101[F-101: テンプレート]
    F003 --> F102[F-102: タグ補完]
    F001 --> F103[F-103: 重複チェック]
    F003 --> F103
    F001 --> F104[F-104: Write連携]
    F001 --> F106[F-106: WebSearch連携]
    F004 --> F107[F-107: 検索・一覧]
    F002 --> F110[F-110: 統計強化]
    F003 --> F108[F-108: Draft/Publish]
    F004 --> F109[F-109: エクスポート]

    style F001 fill:#4CAF50,color:#fff
    style F002 fill:#4CAF50,color:#fff
    style F003 fill:#4CAF50,color:#fff
    style F004 fill:#4CAF50,color:#fff
    style F005 fill:#4CAF50,color:#fff
    style F006 fill:#4CAF50,color:#fff
    style F101 fill:#FFC107,color:#000
    style F102 fill:#FFC107,color:#000
    style F103 fill:#FFC107,color:#000
    style F107 fill:#FFC107,color:#000
```

**凡例**: 緑 = Implemented / 黄 = Draft（v1.0 候補）
