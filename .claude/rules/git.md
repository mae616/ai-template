# Git ブランチ運用ルール

## ブランチ構造
```
main                    ← リリース可能な安定版（直接push禁止）
├── sprint/*            ← スプリント単位（CI通過後にmainへマージ）
│   ├── task/*          ← 1タスク=1AI実装単位（動作不要）
│   └── feature_fix/*   ← スプリント統合後のバグ修正
└── hotfix/*            ← 本番緊急修正（mainから作成→mainへ直接マージ）
```

## 命名規則
- sprint: `sprint/YYYY-MM-機能名` (例: `sprint/2025-01-chat-ui`)
- task: `task/YYYY-MM-機能名-詳細` (例: `task/2025-01-chat-ui-header`)
- feature_fix: `feature_fix/バグ概要` (例: `feature_fix/combined-run-error`)
- hotfix: `hotfix/バグ概要` (例: `hotfix/critical-auth-bug`)

## CI要件
| ブランチ | Lint | TypeCheck | Build | Test |
|---------|:----:|:---------:|:-----:|:----:|
| task/*, feature_fix/* | o | o | - | - |
| sprint/* → main PR | o | o | o | o |
| hotfix/* → main PR | o | o | o | o |

## 基本ルール
- sprint: 1日1回は `main` を取り込む（ブランチ腐り防止）
- task: 必ず最新の `sprint/*` から作成。PRは小さく保つ
- hotfix: マージ後、進行中の `sprint/*` にも取り込む
- 1スプリント = 1〜3日が理想

## レビュー
- task/* → sprint/*: 人 + AI（コード品質、設計意図）
- sprint/* → main: 人 + AI（統合テスト結果、リリース可否）
- hotfix/* → main: 人優先（緊急度と影響範囲）
