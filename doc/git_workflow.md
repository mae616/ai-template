# Git ブランチ運用ガイド

このドキュメントは、AI協働開発における Git ブランチ戦略と運用ルールを定義する。

## メンテナンス情報
- **最終更新日**: 2026-01-25
- **対象**: ai-template を使用するすべてのプロジェクト

---

## ブランチ構造（概要）

```
main
├── sprint/*          ← スプリント単位（CI通過後にmainへマージ）
│   ├── task/*        ← タスク単位（AI実装、動作不要）
│   └── feature_fix/* ← スプリント統合後のバグ修正
└── hotfix/*          ← 本番緊急修正
```

---

## ブランチ種別と運用ルール

### 1. `main` ブランチ

| 項目 | 内容 |
|------|------|
| **目的** | リリース可能な安定版 |
| **保護** | 強め（直接pushは原則禁止） |
| **マージ元** | `sprint/*`, `hotfix/*` |
| **CI要件** | フルビルド + 全テスト通過 |

**ルール**:
- 常に動作する状態を維持
- スプリント単位でまとめてマージ
- 緊急時のみ `hotfix/*` から直接マージ

---

### 2. `sprint/*` ブランチ

| 項目 | 内容 |
|------|------|
| **目的** | スプリント期間の作業集約 |
| **命名例** | `sprint/2025-01-chat-ui` |
| **ベース** | `main` |
| **マージ先** | `main` |
| **CI要件** | フルビルド + 全テスト通過（mainへのPR時） |

**ルール**:
- スプリント開始時に `main` から作成
- このブランチに `task/*` と `feature_fix/*` をマージ
- **1日1回は `main` を取り込む**（ブランチ腐り防止）
- スプリント完了時に `main` へPRを作成

**ライフサイクル**:
```bash
# 作成
git switch main && git pull
git switch -c sprint/2025-01-chat-ui

# main取り込み（定期）
git fetch origin main
git merge origin/main  # または rebase

# 完了時
gh pr create --base main --title "Sprint: チャットUI実装"
```

---

### 3. `task/*` ブランチ

| 項目 | 内容 |
|------|------|
| **目的** | 1タスク = 1 AI実装単位 |
| **命名例** | `task/2025-01-chat-ui-header` |
| **ベース** | **最新の `sprint/*`** |
| **マージ先** | `sprint/*` |
| **CI要件** | Lint + TypeCheck のみ（動作不要） |

**ルール**:
- **必ず最新の `sprint/*` から作成**
- AI（Claude Code）に実装を任せる単位
- 動作しなくてもOK（sprintで統合後に検証）
- PRは小さく保つ（UIだけ、APIだけ、testだけ）

**ライフサイクル**:
```bash
# 作成（最新sprintから）
git switch sprint/2025-01-chat-ui && git pull
git switch -c task/2025-01-chat-ui-header

# 実装後
gh pr create --base sprint/2025-01-chat-ui --title "Task: ヘッダーUI実装"

# 他のtaskがマージされた後のrebase（コンフリクト防止）
git fetch origin sprint/2025-01-chat-ui
git rebase origin/sprint/2025-01-chat-ui
```

**コンフリクト防止**:
- taskマージ後、他の作業中taskは最新sprintにrebaseする
- AI向けカスタムコマンド: 「最新sprintにrebaseしてPR用diff整えて」

---

### 4. `feature_fix/*` ブランチ

| 項目 | 内容 |
|------|------|
| **目的** | スプリント統合後に発見されたバグ修正 |
| **命名例** | `feature_fix/combined-run-error` |
| **ベース** | `sprint/*` |
| **マージ先** | `sprint/*` |
| **CI要件** | Lint + TypeCheck |

**ルール**:
- task単体では見えなかったバグを修正
- sprintブランチで `npm run dev` → バグ発見 → このブランチで修正
- `/bug-*` コマンドでトラブルシュート

