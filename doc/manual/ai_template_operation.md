# ai-template 運用ガイド（開発前反映〜更新）

このドキュメントは、`ai-template` を各開発リポジトリへ **安全に導入・更新**するための手順をまとめます。

## 0. 前提（守ること）
- 反映は必ず **dry-run → 実反映** の順で行う。
- `doc/rdd.md` は原則 **プロジェクト固有**。テンプレ更新で上書きしない（必要なら明示フラグ）。
- 迷ったら `/setup` を実行し、`CLAUDE.md` → `doc/rdd.md` → `.claude/skills` の順で前提を揃える。

## 1. 初回導入（新しい開発リポジトリ）
```bash
cd /path/to/ai-template
scripts/apply_template.sh --target /abs/path/to/your-project --safe --dry-run
scripts/apply_template.sh --target /abs/path/to/your-project --safe
```

## 2. テンプレ更新の反映（既存リポジトリへ）
まずは **上書きしてよい領域**（`CLAUDE.md` / `AGENTS.md` / `.claude/` / `doc/ai_guidelines.md`）だけ更新する。

```bash
cd /path/to/ai-template
scripts/apply_template.sh --target /abs/path/to/your-project --force --dry-run
scripts/apply_template.sh --target /abs/path/to/your-project --force
```

### `doc/rdd.md` を上書きしたい場合（非推奨）
```bash
scripts/apply_template.sh --target /abs/path/to/your-project --force --overwrite-rdd --dry-run
scripts/apply_template.sh --target /abs/path/to/your-project --force --overwrite-rdd
```

### `--sync` について（危険）
`--sync` はテンプレ対象ディレクトリで **削除を伴う同期**を行う。通常は `--force` で十分。

## 3. 失敗したときの復旧（バックアップ）
反映時に `your-project/.ai-template-backup/<timestamp>/` が作成される。復旧は対象ファイルを戻す。

例（単一ファイルを戻す）:
```bash
cd /abs/path/to/your-project
ls .ai-template-backup/
# 最新のtimestampを選んで、必要なファイルを戻す（例: CLAUDE.md）
cp .ai-template-backup/<timestamp>/CLAUDE.md ./CLAUDE.md
```

例（複数ファイルを rsync でまとめて戻す）:
```bash
cd /abs/path/to/your-project
ts="<timestamp>"

# まずはdry-runで確認
rsync -av --dry-run ".ai-template-backup/$ts/CLAUDE.md" "./CLAUDE.md"
rsync -av --dry-run ".ai-template-backup/$ts/AGENTS.md" "./AGENTS.md"
rsync -av --dry-run ".ai-template-backup/$ts/.claude/" "./.claude/"
rsync -av --dry-run ".ai-template-backup/$ts/doc/ai_guidelines.md" "./doc/ai_guidelines.md"

# 問題なければ実行
rsync -av ".ai-template-backup/$ts/CLAUDE.md" "./CLAUDE.md"
rsync -av ".ai-template-backup/$ts/AGENTS.md" "./AGENTS.md"
rsync -av ".ai-template-backup/$ts/.claude/" "./.claude/"
rsync -av ".ai-template-backup/$ts/doc/ai_guidelines.md" "./doc/ai_guidelines.md"
```

## 4. グローバル適用（~/.claude への反映）

判断軸スキル（`user-invocable: false`）やグローバル設定を `~/.claude` に適用する。

```bash
cd /path/to/ai-template

# dry-run で確認
scripts/apply_global.sh --dry-run

# 実行
scripts/apply_global.sh
```

### 適用対象
| 対象 | 説明 |
|------|------|
| `~/.claude/skills/` | スキル（デフォルト: 判断軸のみ、`--all-skills`: 全て） |
| `~/.claude/settings.local.json` | permissions のマージ（追加のみ） |
| `~/.claude/CLAUDE.md` | グローバル設定（全プロジェクト共通） |

### オプション
- `--all-skills` : 全スキルを適用（手順系含む）
- `--skip-skills` : スキルの適用をスキップ
- `--skip-settings` : settings.local.json の適用をスキップ
- `--skip-claude-md` : CLAUDE.md の適用をスキップ
- `--no-backup` : バックアップを作成しない（非推奨）

### 注意
- デフォルトは **判断軸スキル**（`user-invocable: false`）のみ
- `--all-skills` で **手順系スキル**（`user-invocable: true`）も含む
- 適用後は **Claude Code を再起動** してスキルを反映

---

## 5. どこを編集するか（カスタマイズの指針）
- 不変の憲法: `CLAUDE.md`
- 事実（プロジェクト固有）: `doc/rdd.md`（先頭の「AI用：事実ブロック」を更新）
- 思考モジュール: `.claude/skills/*/SKILL.md`
- 詳細運用: `doc/ai_guidelines.md`

