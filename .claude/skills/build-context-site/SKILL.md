---
user-invocable: true
description: "doc/input（確定）+ doc/draft（未合意）+ doc/generated + meta/adr-lite + history の最新を統合し、ローカル閲覧用の HTML サイト（要件・設計・ADR・図を横断）を生成する。確定と発酵中を状態バッジで区別して並べる。「ここ見れば全コンテキスト分かる」プロジェクト現状サイト。"
---

# [ループ] 全コンテキスト HTML サイト `/build-context-site`

> プロジェクトの**全ドキュメントを横断**できるローカル HTML サイトを生成する。要件・設計・ADR・履歴をブラウザ1つで把握できる場を作る。
>
> 設計根拠: `meta/adr-lite.md` の **ADR-008 / ADR-011 / ADR-013**

## 入力: $ARGUMENTS
- 省略時: 既定の対象範囲（後述）で全部生成
- 範囲指定する場合: `design` / `requirements` / `adr` / `all` のいずれか

---

## 🎯 目的
- 散在する Markdown ドキュメント（`doc/input/*`, `doc/generated/*`, `meta/adr-lite.md`）を**一画面で横断できる HTML サイト**にする
- 図（drawio / mermaid）を**埋め込み**で構造を可視化
- 引き継ぎ・確認コストを下げる（人間も AI も同じサイトを参照可能）
- ローカルサーバで閲覧（外部公開はしない）

---

## 前提（必ず確認）

- `reviewable-html-workbench` プラグインが install 済みであること
  - 未 install の場合は手動でユーザーへ案内（後述）
- 対象ドキュメントが存在すること（空なら警告して生成スキップ）
- 出力先 `doc/generated/context-site/` の書き込み権限

### reviewable-html-workbench の install 確認

```bash
claude plugin list | grep -i reviewable-html-workbench || echo "未install"
```

未 install の場合、以下をユーザーへ案内して中断:

```
reviewable-html-workbench プラグインが必要です。以下を実行してください:

claude plugin marketplace add u-ichi/reviewable-html-workbench
claude plugin install reviewable-html-workbench

install 後に /build-context-site を再実行してください。
```

---

## 対象ドキュメント

### 既定（`all` または引数省略時）
| カテゴリ | パス | 状態 | 用途 |
|---|---|---|---|
| 要件 | `doc/input/rdd.md`, `doc/input/*.md` | ✅ 確定 | プロジェクトのRDD・追加要件 |
| デザイン | `doc/input/design/**/*.md`, `doc/input/design/**/*.json` | ✅ 確定 | デザイン SSOT・モック |
| **発酵中** | `doc/draft/**/*.md` | 🧪 **未合意** | プロトの学び・設定集・検討中の案 |
| 生成物 | `doc/generated/**/*.md` | — | マニュアル・自動生成ドキュメント |
| ADR | `meta/adr-lite.md` | ✅ 確定 | 設計決定ログ |
| 履歴（任意） | `history/journal.md` の最新7日分 | — | ローカル閲覧用、配布物には含まない |

> ⚠️ **状態はサイト上で必ず見えるようにする**（次節）。
> 確定と未合意が並列に見えると、閲覧者が未合意のものを決定事項として読む。
> ディレクトリを分けた意味が画面で消える。

### 引数による絞り込み
- `requirements`: 要件のみ
- `design`: デザインのみ
- `adr`: ADR のみ
- `all`: 全部（既定）

---

## 実行手順

### 1. 対象ドキュメントの収集

```bash
# 例: all の場合（draft も収集するが、状態を分けて保持する）
find doc/input doc/generated -type f \( -name "*.md" -o -name "*.json" \) 2>/dev/null
find doc/draft -type f -name "*.md" 2>/dev/null   # ← 未合意として別扱い
cat meta/adr-lite.md
# history は最新7日分のみ
```

### 2. 図の埋め込み準備（MCP）

ドキュメント中に以下のパターンがあれば、対応する MCP を呼び出して図を生成:

- **mermaid コードブロック** ` ```mermaid ... ``` `
  - そのままレンダリング可能（reviewable-html-workbench 側の `visual-html-renderer` が対応）
- **drawio リファレンス** `<!-- drawio:path/to/file.drawio -->`
  - MCP の drawio ツール（`mcp__drawio__open_drawio_xml`）で XML をレンダリング
- **構造説明テキスト**（システム構成・データフロー等）
  - 必要なら mermaid を新規生成して埋め込む（既存ドキュメントは改変しない、サイト側の overlay として）

> ⚠️ **既存ドキュメントは絶対に書き換えない**。サイト生成時の overlay として図を足すだけ。

### 3. HTML 生成（reviewable-html-workbench の `render`）

