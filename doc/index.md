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

`doc/` の外、リポジトリ直下に **`history/`**（`.gitignore` 済み）がある。日々の作業ログ・引き継ぎ日誌の置き場で、セッション間の文脈引き継ぎ・意思決定の経緯記録に使う。クライアントに渡るリポジトリには含まれないので、内部情報も安全に書ける。`doc/input/`（SSOT）や `doc/output/`（送り状）とは役割が異なる「発酵中の思考ログ」。

---

## 新人/初見向け読む順序

1. **[input/rdd.md](./input/rdd.md)** - 要件・制約・技術スタック
2. **[input/architecture.md](./input/architecture.md)** - 全体構造・境界・依存方向
3. **`.claude/rules/git.md`** - ブランチ運用（自動適用）

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