**ライフサイクル**:
```bash
# 作成
git switch sprint/2025-01-chat-ui
git switch -c feature_fix/combined-run-error

# 修正後
gh pr create --base sprint/2025-01-chat-ui --title "Fix: 統合実行時のエラー修正"
```

---

### 5. `hotfix/*` ブランチ

| 項目 | 内容 |
|------|------|
| **目的** | 本番環境の緊急修正 |
| **命名例** | `hotfix/critical-auth-bug` |
| **ベース** | `main` |
| **マージ先** | `main`（+ 必要に応じて `sprint/*`） |
| **CI要件** | フルビルド + 全テスト通過 |

**ルール**:
- 本番で発生した緊急バグのみ使用
- mainから直接作成、mainに直接マージ
- マージ後、進行中の `sprint/*` にも取り込む

**ライフサイクル**:
```bash
# 作成
git switch main && git pull
git switch -c hotfix/critical-auth-bug

# 修正後（mainへ）
gh pr create --base main --title "Hotfix: 認証バグ緊急修正"

# マージ後、sprintにも取り込み
git switch sprint/2025-01-chat-ui
git merge main
```

---

## CI設定の段階分け

| ブランチ | Lint | TypeCheck | Build | Test |
|---------|:----:|:---------:|:-----:|:----:|
| `task/*` | ✅ | ✅ | - | - |
| `feature_fix/*` | ✅ | ✅ | - | - |
| `sprint/*` → `main` PR | ✅ | ✅ | ✅ | ✅ |
| `hotfix/*` → `main` PR | ✅ | ✅ | ✅ | ✅ |

**GitHub Actions 設定例**:
```yaml
# .github/workflows/ci.yml
on:
  pull_request:
    branches: [main, 'sprint/**']

jobs:
  lint-typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - run: pnpm install
      - run: pnpm lint
      - run: pnpm type-check

  build-test:
    if: github.base_ref == 'main'
    needs: lint-typecheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - run: pnpm install
      - run: pnpm build
      - run: pnpm test
```

---

## レビュー方針

### マージ時のレビュー（※印）

| マージ | レビュアー | 観点 |
|--------|-----------|------|
| `task/*` → `sprint/*` | 人 + AI(Codex) | コード品質、設計意図 |
| `sprint/*` → `main` | 人 + AI(Codex) | 統合テスト結果、リリース可否 |
| `hotfix/*` → `main` | 人（優先） | 緊急度と影響範囲 |

### AIレビューの活用
- PRの差分をAIに渡してレビュー依頼
- 設計意図の確認、潜在バグの検出
- セキュリティ観点のチェック

---

## よくあるシナリオ

### シナリオ1: 通常のスプリント開発

```
1. sprint/xxx を main から作成
2. task/xxx-a, task/xxx-b を sprint から作成
3. 各taskで実装 → sprint へPR → マージ
4. sprint上で統合テスト
5. バグ発見 → feature_fix/xxx で修正 → sprint へマージ
6. sprint → main へPR → レビュー → マージ
```

### シナリオ2: 本番緊急バグ

```
1. hotfix/xxx を main から作成
2. 修正実装
3. hotfix → main へPR → レビュー → マージ
4. 進行中の sprint に main を取り込み
```

### シナリオ3: 特定タスクだけ先にmainへ入れたい

```
原則: スプリント単位でマージするため非推奨

どうしても必要な場合:
1. 該当taskを cherry-pick で hotfix として扱う
2. または、スプリントを短くして早めにマージ
```

---

## 推奨: スプリントを短く保つ

- **1スプリント = 1〜3日** が理想
- ブランチが長生きするとコンフリクト地獄になる
- AI開発ではタスク粒度が細かいため、短いサイクルが合う

---

## 関連ドキュメント

- `doc/manual/commands_catalog.md` - タスク/バグ系コマンド
- `.claude/skills/task-*/SKILL.md` - タスク実行スキル
- `.claude/skills/bug-*/SKILL.md` - バグ対応スキル
