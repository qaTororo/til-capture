# アーキテクチャ

til-capture の内部構造と処理フローについてのドキュメントです。

## ディレクトリ構成

```
til-capture/
├── .claude-plugin/
│   └── plugin.json          # プラグインメタデータ（名前・バージョン・ライセンス）
├── hooks/
│   ├── stop-hook.sh          # Stop hook: 自動 TIL キャプチャのトリガー
│   └── session-start-hook.sh # SessionStart hook: ステータス表示
├── skills/
│   ├── til/
│   │   └── SKILL.md          # /til スキル定義（手動 TIL 記録の手順）
│   └── til-list/
│       └── SKILL.md          # /til-list スキル定義（TIL 検索・一覧表示）
├── test/
│   ├── test-helper.bash      # テスト共通ヘルパー
│   ├── stop-hook.bats        # Stop hook のテスト
│   ├── session-start-hook.bats # SessionStart hook のテスト
│   └── plugin-validation.bats  # plugin.json のバリデーションテスト
├── docs/
│   ├── adr/                   # ADR（Architecture Decision Records）
│   │   ├── ADR-001〜005       # 設計判断の記録
│   │   └── README.md
│   ├── spec/                  # Living Spec（機能仕様書）
│   │   ├── 00-vision.md〜06-future-features.md
│   │   └── README.md
│   ├── architecture.md       # 本ドキュメント
│   └── security.md           # セキュリティ対策
├── package.json              # テストランナー（bats）の設定
└── README.md
```

## 処理フロー

### Stop hook（自動キャプチャ）

セッション終了時に WebSearch/WebFetch の使用を検知し、TIL 記録を提案します。

```
セッション終了
  │
  ├─ stop_hook_active == true? ─── Yes ──→ 終了（無限ループ防止）
  │
  ├─ 必須フィールド検証 ─── 失敗 ──→ 終了
  │   (session_id, transcript_path, cwd)
  │
  ├─ CWD 安全性検証 ─── 失敗 ──→ 終了
  │   (絶対パス必須、".." 排除)
  │
  ├─ ステートファイル作成（noclobber）─── 既存 ──→ 終了（重複防止）
  │
  ├─ トランスクリプト存在チェック ─── なし ──→ 終了
  │
  ├─ WebSearch/WebFetch 使用チェック ─── なし ──→ 終了
  │
  ├─ config.json 読み取り（defaultTilDir, author）
  │
  ├─ 保存先を解決（下記参照）
  │
  └─ 信頼度に応じた JSON レスポンスを出力
      ├─ 高信頼: 保存先を明示して記録を指示
      ├─ 低信頼: ユーザーに保存先の確認を依頼
      └─ 未設定: アラート表示（設定手順を案内）
```

### SessionStart hook（ステータス表示）

セッション開始時に TIL の状態を表示します。

```
セッション開始
  │
  ├─ CWD 安全性検証
  │
  ├─ config.json 読み取り（defaultTilDir, author）
  │
  ├─ CWD 内 TIL ディレクトリ検出
  │   (src/content/til → content/til → til)
  │
  ├─ .md ファイル数カウント（上限 1001 件で打ち切り）
  │
  ├─ Author 表示用文字列の組み立て（author 設定時のみ）
  │
  └─ ステータス文字列を出力
      ├─ CWD内検出: "Stock: N entries (パス)" [+ Author]
      ├─ config設定 + 存在: "Stock: N entries (パス)" [+ Author]
      ├─ config設定 + 未存在: "Save to: パス (will ask)" [+ Author]
      └─ 未設定: "⚠ No save destination configured..."
```

## 保存先解決ロジック

Stop hook と /til スキルで共通のロジックです。

| 優先度 | ソース | 条件 | 信頼度 |
|--------|--------|------|--------|
| 1 | CWD 内ディレクトリ | `src/content/til/`、`content/til/`、`til/` の順に存在確認 | 高（確認なしで保存） |
| 2 | config.json の `defaultTilDir` | ディレクトリが存在する | 高（確認なしで保存） |
| 2 | config.json の `defaultTilDir` | ディレクトリが存在しない | 低（ユーザーに確認） |
| — | 上記すべて該当なし | — | アラート表示（保存しない） |

config.json に対するバリデーション:

- `defaultTilDir`: 絶対パス必須（`/` で始まること）、パストラバーサル排除（`..` を含まないこと）
- `author`: 文字列であること、空文字列でないこと（不正値は無視）
- 不正値は静かにアラート表示に移行

## 状態管理

### ステートファイル

Stop hook は同一セッションで複数回実行されることを防ぐため、セッション単位のステートファイルを使用します。

- **パス**: `${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/til-capture-$(id -u)/${SESSION_ID}`
- **ディレクトリ権限**: `chmod 700`（ユーザー専用）
- **作成方法**: `noclobber`（`set -C`）によるアトミック操作で TOCTOU を防止
- **ライフサイクル**: セッション終了時に作成。hook が早期終了する場合は削除

## テストアーキテクチャ

### フレームワーク

[bats-core](https://github.com/bats-core/bats-core) を使用。`npm test` で実行。

### テスト隔離戦略

`test-helper.bash` で以下の隔離を実施:

| 対象 | 隔離方法 |
|------|----------|
| `HOME` | `BATS_TEST_TMPDIR/home` に差し替え |
| 作業ディレクトリ | `BATS_TEST_TMPDIR/project` を使用 |
| `TMPDIR` | `BATS_TEST_TMPDIR` に差し替え（ステートファイル分離） |
| `XDG_RUNTIME_DIR` | `unset`（TMPDIR に統一） |
| セッション ID | `test-$$-${BATS_TEST_NUMBER}` でユニーク化 |

### ヘルパー関数

| 関数 | 用途 |
|------|------|
| `common_setup` / `common_teardown` | テスト前後の環境構築・クリーンアップ |
| `get_state_file` | ステートファイルパスの取得 |
| `create_state_file` | ステートファイルの事前作成 |
| `create_transcript` | トランスクリプトファイルの生成 |
| `generate_stop_hook_input` | Stop hook 用 JSON 入力の生成 |
| `generate_session_start_input` | SessionStart hook 用 JSON 入力の生成 |
| `create_config` | config.json の作成（defaultTilDir, author 対応） |
| `create_cwd_til_dir` | CWD 配下に TIL ディレクトリを作成 |
| `add_md_files` | TIL ディレクトリに .md ファイルを追加 |
