# til-capture Living Spec

> **ステータス**: Draft
> **対象バージョン**: v1.1
> **最終更新**: 2026-02-08

## この文書について

本ディレクトリは til-capture v1.0 の **Living Spec（機能仕様書）** です。
プロダクトの「何を・なぜ・どう振る舞うか」を定義し、実装（How）は [architecture.md](../architecture.md) に委ねます。

### Living Spec とは

- 実装と共に進化する仕様書
- 設計判断の根拠を記録し、チームの共通理解を維持する
- 機能追加・変更時にまず仕様を更新し、実装はそれに従う

## ステータス表記

各仕様にはステータスが付与されます:

| ステータス | 意味 | 次のアクション |
|-----------|------|--------------|
| `[Draft]` | 初期案。検討・議論中 | レビューを経て Proposed へ |
| `[Proposed]` | レビュー済みの提案 | 承認を経て Accepted へ |
| `[Accepted]` | 承認済み。実装可能 | 実装完了後に Implemented へ |
| `[Implemented]` | 実装済み。テストで検証済み | 必要に応じて改訂 |

## 目次

| # | ファイル | 概要 | ステータス |
|---|---------|------|-----------|
| 0 | [00-vision.md](./00-vision.md) | ビジョン・設計原則・ペルソナ | Draft |
| 1 | [01-feature-inventory.md](./01-feature-inventory.md) | 機能インベントリと優先度マトリクス | Draft |
| 2 | [02-ux-patterns.md](./02-ux-patterns.md) | UI/UX パターン定義（中核ドキュメント） | Draft |
| 3 | [03-auto-capture.md](./03-auto-capture.md) | 機能仕様: 自動キャプチャ（Stop hook） | Implemented |
| 4 | [04-manual-capture.md](./04-manual-capture.md) | 機能仕様: 手動キャプチャ（/til スキル） | Implemented |
| 5 | [05-config.md](./05-config.md) | 機能仕様: 設定・保存先解決 | Implemented |
| 6 | [06-future-features.md](./06-future-features.md) | v1.0 候補機能の仕様ドラフト | Draft |

## 関連ドキュメント

| ドキュメント | 役割 | 関係 |
|-------------|------|------|
| [ADR](../adr/README.md) | 設計判断の記録 (Why) | ADR の決定に基づいて Spec のステータスを昇格 |
| [architecture.md](../architecture.md) | 実装の内部構造 (How) | 本 Spec から参照。実装詳細はそちらに記載 |
| [security.md](../security.md) | セキュリティ対策 | 各機能仕様からセキュリティ要件として参照 |
| [README.md](../../README.md) | ユーザー向け利用ガイド | Spec 確定後に v1.0 用に更新 |

## 読み方ガイド

### 初めて読む場合

1. **[00-vision.md](./00-vision.md)** でプロダクトの方向性を理解
2. **[01-feature-inventory.md](./01-feature-inventory.md)** で機能の全体像を把握
3. **[02-ux-patterns.md](./02-ux-patterns.md)** で UI/UX の設計方針を確認
4. 興味のある機能の仕様（03〜06）を個別に参照

### 機能を実装・変更する場合

1. 対象機能の仕様ファイル（03〜06）を確認
2. [02-ux-patterns.md](./02-ux-patterns.md) のパターンに従って UI を設計
3. [architecture.md](../architecture.md) で実装上の制約を確認
4. [security.md](../security.md) でセキュリティ要件を確認

### 新機能を提案する場合

1. [06-future-features.md](./06-future-features.md) に `[Draft]` で追記
2. [01-feature-inventory.md](./01-feature-inventory.md) の候補テーブルに登録
3. レビューを経て優先度を決定
