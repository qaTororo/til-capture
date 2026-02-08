# 機能仕様: 設定・保存先解決

> **ステータス**: `[Implemented]` (v0.3.0)
> **最終更新**: 2026-02-08

## 概要

| 項目 | 値 |
|------|-----|
| **機能 ID** | F-004（保存先解決）、F-005（信頼度ベースの確認） |
| **種別** | ロジック / UX |
| **実装** | `hooks/stop-hook.sh`（L60-95）/ `hooks/session-start-hook.sh`（L18-54）/ `skills/til/SKILL.md` |
| **テスト** | stop-hook.bats #10-19, #23-24 / session-start-hook.bats #1-10 |

## ユーザーストーリー

### F-004: 保存先解決

> 開発者として、TIL の保存先を明示的に設定しなくても適切な場所に保存されてほしい。プロジェクト内に TIL ディレクトリがあればそこに、なければ設定に従ってほしい。

### F-005: 信頼度ベースの確認

> 開発者として、よく使う保存先には確認なしで保存してほしいが、初めて使う場所やフォールバック先には確認を求めてほしい。

## 保存先解決ロジック

### 優先順位

```mermaid
flowchart TD
    A[保存先解決開始] --> B{CWD 内に TIL<br/>ディレクトリがある?}
    B -->|Yes| C[CWD 内ディレクトリを使用<br/>信頼度: 高]
    B -->|No| D{config.json に<br/>defaultTilDir がある?}
    D -->|Yes| E{ディレクトリが<br/>存在する?}
    E -->|Yes| F[config.json のパスを使用<br/>信頼度: 高]
    E -->|No| G[config.json のパスを使用<br/>信頼度: 低]
    D -->|No| H["~/til/ を使用<br/>信頼度: 低"]
```

### Step 1: CWD 内のプロジェクトディレクトリ

以下の 3 つのパスを CWD からの相対パスで**順に**存在確認する。最初に見つかったディレクトリを使用する。

| 優先度 | パス | 想定用途 |
|--------|------|---------|
| 1 | `{CWD}/src/content/til/` | Astro 等の SSG プロジェクト |
| 2 | `{CWD}/content/til/` | Hugo 等の SSG プロジェクト |
| 3 | `{CWD}/til/` | 汎用プロジェクト |

**信頼度**: 高（ディレクトリが存在するため）

**テストケースとの紐付け**:

| テスト | 条件 | 検証内容 |
|--------|------|---------|
| stop-hook.bats #10 | `til/` 存在 | 高信頼メッセージ |
| stop-hook.bats #11 | `content/til/` 存在 | 高信頼メッセージ + 正しいパス |
| stop-hook.bats #12 | `src/content/til/` 存在 | 高信頼メッセージ + 正しいパス |
| stop-hook.bats #13 | 3つ全部存在 | `src/content/til` が選択される |
| stop-hook.bats #17 | CWD `til/` + config.json | CWD が優先 |
| session-start-hook.bats #1 | `til/` 存在 | Stock 表示 |
| session-start-hook.bats #2 | `content/til/` 存在 | 正しいカウント |
| session-start-hook.bats #3 | `src/content/til/` 存在 | 正しいカウント + パス |
| session-start-hook.bats #10 | CWD `til/` + config.json | CWD が優先 |

### Step 2: config.json の defaultTilDir

CWD 内にディレクトリが見つからない場合、設定ファイルを参照する。

#### 設定ファイル

| 項目 | 値 |
|------|-----|
| **パス** | `~/.config/til-capture/config.json` |
| **形式** | JSON |
| **必須** | No（ファイルが存在しなくてもエラーにならない） |

#### スキーマ

```jsonc
{
  "defaultTilDir": "/absolute/path/to/til"  // 絶対パス必須
}
```

#### バリデーションルール

| チェック | 不正時の動作 | テストケース |
|---------|------------|------------|
| 絶対パスであること（`/` 始まり） | 値を無視してフォールバック | stop-hook.bats #24 |
| `..` を含まないこと | 値を無視してフォールバック | stop-hook.bats #23 |
| JSON パースエラー | 値を無視してフォールバック | — |
| `defaultTilDir` フィールド未設定 | 値を無視してフォールバック | — |

#### 信頼度判定

| 条件 | 信頼度 | テストケース |
|------|--------|------------|
| `defaultTilDir` のディレクトリが存在する | 高 | stop-hook.bats #14 / session-start-hook.bats #7 |
| `defaultTilDir` のディレクトリが存在しない | 低 | stop-hook.bats #15 / session-start-hook.bats #8 |

### Step 3: フォールバック `~/til/`（v1.0 で削除予定）

