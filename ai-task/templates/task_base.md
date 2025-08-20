name: "ベースTASKテンプレート v2 - コンテキスト豊富で検証ループ付き"
description: |

## 目的
AIエージェントが十分なコンテキストと自己検証機能を持って機能を実装し、反復的な改善を通じて動作するコードを達成できるように最適化されたテンプレート。

## コア原則
1. **コンテキストが王様**: 必要なドキュメント、例、注意点をすべて含める
2. **検証ループ**: AIが実行して修正できる実行可能なテスト/リントを提供
3. **情報密度**: コードベースからのキーワードとパターンを使用
4. **段階的成功**: シンプルに開始し、検証してから強化
5. **グローバルルール**: CLAUDE.mdのすべてのルールに従うことを確実にする

---

## 目標
[何を構築する必要があるか - 最終状態と希望について具体的に]

## なぜ
- [ビジネス価値とユーザーへの影響]
- [既存機能との統合]
- [これが解決する問題と対象者]

## 何を
[ユーザーが目に見える動作と技術的要件]

### 成功基準
- [ ] [具体的で測定可能な成果]

## 必要なすべてのコンテキスト

### ドキュメントと参照（機能を実装するために必要なすべてのコンテキストをリスト化）
```yaml
# 必ず読む - これらをコンテキストウィンドウに含める
- url: [公式APIドキュメントURL]
  why: [必要な特定のセクション/メソッド]
  
- file: [path/to/example.py]
  why: [従うべきパターン、避けるべき落とし穴]
  
- doc: [ライブラリドキュメントURL] 
  section: [一般的な落とし穴についての特定のセクション]
  critical: [一般的なエラーを防ぐ重要な洞察]

- docfile: [ai-task/ai_docs/file.md]
  why: [ユーザーがプロジェクトに貼り付けたドキュメント]

```

### 現在のコードベースツリー（プロジェクトのルートで`tree`を実行）でコードベースの概要を取得
```bash

```

### 追加されるファイルとファイルの責任を含む希望するコードベースツリー
```bash

```

### 私たちのコードベースとライブラリの癖の既知の落とし穴
```typescript
// 重要: [ライブラリ名]は[特定のセットアップ]を必要とする
// 例: Express.jsはミドルウェアの順序が重要
// 例: このORMは1000レコードを超えるバッチ挿入をサポートしない
// 例: 私たちはZod v3を使用し、
```

## 実装ブループリント

### データモデルと構造

コアデータモデルを作成し、型安全性と一貫性を確保します。
```typescript
例: 
 - インターフェース
 - 型定義
 - Zodスキーマ
 - バリデーション関数

```

### TASKを満たすために完了すべきタスクのリスト（実行順序）

```yaml
タスク1:
MODIFY src/existing_module.ts:
  - FIND pattern: "class OldImplementation"
  - INJECT after line containing "constructor"
  - PRESERVE existing method signatures

CREATE src/new_feature.ts:
  - MIRROR pattern from: src/similar_feature.ts
  - MODIFY class name and core logic
  - KEEP error handling pattern identical

...(...)

タスクN:
...

```


### 必要に応じて各タスクに追加されるタスクごとの疑似コード
```typescript

// タスク1: 新機能の実装
// 重要な詳細を含む疑似コード（完全なコードは書かない）
async function newFeature(param: string): Promise<Result> {
    // パターン: 常に最初に入力を検証する（src/validators.tsを参照）
    const validated = validateInput(param);  // ValidationErrorを発生させる
    
    // 落とし穴: このライブラリは接続プールを必要とする
    const conn = await getConnection();  // src/db/pool.tsを参照
    try {
        // パターン: 既存のリトライ関数を使用
        const result = await retry(
            async () => {
                // 重要: APIは10 req/secを超えると429を返す
                await rateLimiter.acquire();
                return await externalApi.call(validated);
            },
            { attempts: 3, backoff: 'exponential' }
        );
        
        // パターン: 標準化されたレスポンス形式
        return formatResponse(result);  // src/utils/responses.tsを参照
    } finally {
        conn.release();
    }
}
```

### 統合ポイント
```yaml
データベース:
  - migration: "usersテーブルにカラム'feature_enabled'を追加"
  - index: "CREATE INDEX idx_feature_lookup ON users(feature_id)"
  
設定:
  - add to: config/settings.py
  - pattern: "FEATURE_TIMEOUT = int(os.getenv('FEATURE_TIMEOUT', '30'))"
  
ルート:
  - add to: src/api/routes.py  
  - pattern: "router.include_router(feature_router, prefix='/feature')"
```

## 検証ループ

### レベル1: 構文とスタイル
```bash
# これらを最初に実行 - 続行する前にエラーを修正
pnpm lint src/new_feature.ts --fix  # 可能なものを自動修正
pnpm type-check src/new_feature.ts  # 型チェック

# 期待: エラーなし。エラーがある場合、エラーを読み、修正する。
```

### レベル2: 各新機能/ファイル/関数のユニットテスト（既存のテストパターンを使用）
```typescript
// これらのテストケースでtest_new_feature.test.tsを作成:
import { describe, it, expect, vi } from 'vitest';

describe('newFeature', () => {
    it('基本的な機能が動作する', async () => {
        const result = await newFeature("valid_input");
        expect(result.status).toBe("success");
    });

    it('無効な入力はValidationErrorを発生させる', async () => {
        await expect(newFeature("")).rejects.toThrow(ValidationError);
    });

    it('タイムアウトを適切に処理する', async () => {
        vi.spyOn(externalApi, 'call').mockRejectedValue(new Error('timeout'));
        const result = await newFeature("valid");
        expect(result.status).toBe("error");
        expect(result.message).toContain("timeout");
    });
});
```

```bash
# 実行して合格するまで反復:
pnpm test test_new_feature.test.ts
# 失敗する場合: エラーを読み、根本原因を理解し、コードを修正し、再実行（合格するためにモックしない）
```

### レベル3: 統合テスト
```bash
# サービスを開始
pnpm dev

# エンドポイントをテスト
curl -X POST http://localhost:3000/feature \
  -H "Content-Type: application/json" \
  -d '{"param": "test_value"}'

# 期待: {"status": "success", "data": {...}}
# エラーの場合: logs/app.logでスタックトレースをチェック
```

## 最終検証チェックリスト
- [ ] すべてのテストが合格: `pnpm test`
- [ ] リンティングエラーなし: `pnpm lint src/`
- [ ] 型エラーなし: `pnpm type-check src/`
- [ ] 手動テスト成功: [特定のcurl/コマンド]
- [ ] エラーケースが適切に処理される
- [ ] ログが有益だが冗長ではない
- [ ] 必要に応じてドキュメントが更新される

---

## 避けるべきアンチパターン
- ❌ 既存のパターンが機能する場合に新しいパターンを作成しない
- ❌ 「動作するはず」だからといって検証をスキップしない
- ❌ 失敗するテストを無視しない - 修正する
- ❌ 非同期コンテキストで同期関数を使用しない
- ❌ 設定すべき値をハードコードしない
- ❌ すべての例外をキャッチしない - 具体的にする
