# 機能仕様: 自動キャプチャ

> **ステータス**: `[Implemented]` (v0.3.0、v1.0.0 / v1.1.0 で更新)
> **最終更新**: 2026-02-09

## 概要

| 項目 | 値 |
|------|-----|
| **機能 ID** | F-001（自動キャプチャ提案）、F-002（ストック表示 + Author 表示） |
| **種別** | Hook（Stop / SessionStart） |
| **実装** | `hooks/stop-hook.sh` / `hooks/session-start-hook.sh` |
| **テスト** | `test/stop-hook.bats`（25件）/ `test/session-start-hook.bats`（17件） |
| **UX パターン** | A（情報通知）/ B（確認付き提案）/ C（自動実行提案） |

## ユーザーストーリー

### F-001: 自動キャプチャ提案

> 開発者として、セッション中に WebSearch/WebFetch で調べた内容を、セッション終了時に自動で TIL として記録する提案を受けたい。調査しただけのセッションでは提案されないでほしい。

### F-002: ストック表示

> 開発者として、セッション開始時に TIL の蓄積状況を確認したい。学びが積み上がっている実感を得ることで、記録のモチベーションを維持したい。

---

## F-001: 自動キャプチャ提案（Stop hook）

### トリガー条件

セッション終了時（Stop イベント）に以下の**すべて**を満たす場合のみ提案する:

1. `stop_hook_active` が `true` ではない
2. `session_id` が空でも `"null"` でもない
3. `transcript_path` が空でも `"null"` でもない
4. `cwd` が空でも `"null"` でもない
5. `cwd` が絶対パスであり `..` を含まない
6. ステートファイルが存在しない（初回実行）
7. トランスクリプトファイルが存在する
8. トランスクリプト内に `"WebSearch"` または `"WebFetch"` 文字列が含まれる

### 振る舞い仕様

#### 早期終了パターン

| # | 条件 | 出力 | 副作用 | テストケース |
|---|------|------|--------|------------|
| 1 | `stop_hook_active == true` | なし | なし | stop-hook.bats #1 |
| 2 | `session_id` が空 | なし | なし | stop-hook.bats #20 |
| 3 | `transcript_path` が空 | なし | なし | （バリデーション共通） |
| 4 | `cwd` が空 | なし | なし | （バリデーション共通） |
| 5 | `cwd` がパストラバーサルを含む | なし | なし | stop-hook.bats #21 |
| 6 | `cwd` が相対パス | なし | なし | stop-hook.bats #22 |
| 7 | ステートファイルが既に存在 | なし | なし | stop-hook.bats #3, #9 |
| 8 | トランスクリプトファイルが不存在 | なし | ステートファイル削除 | stop-hook.bats #4 |
| 9 | WebSearch/WebFetch 未使用 | なし | ステートファイル削除 | stop-hook.bats #5 |

#### 提案パターン（WebSearch/WebFetch 検知時）

| # | 条件 | 信頼度 | UXパターン | 出力 | テストケース |
|---|------|--------|-----------|------|------------|
| 10 | CWD に `til/` が存在 | 高 | C | `decision: block` + 自動実行メッセージ | stop-hook.bats #10, #18 |
| 11 | CWD に `content/til/` が存在 | 高 | C | `decision: block` + 自動実行メッセージ | stop-hook.bats #11 |
| 12 | CWD に `src/content/til/` が存在 | 高 | C | `decision: block` + 自動実行メッセージ | stop-hook.bats #12 |
| 13 | CWD に複数の TIL ディレクトリ | 高 | C | 最優先ディレクトリを使用 | stop-hook.bats #13 |
| 14 | config.json + ディレクトリ存在 | 高 | C | `decision: block` + 自動実行メッセージ | stop-hook.bats #14 |
| 15 | config.json + ディレクトリ未存在 | 低 | B | `decision: block` + 確認付きメッセージ | stop-hook.bats #15, #19 |
| 16 | config.json なし + CWD に til/ なし | — | — | `decision: block` + アラートメッセージ | stop-hook.bats #16 |
| 17 | CWD ディレクトリ > config.json | 高 | C | CWD のパスを使用 | stop-hook.bats #17 |

#### セキュリティ検証パターン

| # | 条件 | 出力 | 副作用 | テストケース |
|---|------|------|--------|------------|
| 18 | config.json にパストラバーサル | アラート表示 | 不正値は無視 | stop-hook.bats #23 |
| 19 | config.json に相対パス | アラート表示 | 不正値は無視 | stop-hook.bats #24 |

### 状態管理