> **⚠ v1.0 変更予定（[ADR-004](../adr/ADR-004-directory-resolution-strategy.md)）**: フォールバック `~/til/` は v1.0 で削除される。CWD に `til/` がなく、config.json にも `defaultTilDir` が設定されていない場合は、アラートを表示して保存を行わない方針に変更。詳細は ADR-004 を参照。

Step 1, 2 で保存先が決まらない場合のデフォルト値（v0.3 での動作）。

| 項目 | 値 |
|------|-----|
| **パス** | `~/til/`（`$HOME/til`） |
| **信頼度** | 低（常にユーザー確認が必要） |
| **テストケース** | stop-hook.bats #16 / session-start-hook.bats #9 |

## 信頼度ベースの確認（F-005）

### 信頼度テーブル

| 信頼度 | 条件 | Stop hook の動作 | Skill の動作 |
|--------|------|----------------|-------------|
| **高** | CWD 内ディレクトリ存在 | 自動実行メッセージ（パターン C） | 確認なしで保存 |
| **高** | config.json + ディレクトリ存在 | 自動実行メッセージ（パターン C） | 確認なしで保存 |
| **低** | config.json + ディレクトリ未存在 | 確認付きメッセージ（パターン B） | ユーザー確認後に保存 |
| **低** | フォールバック `~/til/` | 確認付きメッセージ（パターン B） | ユーザー確認後に保存 |

### メッセージの違い

#### 高信頼メッセージ（パターン C）

```
保存先: {パス}
```
- 「記録します」（断定的）
- 手順の提示: 特定 → 保存 → 報告
- 「ユーザーが不要と判断した場合はスキップ」の余地

#### 低信頼メッセージ（パターン B）

```
保存先候補: {パス}
```
- 「記録しませんか？」（提案的）
- 「このディレクトリはまだ存在しないか、明示的に設定されていません」
- 手順: 確認 → 承認で保存 / 拒否でスキップ
- config.json 設定の案内

**テストケースとの紐付け**:

| テスト | 検証内容 |
|--------|---------|
| stop-hook.bats #18 | 高信頼: `保存先:` と `保存先ディレクトリ` がメッセージに含まれる |
| stop-hook.bats #19 | 低信頼: `保存先候補:` と `保存してよいですか` がメッセージに含まれる |
| stop-hook.bats #14 | config.json 高信頼: `記録します` が含まれる |
| stop-hook.bats #15 | config.json 低信頼: `確認` が含まれる |

## 実装ごとの差異

保存先解決ロジックは 3 つの実装で共有されるが、微妙な差異がある:

| 実装 | CWD 検証 | config.json パス検証 | フォールバック動作 |
|------|---------|-------------------|--------------------|
| **stop-hook.sh** | 不正値 → `exit 0` | 不正値 → 空文字化 → フォールバック | `$HOME/til` を設定 |
| **session-start-hook.sh** | 不正値 → 空文字化 | 不正値 → 空文字化 → フォールバック | フォールバック表示 |
| **SKILL.md** | Claude の判断に依存 | Claude が Read で読み取り | ユーザーに確認を求める指示 |

> **設計ノート**: Hook（Shell スクリプト）は厳密なバリデーションを行うが、Skill（Claude 解釈）は SKILL.md の指示に従う柔軟な動作となる。信頼度の概念は共通だが、実装手段が異なる。

## セキュリティ要件

- パストラバーサル対策: [security.md §2](../security.md)
- config.json の不正値は静かにフォールバック（エラーメッセージを出さない）
- フォールバック `~/til/` への書き込みは常にユーザー確認必須

## v1.0 での変更予定

### 確定事項（ADR で決定済み）

1. **フォールバック `~/til/` の削除**（[ADR-004](../adr/ADR-004-directory-resolution-strategy.md)）
   - CWD `til/` も config.json `defaultTilDir` もない場合 → アラート表示、保存しない
   - config.json が存在するが `defaultTilDir` が null/空 → アラート表示
   - 初回オンボーディング: SessionStart hook で Claude にセットアップ支援を依頼する導線を追加

2. **config.json `defaultTilDir` の実質必須化**（[ADR-004](../adr/ADR-004-directory-resolution-strategy.md)）
   - CWD 内に `til/` がない環境では、config.json の設定が必須

### v1.1+ で検討

- **F-101: テンプレートカスタマイズ** — config.json の拡張（テンプレート設定の追加）
- config.json スキーマの拡張可能性:
  ```jsonc
  {
    "defaultTilDir": "/path/to/til",  // v1.0 で実質必須化
    "template": {                      // F-101 で追加予定（v1.1+）
      "frontmatter": { ... },
      "sections": [ ... ]
    }
  }
  ```