```bash
# サイトのモデル定義（reviewable-html-workbench の build-model）
# 詳細は plugin の skill (reviewable-design-doc / visual-html-renderer) の指示に従う

python3 -m scripts.html_review_workbench.cli build-model \
  --input-dir doc/ \
  --input-file meta/adr-lite.md \
  --output doc/generated/context-site/model.json

python3 -m scripts.html_review_workbench.cli render \
  --model doc/generated/context-site/model.json \
  --output-dir doc/generated/context-site/ \
  --title "<プロジェクト名> プロジェクト全コンテキスト"
```

> 実際のコマンド名・引数は reviewable-html-workbench の最新版に合わせる。バージョン不整合時はプラグインの README を参照。

### 4. ナビゲーション生成

`doc/generated/context-site/index.html` を起点に、**確定と発酵中を分けた**構造にする:

```
✅ 確定（合意済み・前提にしてよい）
   📋 要件（rdd.md, 追加要件）
   🎨 デザイン（SSOT, モック）
   🏗 ADR（設計決定の歴史）

🧪 発酵中（未合意・参考）      ← doc/draft/
   検討中の案・プロトの学び・設定集

📚 生成物（マニュアル等）
📔 履歴（journal の最新分、ローカル閲覧時のみ）
```

**必須の表示ルール**:
- `doc/draft/` 由来のページには、**ページ上部に「未合意」バッジ**を出す
  （例: `🧪 未合意 — 参考。決定事項ではありません`）
- 確定側のバッジ（`✅ 合意済み`）も出し、**どちらか分からない状態を作らない**
- トップの一覧でも、行ごとに状態が分かるようにする
- 昇格候補の印が付いているものは `⬆️ 昇格候補` として区別する（人間が決める対象）

### 5. プレビューサーバ起動

```bash
# reviewable-html-workbench のプレビュー機能
python3 -m scripts.html_review_workbench.cli preview \
  --dir doc/generated/context-site/

# または簡易サーバ（フォールバック）
cd doc/generated/context-site/ && python3 -m http.server 8765
```

起動 URL をユーザーへ案内する。このとき、本文の最後に**次の形式の1行を必ず出力する**:

```
コンテキストサイト: http://localhost:8765/
```

> CLI のフッターがこの形式を拾ってリンクバッジを出す（`~/.claude/settings.json` の `footerLinksRegexes`）。
> 形式が崩れると拾われないので、**ラベルとコロンの後に半角スペース1つ**を守る。
> レポート一覧（`レポート一覧: <URL>`）と同じ仕組み。

### 6. インライン コメント機能の案内

`reviewable-html-workbench` のコメント機能が使える場合、ユーザーへ案内:

```
ブラウザでドキュメントを開いて、気になる箇所にコメントを付けられます。
コメントは JSON に保存され、AI が次回 /build-context-site --ingest-review で取り込めます。
```

---

## 出力先

```
doc/generated/context-site/
├── index.html               ← トップページ
├── model.json               ← reviewable-html-workbench のモデル
├── pages/                   ← 各ドキュメントの HTML
│   ├── requirements/
│   ├── design/
│   ├── adr/
│   └── generated/
├── assets/                  ← 図・画像
└── comments/                ← ユーザーコメントの蓄積（あれば）
```

> ⚠️ `doc/generated/context-site/` は配布物に含めない方針が筋（毎回生成される一時成果物）。`.gitignore` への追加を推奨

---

## 課金前停止ポイント

このスキルは**ローカル処理のみ**なので、課金発生ポイントは無い（外部 API を叩かない）。
MCP 経由の drawio / mermaid もローカルレンダリング。

---

## やってはいけない

- 既存 `doc/input/*` や `meta/adr-lite.md` を**書き換える**（サイト生成は read-only）
- `history/journal.md` を**配布物として含める**（gitignore 配下のローカル閲覧用に留める）
- 生成サイトを**外部公開**する（個人情報・契約情報が含まれる可能性、ローカルのみ）
- ⚠️ **確定（`doc/input/`）と発酵中（`doc/draft/`）を、状態表示なしに並べる**。
  分けた意味が画面で消え、未合意のものが決定事項として読まれる（ADR-026）
- reviewable-html-workbench 未 install のまま強行（手動 install を案内）

---

## `/auto-task` `/auto-bug` との関係

- `/auto-task` `/auto-bug` の成果（PR、思考プロセス、レビュー履歴）は別途 `reviewable-html-workbench` の `render` で `doc/generated/loop-reports/` に出力される（ADR-013）
- `/build-context-site` は**プロジェクト全体の現状**を見るためのサイト
- 両者は独立したコマンドだが、内部で同じ `reviewable-html-workbench` を使う

---

## 自己評価
- **成功自信度**: (1-10)
- **一言理由**: {対象ドキュメントの網羅度、図のレンダリング成否、ナビの分かりやすさを踏まえて記載}
