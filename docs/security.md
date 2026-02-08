# セキュリティ対策

til-capture で実施しているセキュリティ対策の一覧です。

## 入力バリデーション

Stop hook は stdin から受け取る JSON の必須フィールドを検証します。

| フィールド | 検証内容 |
|-----------|---------|
| `session_id` | 空・null でないこと |
| `transcript_path` | 空・null でないこと |
| `cwd` | 空・null でないこと |

いずれかが欠落している場合、hook は即座に `exit 0` で正常終了します（エラーにはしない）。

## パストラバーサル対策

CWD と config.json の `defaultTilDir` の両方に対して、パストラバーサル攻撃を防止します。

### 検証ルール

1. **絶対パス必須**: `/` で始まらないパスは拒否
2. **`..` 排除**: パス中に `..` を含む場合は拒否

```bash
# CWD の検証
if [[ ! "$CWD" =~ ^/ ]] || [[ "$CWD" =~ \.\. ]]; then
  exit 0
fi

# defaultTilDir の検証
if [[ ! "$TIL_DIR" =~ ^/ ]] || [[ "$TIL_DIR" =~ \.\. ]]; then
  TIL_DIR=""  # 静かにフォールバック
fi
```

### 対象箇所

- **Stop hook**: CWD（即座に終了）、defaultTilDir（フォールバック）
- **SessionStart hook**: CWD（空文字に置換）、defaultTilDir（フォールバック）

## 無限ループ防止

Stop hook が TIL 記録を提案 → Claude が応答 → 再度 Stop hook が発火、という無限ループを防止します。

### 二重の防止メカニズム

1. **`stop_hook_active` フラグ**: Claude Code が提供する公式フィールド。Stop hook 内からの再実行時に `true` になる
2. **セッション単位のステートファイル**: 同一セッション ID で2回目以降の実行を防止

## TOCTOU 防止

ステートファイルの存在チェックと作成を原子的に行い、Time of Check to Time of Use (TOCTOU) の競合状態を防止します。

```bash
# noclobber (set -C) でアトミックに作成
# ファイルが既に存在する場合はコマンドが失敗する
if ! (set -C; : > "$STATE_FILE") 2>/dev/null; then
  exit 0  # 既に実行済み
fi
```

`set -C`（noclobber）により、ファイルの存在チェックと作成が単一のシステムコールで行われます。

## ディレクトリ権限

ステートファイルを格納するディレクトリは `chmod 700` で作成され、所有ユーザーのみがアクセスできます。

```bash
STATE_DIR="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/til-capture-$(id -u)"
mkdir -p "$STATE_DIR" 2>/dev/null && chmod 700 "$STATE_DIR" 2>/dev/null || true
```

- ディレクトリ名に `$(id -u)` を含めてユーザー単位で分離
- `XDG_RUNTIME_DIR` が利用可能な場合は優先使用（通常 `/run/user/<uid>/` で既にユーザー専用）

## 性能対策

SessionStart hook での .md ファイル数カウントは、大量のファイルがある場合の性能劣化を防止します。

```bash
find "$dir" -name "*.md" -type f 2>/dev/null | head -n 1001 | wc -l
```

- `head -n 1001` で 1001 件を超えるファイルの走査を打ち切り
- 1000 件を超える場合は「1000+ entries」と表示
- `find` の出力をパイプで制限することで、ディレクトリ全体を走査しない
