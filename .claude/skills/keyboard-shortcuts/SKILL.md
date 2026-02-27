---
name: keyboard-shortcuts
category: role
user-invocable: false
description: UIキーボードショートカットを「公式基準（W3C APG / WCAG）＋プラットフォーム規約（Apple HIG / Fluent UI）＋デファクトスタンダード（GitHub・Gmail・Slack等）」に沿って設計し、衝突なく・発見しやすく・無効化可能な形で実装するための判断軸。
---

# Keyboard Shortcuts Skill

## 発火条件（適用タイミング）
- 依頼が「キーボードショートカット」「キーバインド」「ホットキー」「ショートカットキー」「キーボードナビゲーション」なら適用する。
- UI実装（`/design-ui` / `/design-assemble` / フロント実装）でインタラクティブ要素を扱うとき、必要に応じて併用する。
- `accessibility-engineer` skill と組み合わせて使うことが多い（キーボード操作全般はそちらが基本、このskillはショートカット設計に特化）。

## このSkillの基本方針（整理軸）
- **公式基準ファースト**: W3C APG のキーボードパターンと WCAG 2.1/2.2 の成功基準を最上位の根拠とする。
- **プラットフォーム規約の尊重**: OS予約キー（macOS: ⌘+Space, ⌘+Tab 等 / Windows: Win+L 等）やブラウザ標準キー（Ctrl+T, Ctrl+W 等）を奪わない。
- **デファクトの活用**: GitHub・Gmail・Slack・X 等で広く定着したパターン（`?` でヘルプ、`/` で検索、`j`/`k` でリスト移動等）を文脈に応じて採用し、ユーザーの学習コストを下げる。
- **発見可能性と無効化**: ショートカットは隠れ機能ではない。一覧表示（`?`）・ツールチップ・無効化/リマップ手段を必ず提供する。

## 思想（判断ルール）

### 1) 公式基準への準拠（WCAG / APG）
- **WCAG 2.1.1 (A)**: すべての機能がキーボードで操作可能であること。ショートカットは利便性の追加であり、ショートカットなしでも機能が使えることが前提。
- **WCAG 2.1.2 (A)**: キーボードトラップを作らない。モーダル内のフォーカストラップは例外だが、`Escape` で必ず脱出可能にする。
- **WCAG 2.1.4 (A)**: **単独文字キー**（修飾キーなし）のショートカットには、以下のいずれかを提供する:
  1. 無効化する仕組み
  2. 修飾キー付きにリマップする仕組み
  3. コンポーネントがフォーカスを持つ時のみ有効にする
