# til-capture ADR（Architecture Decision Records）

> **最終更新**: 2026-02-08

## この文書について

本ディレクトリは til-capture の設計判断を ADR として記録する場所です。
Living Spec（`docs/spec/`）が「何を・なぜ」を定義するのに対し、ADR は「なぜその選択肢を採用したか」の判断根拠を記録します。

### ADR と Living Spec の関係

```
ADR（判断の記録）          Living Spec（仕様の定義）
┌──────────────┐          ┌──────────────┐
│ ADR-001      │──決定──→│ 02-ux-patterns│
│ [Accepted]   │          │ [Draft]→[Accepted]
└──────────────┘          └──────────────┘
```

**ワークフロー**:
1. Draft の Spec に対して未決定事項を識別する
2. ADR を `[Proposed]` で作成し、選択肢を分析する
3. 決定を下し、ADR を `[Accepted]` にする
4. 対応する Spec のステータスを昇格させる（`[Draft]` → `[Accepted]`）

## ステータス

| ステータス | 意味 |
|-----------|------|
| `[Proposed]` | 提案中。レビュー・議論を受け付けている |
| `[Accepted]` | 承認済み。この判断に従って実装を進める |
| `[Superseded]` | 別の ADR により置き換えられた（後継 ADR へのリンクを記載） |

## ADR 一覧

| # | タイトル | ステータス | 関連 Spec | 日付 |
|---|---------|-----------|-----------|------|
| [001](./ADR-001-trust-based-confirmation-flow.md) | 信頼度ベースの確認フロー | `[Accepted]` | 02-ux-patterns, 05-config | 2026-02-08 |
| [002](./ADR-002-v1-feature-priority.md) | v1.0 機能の優先順位 | `[Accepted]` | 01-feature-inventory, 06-future | 2026-02-08 |
| [003](./ADR-003-new-hook-event-strategy.md) | 新規 Hook イベント活用方針 | `[Accepted]` | 06-future-features | 2026-02-08 |
| [004](./ADR-004-directory-resolution-strategy.md) | 保存先ディレクトリ解決戦略 | `[Accepted]` | 05-config | 2026-02-08 |

<!-- 新しい ADR を追加したらここに行を追加する -->

## ADR の作成方法

1. [TEMPLATE.md](./TEMPLATE.md) をコピーする
2. ファイル名: `ADR-NNN-kebab-case-title.md`（例: `ADR-001-ux-layer-architecture.md`）
3. 番号は連番（001, 002, ...）
4. テンプレートに沿って内容を記述する
5. ステータスを `[Proposed]` で作成し、決定後に `[Accepted]` に変更する

## 補足

> **除外した候補**: UI レイヤーの 3 層構造（Hook→Claude→ユーザー）は Claude Code プラグインの制約からの帰結であり、選択肢がないため ADR 対象外とした。02-ux-patterns.md のアーキテクチャ背景として記録されている。

## 関連ドキュメント

| ドキュメント | 関係 |
|-------------|------|
| [Living Spec](../spec/README.md) | ADR の決定に基づいて仕様を確定する |
| [architecture.md](../architecture.md) | ADR の決定に基づいて実装構造を設計する |
| [security.md](../security.md) | セキュリティに関わる判断は ADR で記録する |
