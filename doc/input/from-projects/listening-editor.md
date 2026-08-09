# listening-editor からの送り状

- **出典リポジトリ**: `/Users/mae/output/listening-editor-workspace`
- **公開リポジトリ**: https://github.com/mae616/listening-editor （private。プラグイン本体 `listening-editor/` のみ）
- **記録日**: 2026-07-29

> 注意: 下記「解決済みファイル」のうち `.claude/hooks/` と `doc/` はワークスペース直下にあり、
> **公開リポジトリには含まれていない**（Git 管理外）。取り込み時はローカルパスから読むこと。

---

## 項目1: ガード系フックは「AIが打つコマンド形」で検証し、fail-closed にする

- **種別**: 既存の仕組みの修正（hook）＋ rules追記
- **反映先候補**: `.claude/hooks/git-branch-guard.sh`（修正本体）/ `.claude/rules/tool-usage.md`（原則）
- **出典リポジトリ**: `/Users/mae/output/listening-editor-workspace`
- **解決済みファイル**: `/Users/mae/output/listening-editor-workspace/.claude/hooks/git-branch-guard.sh`
- **状態**: 未取込

### 何が起きていたか

`main` への直接 commit/push をブロックするはずのフックが、**黙って素通り**していた。
ガードが効いていないのに「守られている」と誤認する種類の不具合。
原因は独立して3つあり、実測で切り分けた。**最初の修正は1つしか直せておらずテストで落ちた。**

**原因A（主因）: `git` とサブコマンドの隣接を前提にした正規表現**

```
git commit -m x            → match
git -C <path> commit -m x  → NO-MATCH   ← 入口で exit 0 し、以降の判定に到達しない
```

人間は `cd` してから `git commit` するが、**AIは作業ディレクトリを移動せずに済む
`git -C <path>` を好む**。人間の手癖を前提にしたパターンは、AI相手では抜ける。
同じ書き方が push の refspec チェックにも**もう1箇所**あった。

**原因B: `rev-parse --abbrev-ref HEAD` はコミット0件のリポジトリで文字列 `HEAD` を返す**

`HEAD` は `main` と一致しないため、**初回コミットの瞬間だけガードが無効**になる。
「リポジトリを作って最初のコミットを積む」という最も起こりがちな場面で穴が開く。
`git branch --show-current` なら同じ状況でも `main` を返す。

**原因C: フックは実行「前」に走るため cwd が当てにならない**

`git -C <path>` と `cd <path> &&` は、対象リポジトリが cwd と異なる。
コマンド文字列からパスを抽出し、そのパス基準で判定する必要がある。

**あわせて fail-closed 化**: ブランチを特定できないとき、修正前は素通りしていた。
ガードの目的からすると、判定不能は「止める」が正しい。

### 汎用化した形（テンプレートに置く原則）

1. ガード系フックの正規表現は、**AIが実際に打つコマンド形**で検証する
2. ガード系フックは **fail-closed**。判定不能で通す実装は「守られている」誤認を生み、穴より悪い
3. フックは書いて終わりにせず、**通す/止める両方**を実測する
4. 同じ欠陥パターンは**ファイル内に複数ある前提**で探す

### 検証スニペット

リポジトリを汚さずフック単体を叩ける。テンプレートに同梱すると再利用が効く。

```bash
t(){ CLAUDE_TOOL_ARG_COMMAND="$2" bash .claude/hooks/git-branch-guard.sh >/dev/null 2>&1; a=$?
     [ "$a" = "$3" ] && echo "  PASS  $1" || echo "  FAIL  $1 (期待=$3 実際=$a)"; }
t "git以外"         'ls -la'                              0
t "-C で sprint"    'git -C <repo> commit -m x'           0
t "cd で sprint"    'cd <repo> && git commit -m x'        0
t "-C で main"      'git -C <main-repo> commit -m x'      2
t "cd で main"      'cd <main-repo> && git commit -m x'   2
t "main へ refspec" 'git -C <repo> push origin HEAD:main' 2
t "判定不能"        'git commit -m x'                     2   # Git管理外の cwd から
```

出典セッションでは、この形で11ケース検証して全PASSを確認した。

---

## 項目2: プラグインが依存する外部MCPは同梱せず、READMEで開示して各自導入にする

- **種別**: rules追記（配布・依存の方針）
- **反映先候補**: `.claude/rules/code-quality.md`（依存評価の補助基準に追記）
- **出典リポジトリ**: `/Users/mae/output/listening-editor-workspace`
- **解決済みファイル**: `/Users/mae/output/listening-editor-workspace/listening-editor/README.md`
  （「使っている外部コンポーネント」「X の投稿を読む場合」の各節）
- **状態**: 未取込

### 何が問題か

プラグインが外部 MCP に依存するとき、`.mcp.json` に同梱すると
**利用者が既に同じ MCP を設定していた場合に二重登録**になり、ツールが重複して動作が不安定になる。
実際にこのケースが起きた（利用者の `~/.claude.json` に同じ MCP が既に存在していた）。

### 汎用化した形

- 外部 MCP は**同梱・再配布しない**。利用者の環境で起動されるものとして扱う
- README に「使っている外部コンポーネント」の表を置き、**提供元・用途・同梱の有無**を明示する
- **なぜ同梱しないか**の理由も書く（公式配布物を抱え込まない／利用者環境の二重登録を避ける）
- 依存が無くても動く経路を用意し、README に書く
- ライセンスを確認していない依存は**推測で書かず**、「各リポジトリの記載に従う」に留める

非公式プラグインが公式コンポーネントを利用する場合、この開示の有無で受け取られ方が変わる。
同梱していないことを明記すると、ライセンス上の位置づけも明確になる。
