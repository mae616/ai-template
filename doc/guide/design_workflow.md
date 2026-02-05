# デザインワークフローガイド

## フロー概要

```
起点選択 → SSOT生成 → UI骨格 → コンポーネント分離 → 結合
```

## 1. 起点を選ぶ

| 状況 | スキル | 説明 |
|------|--------|------|
| Figmaあり | `/design-ssot` | Figma MCPからSSOT抽出 |
| Figmaなし/叩き台から | `/design-mock` | 会話からSSOT + HTML生成 |

## 2. 順番に進める

| 順 | スキル | やること |
|----|--------|----------|
| 2 | `/design-ui` | SSOT → 静的UI骨格（見た目のみ） |
| 3 | `/design-components` | UI骨格 → Layout/Component抽出 |
| 4 | `/design-assemble` | variants → 型付きProps結合 |

## 任意オプション

| スキル | 用途 |
|--------|------|
| `/design-html` | SSOT → 静的HTML出力 |
| `/design-split` | 1枚HTML → ページ単位に分割 |

## チェックポイント（コミットタイミング）

- **起点完了時**: SSOT（`doc/input/design/*.json`）生成後
- **UI骨格完了時**: 静的UIファイル生成後
- **コンポーネント分離完了時**: 各コンポーネント抽出後

> 💡 セッション途中終了に備え、各ステップ完了ごとにコミットする
