# Guide（運用ガイド）

[← doc/index.md に戻る](../index.md)

このディレクトリは **テンプレート提供の運用ガイド** を格納する。プロジェクト共通の手順・カタログ・規約を記載。

---

## ドキュメント一覧

| ファイル | 説明 | 対象者 |
|---------|------|--------|
| [git_workflow.md](./git_workflow.md) | Gitブランチ運用（main ← sprint ← task） | 全員 |
| [ai_template_operation.md](./ai_template_operation.md) | テンプレート導入・更新手順 | 管理者 |
| [commands_catalog.md](./commands_catalog.md) | スキル（手順系）カタログ | AI/開発者 |
| [skills_catalog.md](./skills_catalog.md) | スキル（判断軸系）カタログ | AI/開発者 |
| [ai_guidelines.md](./ai_guidelines.md) | AI運用の詳細規約 | AI |

---

## よく参照するページ

### 開発フロー
1. `/setup` で前提読み込み
2. `/task-list` → `/task-detail` → `/task-run` でタスク実行
3. `doc/guide/git_workflow.md` に従ってブランチ運用

### バグ対応フロー
1. `/bug-new` → `/bug-investigate` → `/bug-propose` → `/bug-fix`
2. PRで `Fixes #...` でIssue紐づけ

### デザインフロー
- 会話起点: `/design-mock` → `/design-ui` → `/design-components` → `/design-assemble`
- Figma起点: `/design-ssot` → `/design-ui` → `/design-components` → `/design-assemble`