| 項目 | 詳細 |
|------|------|
| **ステートディレクトリ** | `${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/til-capture-$(id -u)/` |
| **ステートファイル** | `{ステートディレクトリ}/{session_id}` |
| **ディレクトリ権限** | `chmod 700`（ユーザー専用） |
| **作成方法** | `set -C`（noclobber）によるアトミック作成 |
| **ライフサイクル** | 作成 → 早期終了時は削除 / 正常終了時は保持 |

**状態遷移**:

| テストケース | ステートファイル作成 | ステートファイル削除 |
|------------|-------------------|-------------------|
| stop-hook.bats #8 | Yes | No |
| stop-hook.bats #4（トランスクリプト不在） | Yes → 削除 | Yes |
| stop-hook.bats #5（WebSearch 未使用） | Yes → 削除 | Yes |
| stop-hook.bats #9（2回目実行） | 既存のため作成失敗 → 早期終了 | No |

### メッセージ仕様

[02-ux-patterns.md](./02-ux-patterns.md#パターン-b-確認付き提案低信頼) のパターン B/C を参照。

### セキュリティ要件

- 入力バリデーション: [security.md §1](../security.md)
- パストラバーサル対策: [security.md §2](../security.md)
- 無限ループ防止: [security.md §3](../security.md)
- TOCTOU 防止: [security.md §4](../security.md)
- ディレクトリ権限: [security.md §5](../security.md)

---

## F-002: ストック表示（SessionStart hook）

### トリガー条件

セッション開始時（SessionStart イベント）に**常に**実行される。

### 振る舞い仕様

#### TIL ディレクトリ検出とカウント

| # | 条件 | 出力 | テストケース |
|---|------|------|------------|
| 1 | CWD に `til/` が存在 + .md あり | `Stock: N entries (パス)` | session-start-hook.bats #1 |
| 2 | CWD に `content/til/` が存在 | `Stock: N entries (パス)` | session-start-hook.bats #2 |
| 3 | CWD に `src/content/til/` が存在 | `Stock: N entries (パス)` | session-start-hook.bats #3 |
| 4 | TIL ディレクトリが空 | `Stock: 0 entries (パス)` | session-start-hook.bats #4 |
| 5 | 複数 .md ファイル | `Stock: N entries (パス)` | session-start-hook.bats #5 |
| 6 | .md 以外のファイル | カウント対象外 | session-start-hook.bats #6 |

#### config.json 連携

| # | 条件 | 出力 | テストケース |
|---|------|------|------------|
| 7 | config.json + ディレクトリ存在 | `Stock: N entries (パス)` | session-start-hook.bats #7 |
| 8 | config.json + ディレクトリ未存在 | `Save to: パス (will ask)` | session-start-hook.bats #8 |
| 9 | config.json なし + CWD に til/ なし | `⚠ No save destination configured...` | session-start-hook.bats #9 |

#### 優先順位と出力形式

| # | 条件 | 出力 | テストケース |
|---|------|------|------------|
| 10 | CWD の `til/` > config.json | CWD のパスとカウントを使用 | session-start-hook.bats #10 |
| 11 | JSON 出力構造 | `hookEventName: "SessionStart"` | session-start-hook.bats #11 |
| 12 | 共通プレフィックス | `TIL auto-capture: ON (WebSearch/WebFetch)` | session-start-hook.bats #12 |

### カウント仕様

| 項目 | 詳細 |
|------|------|
| **対象** | `.md` 拡張子のファイルのみ |
| **上限** | 1001 件で打ち切り（`head -n 1001`） |
| **上限超過時の表示** | `1000+ entries` |
| **カウント方法** | `find ... -name "*.md" -type f` |

### セキュリティ要件

- CWD の安全性検証: パストラバーサル・相対パスは空文字に置換（静かにフォールバック）
- config.json の検証: 不正値は空文字に置換
- 性能対策: [security.md §6](../security.md)

---

## 変更履歴

### v1.0.0

- **F-001**: フォールバック `~/til/` を削除、保存先未設定時はアラート表示に変更（[ADR-004](../adr/ADR-004-directory-resolution-strategy.md)）
- **F-002**: アラートメッセージで設定手順を案内
- **F-103**: 重複チェックをスコープ外に変更（[ADR-005](../adr/ADR-005-v1.1-team-usage-and-scope.md)）

### v1.1.0

- **F-002**: config.json の `author` フィールドを読み取り、セッション開始時に `| Author: username` を表示（[F-111](./01-feature-inventory.md)）
- **F-001**: config.json から `author` を読み取り、TIL 記録指示メッセージに反映

### 将来バージョンでの検討

- **F-104: PostToolUse(Write) 連携** — TIL 書き込み後のメタデータ自動付与
- **F-106: PostToolUse(WebSearch) 連携** — 調査トピックのリアルタイム蓄積
- **F-110: 統計・サマリー表示の強化** — ストック表示の情報量拡充
