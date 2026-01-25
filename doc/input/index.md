# Input（人間が書くSSOT）

[← doc/index.md に戻る](../index.md)

このディレクトリは **人間が書く情報源（SSOT）** を格納する。AIはこれを参照して判断・生成を行う。

---

## ドキュメント一覧

| ファイル | 説明 | 更新タイミング |
|---------|------|---------------|
| [rdd.md](./rdd.md) | 要件定義（目標/非目標/技術スタック/制約） | プロジェクト開始時・変更時 |
| [architecture.md](./architecture.md) | アーキテクチャ（構造/境界/依存方向） | 設計変更時 |
| [design/](./design/) | デザインSSOT（tokens/components/context） | デザイン更新時 |

---

## 編集の指針

### rdd.md
- **AI用：事実ブロック**（先頭）を最新に保つ
- 技術スタック変更時は必ず更新
- スキル適用条件に影響

### architecture.md
- 全体構造と境界を明確に
- 依存方向のルールを記載
- 図は Mermaid 推奨

### design/
- `ssot_schema.md` - SSOT JSONの契約
- `design_context.json` - コンテキスト情報
- `copy.json` - 固定テキスト
- `assets/` - 画像等アセット
