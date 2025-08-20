# 指示読み込みガイド
> このファイルは、AIエージェントが適切な指示を選択するためのガイドです

# 役割別指示選択ガイド

## 🎨 フロントエンド開発者
```
@core-personality.md
@development-core.md
@tdd-specialist.md
```

## 🏗️ アーキテクチャ設計者
```
@core-personality.md
@development-core.md
@security-architect.md
@documentation-expert.md
```

## 📊 プロジェクトマネージャー
```
@core-personality.md
@development-core.md
@project-manager.md
```

## 🚀 フルスタック開発者
```
@core-personality.md
@development-core.md
@tdd-specialist.md
@documentation-expert.md
```

## 🔒 セキュリティ専門家
```
@core-personality.md
@development-core.md
@security-architect.md
```

## 📚 ドキュメント専門家
```
@core-personality.md
@development-core.md
@documentation-expert.md
```

## 🧪 テスト・品質保証専門家
```
@core-personality.md
@development-core.md
@tdd-specialist.md
@security-architect.md
```

# 使用方法
1. **基本設定として** `@core-personality.md` と `@development-core.md` を必ず読み込む
2. **専門領域に応じて** 必要な指示ファイルを選択
3. **必要に応じて** 他の専門ファイルを参照

# ファイル構成
```
ai_instructions/
├── 🎭 core-personality.md          # 基本ペルソナ（必須）
├── 🛠️ development-core.md         # 開発の基本原則（必須）
├── 🧪 tdd-specialist.md           # TDD専門家用
├── 📚 documentation-expert.md      # ドキュメント専門家用
├── 🔒 security-architect.md        # セキュリティ専門家用
├── 📊 project-manager.md           # プロジェクト管理専門家用
└── 🎯 instruction-loader.md        # 動的読み込み用（このファイル）
```

# 注意事項
- **基本設定は必須**: `@core-personality.md` と `@development-core.md` は常に含める
- **専門性のバランス**: 過度に多くの指示ファイルを読み込むと混乱する可能性
- **段階的適用**: 必要に応じて段階的に指示ファイルを追加
- **定期的な見直し**: 役割やプロジェクトの変化に応じて指示ファイルを調整

# トラブルシューティング
## 指示が重複している場合
- 基本設定と専門設定で重複する内容がある場合は、専門設定を優先
- 矛盾する指示がある場合は、より具体的な指示を優先

## 指示が不足している場合
- 必要な指示が見つからない場合は、`@development-core.md` の基本原則を参照
- 特定の技術領域について詳しく知りたい場合は、該当する専門ファイルを追加

## 指示が多すぎる場合
- 現在のタスクに関係ない指示ファイルは一時的に除外
- 必要最小限の指示ファイルのみを使用
