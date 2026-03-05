# ドキュメント索引

このページは `doc/` の **総合入口** です。目的別にナビゲートしてください。

---

## クイックナビ

| 目的 | 場所 |
|------|------|
| 要件・技術スタックを確認したい | [input/rdd.md](./input/rdd.md) |
| アーキテクチャを確認したい | [input/architecture.md](./input/architecture.md) |
| デザインSSOTを確認したい | [input/design/](./input/design/) |
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
└── generated/            # 【AI生成】上書きOK
    ├── index.md          # 索引
    ├── manual/           # /manual-gen の出力先
    └── reverse/          # /docs-reverse の出力先
```

---

## 新人/初見向け読む順序

1. **[input/rdd.md](./input/rdd.md)** - 要件・制約・技術スタック
2. **[input/architecture.md](./input/architecture.md)** - 全体構造・境界・依存方向
3. **`.claude/rules/git-workflow.md`** - ブランチ運用（自動適用）

---

## 各ディレクトリの役割

### input/（人間が書く）
- **誰が**: 人間（プロジェクトオーナー/アーキテクト）
- **いつ**: プロジェクト開始時、変更時
- **何を**: 要件、制約、設計の根拠となる情報

### generated/（AI生成）
- **誰が**: AI（Claude Code）
- **いつ**: `/manual-gen`, `/docs-reverse` 実行時
- **何を**: 手順書、リバースエンジニアリングドキュメント
