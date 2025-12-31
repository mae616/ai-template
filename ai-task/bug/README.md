# ai-task/bug（バグ対応ログ）

このフォルダは、`/bug-new` で起票した **バグ対応ログ（トラブルシューティングログ）** の置き場です。

## 基本方針
- **1バグ = 1ファイル**（Markdown）
- 進行に合わせて `/bug-investigate` → `/bug-propose` → `/bug-fix` が **同じファイルを追記更新**する
- 履歴はGitで追跡する（ログ内には「対応履歴（時系列）」も残す）

## 命名規約（推奨）
- `{短いタイトル}.md`
  - 例: `認証失敗.md`, `podmanが起動しない.md`

## 使い方（例）
```bash
/bug-new podmanが起動しない
/bug-investigate ai-task/bug/podmanが起動しない.md
/bug-propose ai-task/bug/podmanが起動しない.md
/bug-fix ai-task/bug/podmanが起動しない.md
```

## 補足（証跡）
必要なら、検証ログ/スクショ/計測結果などの証跡を `ai-task/bug/artifacts/` 配下に置き、ログ本文から相対リンクします。

