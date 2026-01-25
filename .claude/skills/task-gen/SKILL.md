---
user-invocable: true
description: "[タスク実行] 2. 指定sprintのTASK作成"
---

# [タスク実行] 2. 指定sprintのTASK作成 (引数:Milestone名, 作成スプリント)

## Milestone: $ARGUMENTS

指定されたMilestone（Sprint）のIssueに **詳細な実装コンテキスト** を追記します。
**必ず `doc/rdd.md` の技術スタック・制約に準拠**し、必要コンテキストをIssue本文に同梱してください。
逸脱が必要な場合は**変更要求(ADR-lite)** をIssue本文に挿入し、ユーザー承認後に着手します。

## 共通前提（参照）
- 口調・出力規約・調査方針・TDD・Docコメント等は `CLAUDE.md` に従う。
- `doc/rdd.md` を読み、該当する `.claude/skills/*` を適用して判断軸を揃える（例: `architecture-expert` / `developer-specialist` / `security-expert`）。
- 詳細運用（サンプル運用/依存評価補助/ADR-lite）は `doc/ai_guidelines.md` を参照。

---

## GitHub連携の前提

### 必要な権限
以下の `gh` コマンドが実行可能であること：
- `gh issue list` / `gh issue view` / `gh issue edit`
- `gh issue comment`

### 対象Issue取得
```bash
# Milestone配下のIssueを取得
gh issue list --milestone "sprint-1" --state open --json number,title,body
```

---

## 調査プロセス
1. **コードベース分析**
   - 類似機能/参照ファイル/命名規約/テスト雛形の抽出
   - **重複回避**を最優先し、既存拡張で解決できるか確認
2. **外部調査**
   - 公式Doc(URL)、GitHub実装例、StackOverflow（出典実在のみ）
3. **RDD整合チェック**
   - 技術スタック/制約/非機能要件の遵守を確認
   - **決定理由/背景**をIssue本文に記録
4. **ユーザー確認（必要時）**
   - 変更要求(ADR-lite) を提示→承認後にタスク確定

---

## Issue詳細化フォーマット

### Issue本文に追記する内容
```markdown
---
## 実装詳細（/task-gen で追記）

### 技術スタック(固定)
{RDD指定のスタック}

### 重要コンテキスト
- 公式Doc: {URL}
- 参照コード: {path/to/file}
- 規約: {命名規則等}
- 注意点: {ハマりポイント}

### 実装ブループリント（擬似コード）
```typescript
function example() {
  // ...
}
```

### 難所検証方針
- 最小サンプル（削除可）で {何を} 検証する

### サンプル運用
- 配置: `samples/` ディレクトリ（フレームワーク適合）
- 解決後に削除
- 機密禁止・ビルド/テスト/計測は除外

### 変更要求（必要時のみ）
> **ADR-lite**: {変更内容と理由}
> **承認状況**: 待ち / 承認済み
```

---

## 出力手順

### 1. 対象Issue一覧取得
```bash
gh issue list --milestone "sprint-1" --state open --json number,title
```

### 2. 各Issueの詳細化
```bash
# 現在の本文を取得
BODY=$(gh issue view {ISSUE_NUMBER} --json body --jq '.body')

# 詳細を追記してedit
gh issue edit {ISSUE_NUMBER} --body "${BODY}

---
## 実装詳細（/task-gen で追記）
...
"
```

### 3. ラベル追加（オプション）
```bash
gh issue edit {ISSUE_NUMBER} --add-label "ready-for-dev"
```

### 4. 進捗コメント
```bash
gh issue comment {ISSUE_NUMBER} --body "/task-gen 完了: 実装詳細を追記しました"
```

---

## 出力（GitHub）
- **Issue本文**: 実装詳細セクションを追記
- **ラベル**: `ready-for-dev` を追加（オプション）
- **コメント**: 詳細化完了の記録

---

## 品質チェックリスト
- RDD/Architecture/Design 準拠
- 重複回避が明記されている
- 参照URL・コードスニペットが**実在**
- 検証ゲートが**実行可能**
- 実装パス（擬似コード/手順）が明確
- エラーハンドリング/ロールバック記述
- 変更要求がある場合は**承認待ち**を明記
- 最小サンプル検証の計画がある
- サンプル運用（配置はフレームワーク適合・命名・削除・機密・除外）がIssueに明記されている

---

## 自己評価
成功自信度 (1-10) と一言理由
