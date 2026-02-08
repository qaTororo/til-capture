---
name: til-list
description: >
  This skill should be used when the user asks to "list TILs",
  "search TILs", "show my TILs", "find a TIL", "TIL一覧",
  "TILを検索", "タグ一覧", or any request to browse or search
  previously saved TIL entries.
allowed-tools: Read, Glob, Grep
---

# TIL List / Search

蓄積した TIL の一覧表示・検索を行う。

## 手順

### 1. 保存先の解決

以下の順序で TIL ディレクトリを特定する。

#### Step 1: CWD 内のプロジェクトディレクトリ
以下の3つのパスを CWD からの相対パスで**順に**存在確認する:

1. `{CWD}/src/content/til/`
2. `{CWD}/content/til/`
3. `{CWD}/til/`

最初に見つかったディレクトリを使用する。

#### Step 2: config.json の defaultTilDir
Step 1 で見つからない場合、`~/.config/til-capture/config.json` を Read で読み取る。
`defaultTilDir` フィールドが設定されている場合、そのパスを使用する。

ファイルが存在しないまたは読み取りエラーの場合は次へ。

#### 保存先が見つからない場合
Step 1, 2 で保存先が決まらない場合、以下を案内して終了する:
- `~/.config/til-capture/config.json` に `{"defaultTilDir": "/path/to/til"}` を設定する
- またはプロジェクト内に `til/` ディレクトリを作成する

### 2. コマンドの実行

$ARGUMENTS の内容に応じて以下の処理を分岐する。

#### `/til-list`（引数なし）— 直近の TIL 一覧

1. Glob で `{TILディレクトリ}/*.md` を列挙する
2. ファイル名の日付降順で直近 10 件を選択する
3. 各ファイルの frontmatter から `title`, `date`, `tags` を Read で抽出する
4. 以下のフォーマットで一覧を表示する:

```
TIL 一覧（直近 10 件） — {TILディレクトリ}
1. YYYY-MM-DD - タイトル [tag1, tag2]
2. YYYY-MM-DD - タイトル [tag1]
...
合計: N 件
```

#### `/til-list search <keyword>` — キーワード全文検索

1. Grep で `{TILディレクトリ}/*.md` 内を `<keyword>` で検索する
2. マッチしたファイルの frontmatter から `title`, `date`, `tags` を Read で抽出する
3. 以下のフォーマットで結果を表示する:

```
TIL 検索結果: "<keyword>" — {TILディレクトリ}
1. YYYY-MM-DD - タイトル [tag1, tag2]
   → マッチした行の抜粋
2. ...
合計: N 件ヒット
```

#### `/til-list tags` — タグ別件数

1. Glob で `{TILディレクトリ}/*.md` を列挙する
2. 各ファイルの frontmatter `tags:` 行を Grep で抽出する
3. タグを小文字化して集計し、頻度の高い順に表示する:

```
TIL タグ一覧 — {TILディレクトリ}
bash        (12)
javascript  (8)
docker      (5)
...
合計: N 種類のタグ
```

## 引数

$ARGUMENTS が指定された場合、コマンドのヒントとして使用する。
例: `search docker`, `tags`, 未指定なら一覧表示。
