# ドキュメント索引

このページは `doc/` の **総合入口** です。目的別にナビゲートしてください。

---

## メンテナンス情報
- **最終更新日**: 2026-01-25
- **テンプレートバージョン**: ai-template v1.0

---

## クイックナビ

| 目的 | 場所 |
|------|------|
| 要件・技術スタックを確認したい | [input/rdd.md](./input/rdd.md) |
| アーキテクチャを確認したい | [input/architecture.md](./input/architecture.md) |
| Gitブランチ運用を確認したい | [guide/git_workflow.md](./guide/git_workflow.md) |
| コマンド/スキル一覧を見たい | [guide/commands_catalog.md](./guide/commands_catalog.md) |
| AI生成ドキュメントを見たい | [generated/index.md](./generated/index.md) |

---

## ディレクトリ構造

```
doc/
├── index.md              # このファイル（総合入口）
│
├── input/                # 【人間が書く】SSOT
│   ├── index.md          # 索引
│   ├── rdd.md            # 要件定義
│   ├── architecture.md   # アーキテクチャ
│   └── design/           # デザインSSOT
│
├── guide/                # 【テンプレ提供】運用ガイド
│   ├── index.md          # 索引
│   ├── git_workflow.md   # Gitブランチ運用
│   ├── ai_template_operation.md
│   ├── commands_catalog.md
│   ├── skills_catalog.md
│   └── ai_guidelines.md
│
├── generated/            # 【AI生成】上書きOK
│   ├── index.md          # 索引
│   ├── manual/           # /manual-gen の出力先
│   └── reverse/          # /docs-reverse の出力先
│
└── devlog/               # 作業ログ
```

---

## 新人/初見向け読む順序

1. **[input/rdd.md](./input/rdd.md)** - 要件・制約・技術スタック
2. **[input/architecture.md](./input/architecture.md)** - 全体構造・境界・依存方向
3. **[guide/git_workflow.md](./guide/git_workflow.md)** - ブランチ運用
4. **[guide/ai_template_operation.md](./guide/ai_template_operation.md)** - テンプレ運用

---

## AI向け参照の優先順位（SSOT）

1. `CLAUDE.md`（憲法）
2. `doc/input/rdd.md`（プロジェクト固有の事実）
3. `.claude/skills/*/SKILL.md`（判断軸）
4. `doc/guide/ai_guidelines.md`（詳細運用）

---

## 各ディレクトリの役割

### input/（人間が書く）
- **誰が**: 人間（プロジェクトオーナー/アーキテクト）
- **いつ**: プロジェクト開始時、変更時
- **何を**: 要件、制約、設計の根拠となる情報

### guide/（テンプレ提供）
- **誰が**: テンプレートメンテナー
- **いつ**: テンプレート更新時
- **何を**: 運用手順、カタログ、規約

### generated/（AI生成）
- **誰が**: AI（Claude Code）
- **いつ**: `/manual-gen`, `/docs-reverse` 実行時
- **何を**: 手順書、リバースエンジニアリングドキュメント
