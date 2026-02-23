# デザインワークフローガイド

## フロー概要

```
「デザインしたい」→ AIが起点を自動判断 → SSOT生成 → (HTML確認) → UI骨格 → コンポーネント分離 → 結合
```

## 1. 起点（AIが自動判断）

ユーザーは起点スキルを覚える必要はない。AIが会話の文脈から適切な起点を選んで提案する。

| 手がかり | 起点スキル | 説明 |
|---------|-----------|------|
| Figma URLが会話にある | `/design-ssot` | Figma MCPからSSOT抽出 |
| `.pen` ファイルがある / Pencil指定 | Pencil MCP | Pencilエディタで直接デザイン |
| どちらもない | `/design-mock` | 会話からSSOT + HTML叩き台を生成 |

## 2. 共通フロー（起点完了後）

| 順 | スキル | やること |
|----|--------|----------|
| 1.5 | `/design-html`（任意） | SSOT → ページ単位HTML生成（イメージ確認用） |
| 2 | `/design-ui` | SSOT → 静的UI骨格（見た目のみ） |
| 3 | `/design-components` | UI骨格 → Layout/Component抽出 |
| 4 | `/design-assemble` | variants → 型付きProps結合 |

> `/design-html` は、ページ単位でブラウザ確認したい場合にAIが自動提案する（旧 `/design-split` の役割も統合済み）

## 3. UI/UX判断軸スキルの使い分け

以下の5スキルはAIが自動参照する判断軸（`user-invocable: false`）。ユーザーが手動で呼ぶ必要はない。

### 早見表: どの場面でどのスキルが効くか

| 場面 | 主担当 | 補助 |
|------|--------|------|
| 画面の目的・構造・優先度を決める | `ui-designer` | `usability-psychologist` |
| コンポーネント設計・トークン整理 | `ui-designer` | `frontend-implementation` |
| 「使いにくい」「迷う」「離脱」の改善 | `usability-psychologist` | `ui-designer` |
| フォーム/入力/オンボーディング設計 | `usability-psychologist` | `accessibility-engineer` |
| アニメーション・演出・トランジション | `creative-coder` | `frontend-implementation` |
| デザインデータ → 実装への翻訳 | `frontend-implementation` | `ui-designer` |
| レスポンシブ・比率・崩れ耐性 | `frontend-implementation` | `creative-coder` |
| セマンティックHTML・ARIA・キーボード操作 | `accessibility-engineer` | `usability-psychologist` |
| スクリーンリーダ・フォーカス管理 | `accessibility-engineer` | `frontend-implementation` |

### 各スキルの守備範囲（一言）

| スキル | 一言 | 主な問い |
|--------|------|---------|
| `ui-designer` | **何を・どの順で見せるか** | 画面の目的は？主要CTAは？例外状態は？ |
| `usability-psychologist` | **迷い・負荷・エラーを減らす** | どこで失敗してる？認知負荷の原因は？ |
| `creative-coder` | **動きで情報を伝える** | この演出の目的は？reduced motion対応は？ |
| `frontend-implementation` | **デザインを壊れない構造に翻訳** | 比率は？制約は？崩れ耐性は？ |
| `accessibility-engineer` | **支援技術に正しく伝わる実装** | キーボードで完了できる？名前が付いてる？ |

### 併用パターン

- **設計フェーズ**（`/design-mock` 〜 `/design-ui`）: `ui-designer` + `usability-psychologist`
- **実装フェーズ**（`/design-components` 〜 `/design-assemble`）: `frontend-implementation` + `accessibility-engineer`
- **表現が重要な場面**: 上記 + `creative-coder`

## チェックポイント（コミットタイミング）

- **起点完了時**: SSOT（`doc/input/design/*.json`）生成後
- **HTML確認完了時**: ページ単位HTML生成後（任意）
- **UI骨格完了時**: 静的UIファイル生成後
- **コンポーネント分離完了時**: 各コンポーネント抽出後

> セッション途中終了に備え、各ステップ完了ごとにコミットする
