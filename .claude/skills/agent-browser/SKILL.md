---
name: agent-browser
category: tech
user-invocable: false
description: Agent Browser（Headlessブラウザ自動化CLI）を使ったUI検証・E2Eテスト・スクリーンショット取得の判断軸。アクセシビリティツリーベースの要素選択を優先し、壊れにくいテスト設計を目指す。
---

# Agent Browser Skill

## 参照（公式）
- [GitHub](https://github.com/vercel-labs/agent-browser)
- インストール: `npm install -g agent-browser && agent-browser install`

## 発火条件
- `doc/input/rdd.md` に `Agent Browser` や `E2Eテスト` `UI検証` が記載されている場合、このSkillの方針をデフォルト採用する。
- 記載がなくても、ユーザーの依頼がブラウザ自動化/UI確認/スクリーンショット比較/E2Eテストに該当するなら適用する。

## このSkillの基本方針
- 基本方針: AIエージェント向けHeadlessブラウザCLI。UI検証・E2Eテスト・視覚的確認に使う。
- 要素選択: アクセシビリティツリー（`@e1` 等）やセマンティックロケータ（role/label）を優先。CSSセレクタは最終手段。
- テスト設計: 壊れにくいテストを書く。実装詳細（class名/id）に依存しない。
- パフォーマンス: グローバルインストール（`npm i -g`）を推奨。`npx` 経由はNode.jsフォールバックで遅い。

## 思想（判断ルール）
1. **アクセシビリティファースト**: 要素はrole/label/textで特定する。CSSセレクタ依存はリファクタに弱い。
2. **最小スコープ**: テストはユーザー操作単位で小さく。ページ全体の網羅より重要フローの確認を優先。
3. **スクリーンショットは証拠**: 視覚的な確認が必要な場面では積極的に撮る。差分検証でリグレッションを防ぐ。
4. **待機は明示的に**: 暗黙の `sleep` を避け、要素の出現/状態変化を待つ。

## 主要コマンド（よく使うもの）

### ページ操作
```bash
agent-browser open <url>              # ページを開く
agent-browser goto <url>              # 別URLへ遷移
agent-browser screenshot [file]       # スクリーンショット取得
agent-browser pdf [file]              # PDF保存
```

### 要素操作
```bash
agent-browser click <selector>        # クリック
agent-browser fill <selector> <text>  # 入力欄にテキスト入力
agent-browser press <key>             # キー押下（Enter等）
agent-browser scroll <direction>      # スクロール
```

### 要素選択の優先順位
```bash
# 1. セマンティックロケータ（推奨）
agent-browser click "role=button[name='Submit']"
agent-browser fill "role=textbox[name='Email']" "test@example.com"

# 2. アクセシビリティツリー参照
agent-browser click @e1               # ツリー上のID

# 3. テキストマッチ
agent-browser click "text=ログイン"

# 4. CSSセレクタ（最終手段）
agent-browser click "#submit-btn"
```

### 情報取得
```bash
agent-browser text [selector]         # テキスト取得
agent-browser title                   # ページタイトル
agent-browser url                     # 現在のURL
agent-browser count <selector>        # 要素数
```

### デバイス・環境設定
```bash
agent-browser --viewport 375x812      # モバイルビューポート
agent-browser --device "iPhone 15"    # デバイスエミュレーション
agent-browser --color-scheme dark     # ダークモード
```

## 出力フォーマット（必ずこの順）
1. 推奨方針（1〜3行）
2. 理由（テスト安定性 / 保守性 / ユーザー視点）
3. 設計案（テスト対象フロー / 要素選択戦略 / スクリーンショット計画 / 環境設定）
4. チェックリスト（実装前に確認）
5. 落とし穴（避けるべき）
6. 次アクション（小さく試す順）

## チェックリスト
- [ ] `agent-browser` がグローバルインストール済みか（`agent-browser --version`）
- [ ] Chromiumがインストール済みか（`agent-browser install`）
- [ ] 要素選択はアクセシビリティベースか（CSSセレクタに逃げていないか）
- [ ] テストはユーザー操作の単位で分割されているか
- [ ] 暗黙の `sleep` ではなく明示的な待機条件を使っているか
- [ ] スクリーンショットの保存先・命名規則は決まっているか

## よくある落とし穴
- `npx agent-browser` で毎回起動すると遅い（グローバルインストール推奨）
- CSSクラス名に依存したセレクタがリファクタで全壊する
- `sleep(3000)` のような固定待機はCI環境で不安定になる
- スクリーンショット差分がフォントレンダリングの差で誤検知する（閾値設定が必要）
- Headless環境でのビューポートサイズ未指定でレイアウトが実機と異なる
