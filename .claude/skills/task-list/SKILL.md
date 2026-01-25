---
user-invocable: true
description: "[タスク実行] 1. TASKリストの生成"
---

# [タスク実行] 1. TASKリストの生成 (引数:doc/rdd.mdなどのコンテキストファイル)

## タスク全容: $ARGUMENTS

機能実装のための完全なタスクリストを **GitHub Issues + Milestone + Project** として生成します。
AIエージェントがスクラムで段階的な最小限の開発を繰り返せるよう、**Sprint = Milestone** でタスクを編成します。
本リストは **doc/rdd.md（要件・技術スタック・非機能要件）を唯一の根拠**として作成します。

## 共通前提（参照）
- 口調・出力規約・調査方針・TDD・Docコメント等は `CLAUDE.md` に従う。
- `doc/rdd.md` を読み、該当する `.claude/skills/*` を適用して判断軸を揃える（例: `architecture-expert` / `developer-specialist` / `security-expert`）。
- 詳細運用（サンプル運用/依存評価補助/ADR-lite）は `doc/ai_guidelines.md` を参照。

---

## GitHub連携の前提

### 必要な権限
以下の `gh` コマンドが実行可能であること：
- `gh issue create` / `gh issue list` / `gh issue view`
- `gh project item-add` / `gh project list`
- `gh api` （Milestone作成用）

### Milestone = Sprint
- Sprint 1 → Milestone `sprint-1`
- Sprint 2 → Milestone `sprint-2`
- 存在しない場合は `gh api` で作成する

### Project連携（任意）
- GitHub Projects が設定されている場合、作成したIssueを自動追加する
- Project番号は `gh project list` で確認

---

## RDD遵守・技術スタックガードレール
- **必須**: `doc/rdd.md` の以下を読み取り、各Issue本文に**参照セクション**を明記
  - 目標/非目標、対象ドメイン、**技術スタック**、非機能要件、制約
- **禁止**: RDDに記載のない新規スタックを無断採用すること
- **逸脱が必要な場合**: 「変更要求(ADR-lite)」テンプレでユーザー承認を得るまで着手禁止

---

## 調査プロセス
1. **コードベース分析**: 既存の類似機能/パターン/規約の確認（重複防止）
2. **RDD整合チェック**: RDDの目標/非目標・技術スタック・制約と照合
3. **ユーザー確認（必要時）**: 仕様の曖昧さや不足の解消。逸脱時は変更要求を提示。
4. **重複回避と可視化**
   - 既存コードの抽象化/共通化を優先
   - 各タスクには**決定理由/背景を1行**で残す
   - 難所は**最小サンプルで検証**（削除可と注記）

---

## タスクリスト生成の指針
- **Sprint = Milestone** 単位で目的/スコープ/タスクを記載
- 各タスク（Issue）に**検証ゲート**・**参照(RDD/コード/設計)** を明示
- **MVP優先**。見える成果を早期に届ける

---

## 出力手順

### 1. Milestone作成（Sprint単位）
```bash
# Milestone存在確認
gh api repos/{owner}/{repo}/milestones --jq '.[] | select(.title=="sprint-1")'

# 存在しなければ作成
gh api repos/{owner}/{repo}/milestones -f title="sprint-1" -f description="Sprint 1: {スプリント目的}"
```

### 2. Issue一括作成
```bash
gh issue create \
  --title "TASK-1: {タスク概要}" \
  --body "$(cat <<'EOF'
## 目的
{タスクの目的}

## RDD参照
- doc/rdd.md §{セクション}

## 検証ゲート
```bash
pnpm lint --fix && pnpm type-check
pnpm test
```

## 依存
- #XX（依存Issue番号）

## 決定理由
{なぜこのタスクが必要か}
EOF
)" \
  --milestone "sprint-1" \
  --label "task"
```

### 3. Project追加（設定されている場合）
```bash
# Project番号を取得
gh project list

# Issueを追加
gh project item-add {PROJECT_NUMBER} --owner {owner} --url {ISSUE_URL}
```

---

## 出力（GitHub）
- **Milestone**: `sprint-{n}` （Sprint単位）
- **Issues**: タスクごとに1 Issue（ラベル: `task`）
- **Project**: 設定されていれば自動追加

---

## 品質チェックリスト
- RDD/Architecture/Design の整合性
- 逸脱がある場合、**変更要求(ADR-lite)** を Issue本文に付与し承認待ちにしている
- 検証ゲートが**自動実行可能**
- 既存パターン参照（重複なし）
- **決定理由が明記されている**
- **依存関係が Issue番号で明示されている**
- Milestoneが正しく設定されている

---

## 自己評価
成功自信度 (1-10) ＋ 一言理由