- **WCAG 2.4.7 (AA)**: フォーカスインジケーターを常に可視にする。ショートカットでフォーカス移動した先も同様。
- **参照**: [WAI-ARIA APG Keyboard Interface](https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/) / [APG Patterns](https://www.w3.org/WAI/ARIA/apg/patterns/)

### 2) 複合ウィジェットのキーボードパターン（APG準拠）
以下はAPGが定めるウィジェット別の標準キー割り当て。独自実装せず、このパターンに従う。

| ウィジェット | 内部移動 | 主要キー |
|-------------|---------|---------|
| Tabs | 左右矢印（水平）/ 上下矢印（垂直） | Home, End, Delete（閉じる） |
| Menu / Menubar | 上下矢印（縦）/ 左右矢印（横） | Enter/Space（実行）, Escape（閉じる） |
| Listbox | 上下矢印 | Home, End, Type-ahead |
| Grid | 上下左右矢印 | PageUp/Down, Ctrl+Home/End |
| Tree View | 上下矢印, 左（折畳）, 右（展開） | Enter（実行）, `*`（全展開） |
| Dialog (Modal) | Tab（内部循環） | Escape（閉じる）, フォーカストラップ必須 |
| Combobox | 上下矢印（ポップアップ内） | Escape（閉じる）, Enter（選択） |
| Radio Group | 上下/左右矢印 | Space（選択） |
| Toolbar | 左右矢印 | Home, End |

- **フォーカス管理**: Roving Tabindex（フォーカス中 `tabindex="0"` / 他 `tabindex="-1"`）または `aria-activedescendant` を使い分ける。

### 3) プラットフォーム規約（衝突回避）

#### 修飾キーのクロスプラットフォーム対応
| 機能 | macOS | Windows / Linux |
|------|-------|-----------------|
| アプリコマンド | `⌘ Cmd` | `Ctrl` |
| 代替操作 | `⌥ Option` | `Alt` |
| 逆方向/拡張 | `⇧ Shift` | `Shift` |

#### 予約済みキー（絶対に奪わない）
- **macOS**: `⌘+Space`（Spotlight）, `⌘+Tab`（アプリ切替）, `⌘+Q`（終了）, `⌘+H`（隠す）, `⌘+M`（最小化）, `Ctrl+F1`/`Ctrl+F7`（キーボードアクセス）
- **Windows**: `Win+L`（ロック）, `Alt+Tab`（切替）, `Alt+F4`（終了）, `Ctrl+Alt+Del`
- **ブラウザ共通**: `Ctrl/⌘+T`（新規タブ）, `Ctrl/⌘+W`（タブを閉じる）, `Ctrl/⌘+L`（アドレスバー）, `F5/⌘+R`（更新）, `Ctrl/⌘+F`（ページ内検索）
- **支援技術**: CapsLock / Insert（スクリーンリーダの修飾キーとして使用）は避ける
- **参照**: [Apple HIG - Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards) / [macOS ショートカット一覧](https://support.apple.com/en-us/102650)

### 4) デファクトスタンダード（業界共通パターン）
主要サービス（GitHub / Gmail / Slack / X / Notion / VS Code）で共通して定着しているパターン。文脈が合えば積極的に採用する。

#### グローバルショートカット（ページ全体）
| キー | 機能 | 採用例 |
|------|------|--------|
| `?` | ショートカットヘルプ一覧を表示 | GitHub, Gmail, X |
| `/` | 検索バーにフォーカス | GitHub, X, YouTube |
| `Escape` | モーダル/ポップアップ/ドロワーを閉じる | 全サービス共通 |
| `⌘/Ctrl+K` | コマンドパレット / クイックスイッチャー | GitHub, Slack, VS Code, Linear |

#### リスト/フィード操作（vim風）
| キー | 機能 | 採用例 |
|------|------|--------|
| `j` | 次の項目へ移動 | Gmail, X, GitHub |
| `k` | 前の項目へ移動 | Gmail, X, GitHub |
| `o` / `Enter` | 選択した項目を開く | Gmail, X |
| `x` | 項目を選択/チェック | Gmail |

#### ページナビゲーション（シーケンシャルキー）
| キー | 機能 | 採用例 |
|------|------|--------|
| `g` → `h` | ホームへ移動 | X |
| `g` → `i` | Inbox / Issues へ移動 | Gmail, GitHub |
| `g` → `n` | 通知へ移動 | X |
| `g` → `p` | プロフィール / Pull Requests へ移動 | X, GitHub |

#### アクション
| キー | 機能 | 採用例 |
|------|------|--------|
| `n` / `c` | 新規作成（ポスト / メール / Issue） | X (`n`), Gmail (`c`) |
| `r` | 返信 | X, Gmail |
| `l` / `s` | いいね / スター | X (`l`), Gmail (`s`) |

### 5) 実装時の原則
- **KeyboardEvent.key を使う**: `keyCode`（非推奨）ではなく `event.key` で判定する。物理配置が重要な場合（ゲーム等）は `event.code` を使い分ける。参照: [W3C UI Events KeyboardEvent key Values](https://www.w3.org/TR/uievents-key/)
- **修飾キーの正規化**: macOS の `⌘` と Windows の `Ctrl` を同一機能にマッピングする（`event.metaKey || event.ctrlKey`）。
- **シーケンシャルキー**: `g` → `i` のような2打鍵は、タイムアウト（500〜1000ms）を設け、中間状態を視覚的にフィードバックする。
- **入力フィールドとの競合回避**: `<input>`, `<textarea>`, `[contenteditable]` にフォーカスがある時はグローバルショートカットを無効化する。
- **カスタマイズ対応**: ユーザーがショートカットを無効化・リマップできるUIまたは設定を提供する（WCAG 2.1.4 対応）。

## 進め方（最初に確認する問い）
1. このUIのどの機能にショートカットを割り当てる？（全機能にショートカットは不要。頻度の高い操作を優先）
2. ターゲットプラットフォームは？（Web / macOS / Windows / クロスプラットフォーム）
3. リスト/フィード型のUI要素はある？（`j`/`k` パターンの適用判断）
4. コマンドパレットは実装する？（`⌘/Ctrl+K` パターン）
5. 既存のショートカットフレームワーク/ライブラリの有無は？（tinykeys, hotkeys-js, Mousetrap 等）

## 出力フォーマット（実装時）
1. **ショートカット一覧表**: 機能 / キー / 文脈（グローバル or フォーカス内） / 参照元（APG / デファクト / カスタム）
2. **衝突チェック**: OS予約 / ブラウザ標準 / 支援技術との衝突がないか
3. **WCAG 2.1.4 対応**: 単独文字キーの無効化/リマップ/フォーカス限定の方針
4. **フォーカス管理**: ショートカット発動後のフォーカス移動先の定義
5. **発見可能性**: `?` ヘルプ / ツールチップ / ドキュメントの提供方針
6. **実装方針**: イベントハンドリング・ライブラリ選定・テスト計画

## チェックリスト
### 基本要件（WCAG準拠）
- [ ] すべてのインタラクティブ要素がキーボードで操作可能（2.1.1）
- [ ] キーボードトラップが存在しない（2.1.2）
- [ ] 単独文字キーショートカットに無効化/リマップ/フォーカス限定を提供（2.1.4）
- [ ] フォーカスインジケーターが可視（2.4.7）
- [ ] フォーカスが他要素に遮蔽されない（2.4.11）

### 衝突回避
- [ ] OS予約キー（⌘+Space, Win+L 等）と衝突しない
- [ ] ブラウザ標準キー（⌘+T, ⌘+W, ⌘+F 等）と衝突しない
- [ ] 支援技術の修飾キー（CapsLock, Insert）を使用していない
- [ ] テキスト入力中にグローバルショートカットが誤発動しない

### デファクト準拠
- [ ] リスト/フィード操作に `j`/`k` パターンを採用しているか検討した
- [ ] 検索フォーカスに `/` パターンを採用しているか検討した
- [ ] ショートカットヘルプ表示（`?`）を提供した
- [ ] `Escape` でモーダル/ポップアップが閉じる

### 実装品質
- [ ] `event.key` を使用している（`keyCode` 非推奨）
- [ ] macOS / Windows のクロスプラットフォーム対応をした
- [ ] シーケンシャルキーにタイムアウトとフィードバックがある
- [ ] ショートカット一覧が文書化されている

## よくある落とし穴
- **OS/ブラウザ予約キーの上書き** — ユーザーの基本操作を壊す。事前に衝突テーブルを確認する。
- **入力フィールド内での誤発動** — `<input>` / `<textarea>` にフォーカスがあるのに `j`/`k` が発動してリスト移動する。フォーカス対象の判定を怠らない。
- **WCAG 2.1.4 違反** — `j`/`k`/`n` 等の単独文字キーを実装して無効化手段を提供しない。音声入力ユーザーのディクテーション中に誤発動する。
- **フォーカス移動先の未定義** — ショートカットで画面遷移した後、フォーカスがページ先頭に戻る。移動先を明示的に設計する。
- **ショートカットの過剰割り当て** — すべての機能にキーを割り当てようとして、覚えきれない・衝突する。頻度の高い操作10〜20個に絞る。
- **修飾キーの不統一** — macOS で `⌘+K`、同じ機能を Windows で `Alt+K` にする等、プラットフォーム間で対応がバラバラ。`⌘` ↔ `Ctrl` の対応を守る。
- **プラットフォーム検出の誤り** — `navigator.platform`（非推奨）に依存する。`navigator.userAgentData` や feature detection を使う。
- **`keyCode` / `which` の使用** — 非推奨でロケール依存の問題がある。`event.key` を使う。

## 短問テンプレ（不足情報を推測しない）
- このアプリのメインの操作パターンは？（リスト閲覧 / エディタ / ダッシュボード / フォーム中心）
- ターゲットプラットフォームは？（Web専用 / Electron / PWA / ネイティブアプリ）
- 既存のキーボードショートカットがあるか？（あればリストを提示してもらう）
- ユーザーがショートカットをカスタマイズできる必要はあるか？

## 参照ドキュメント
### 公式基準
- [W3C WAI-ARIA Authoring Practices Guide (APG)](https://www.w3.org/WAI/ARIA/apg/)
- [APG - Developing a Keyboard Interface](https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/)
- [WCAG 2.1 - 2.1.4 Character Key Shortcuts](https://www.w3.org/WAI/WCAG21/Understanding/character-key-shortcuts.html)
- [W3C UI Events KeyboardEvent key Values](https://www.w3.org/TR/uievents-key/)
- [Apple HIG - Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards)
- [macOS Keyboard Shortcuts](https://support.apple.com/en-us/102650)
- [Windows Keyboard Accessibility](https://learn.microsoft.com/en-us/windows/apps/design/accessibility/keyboard-accessibility)

### デファクト参照
- [GitHub Keyboard Shortcuts](https://docs.github.com/en/get-started/accessibility/keyboard-shortcuts)
- [Gmail Keyboard Shortcuts](https://support.google.com/mail/answer/6594)
- [Slack Keyboard Shortcuts](https://slack.com/help/articles/201374536-Slack-keyboard-shortcuts)
- [VS Code Keybindings](https://code.visualstudio.com/docs/configure/keybindings)
