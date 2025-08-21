# リバースエンジニアリングによるドキュメント作成

## 入力: $ARGUMENTS（対象コードのパス）

## プロセス
1. **コード分析**
   - 実装内容を把握し、必要なドキュメントに落とし込む  

2. **参照ルール**
   - `doc/rdd.md`, `doc/architecture.md`, `doc/design/*` をSSOTとし整合性確認  
   - その他の文書（api-spec, uml, test_case, design_document）は逆生成  

3. **出力対象**
   - `doc/rdd.md` → 要件変更があれば追記  
   - `doc/architecture.md` → 実装変更を反映  
   - `doc/api-specification.md` → API仕様書化  
   - `doc/uml/` → ASCIIアート形式のUML図  
   - `doc/test_case/` → テストケース更新  
   - `doc/design_document/` → 設計意図・トレードオフの記録  

4. **整合性チェック**
   - SSOTとの矛盾がないか  
   - 不整合がある場合はユーザー確認  

## 出力
保存先: `doc/{各種ファイル}.md`
