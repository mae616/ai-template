---
name: playwright
category: tech
user-invocable: false
description: Playwright E2Eテストフレームワークの判断軸。ユーザー視点のロケーター選択・自動待機・テスト分離・CI最適化を公式ベストプラクティスに沿って整理する。doc/input/rdd.md に「Playwright」「E2Eテスト」がある場合や、ブラウザテスト設計の相談で使う。
---

# Playwright E2E Testing Skill

## 参照（公式）
- [Playwright公式](https://playwright.dev)
- [Best Practices](https://playwright.dev/docs/best-practices)
- [Locators](https://playwright.dev/docs/locators)

## 発火条件
- `doc/input/rdd.md` に `Playwright` や `E2Eテスト` が記載されている場合、このSkillの方針をデフォルト採用する。
- 記載がなくても、ブラウザE2Eテスト設計・Playwrightの使い方に該当する相談なら適用する。

## このSkillの基本方針
- 基本方針: ユーザーに見える振る舞いをテストする。実装詳細（class名/id/DOM構造）に依存しない。
- ロケーター: `getByRole` > `getByLabel` > `getByText` > `getByTestId` > CSSセレクタ。ロールベースを最優先。
- アサーション: Web Firstアサーション（自動リトライ付き）を使う。手動の `isVisible()` チェックを避ける。
- テスト分離: 各テストは完全に独立。共有状態・テスト順序依存を排除する。
- パフォーマンス: グローバルインストール推奨。CIではLinux + 必要ブラウザのみ + シャーディング。

## 思想（判断ルール）
1. **ユーザー視点でテストする**: エンドユーザーが操作する通りにテストを書く。内部APIやDOM構造に依存しない。
2. **ロールベースのロケーター最優先**: `getByRole('button', { name: '送信' })` はリファクタに強い。CSSセレクタはDOMの変更で壊れる。
3. **自動待機を信頼する**: Playwrightは要素の可視性・有効性を自動で待つ。明示的な `sleep` や `waitForTimeout` は不要。
4. **テストは独立させる**: 各テストは独自のブラウザコンテキスト（Cookie/ストレージ）で実行。beforeEachで共通セットアップ。
5. **外部依存はモックする**: サードパーティAPIはNetwork APIでインターセプト。外部サイトのリンク先はテストしない。
6. **デバッグにはTrace Viewerを使う**: スクリーンショットやビデオよりTraceの方が情報量が多い。CIでは `on: 'first-retry'` で有効化。

## ロケーター選択の優先順位

```typescript
// 1. ロールベース（最優先・推奨）
page.getByRole('button', { name: '送信' })
page.getByRole('textbox', { name: 'メールアドレス' })
page.getByRole('heading', { name: 'ログイン' })

// 2. ラベル/プレースホルダー
page.getByLabel('メールアドレス')
page.getByPlaceholder('example@mail.com')

// 3. テキスト
page.getByText('ログイン')

// 4. テストID（他の方法で特定できない場合）
page.getByTestId('submit-button')

// 5. CSSセレクタ（最終手段）
page.locator('#submit-btn')
```

## アサーションの書き方

```typescript
// 推奨: Web Firstアサーション（自動リトライ付き）
await expect(page.getByText('ようこそ')).toBeVisible()
await expect(page.getByRole('alert')).toHaveText('保存しました')
await expect(page).toHaveURL('/dashboard')

// 非推奨: 手動チェック（リトライなし）
expect(await page.getByText('ようこそ').isVisible()).toBe(true)
```

## テスト構造のパターン

```typescript
import { test, expect } from '@playwright/test'

test.describe('ログインフロー', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login')
  })

  test('正常系_有効な認証情報でダッシュボードに遷移', async ({ page }) => {
    await page.getByLabel('メールアドレス').fill('user@example.com')
    await page.getByLabel('パスワード').fill('password123')
    await page.getByRole('button', { name: 'ログイン' }).click()
    await expect(page).toHaveURL('/dashboard')
  })

  test('異常系_無効なパスワードでエラー表示', async ({ page }) => {
    await page.getByLabel('メールアドレス').fill('user@example.com')
    await page.getByLabel('パスワード').fill('wrong')
    await page.getByRole('button', { name: 'ログイン' }).click()
    await expect(page.getByRole('alert')).toHaveText('認証に失敗しました')
  })
})
```

## CI最適化

```typescript
// playwright.config.ts のCI向け設定
export default defineConfig({
  // CIでは全リトライ1回
  retries: process.env.CI ? 1 : 0,
  // CIでは並列ワーカーを制限
  workers: process.env.CI ? 2 : undefined,
  // Traceは最初のリトライ時のみ
  use: {
    trace: 'on-first-retry',
  },
})
```

```bash
# CIで必要なブラウザだけインストール
npx playwright install --with-deps chromium

# シャーディングで並列化
npx playwright test --shard=1/3
npx playwright test --shard=2/3
npx playwright test --shard=3/3
```

## 出力フォーマット（必ずこの順）
1. 推奨方針（1〜3行）
2. 理由（テスト安定性 / 保守性 / ユーザー視点）
3. 設計案（テスト対象フロー / ロケーター戦略 / モック戦略 / CI設定）
4. チェックリスト（実装前に確認）
5. 落とし穴（避けるべき）
6. 次アクション（小さく試す順）

## チェックリスト
- [ ] ロケーターはロールベース(`getByRole`)を最優先にしているか
- [ ] アサーションはWeb First（`await expect(...).toBeVisible()` 等）か
- [ ] 各テストが独立しているか（共有状態・順序依存なし）
- [ ] `waitForTimeout` / `sleep` を使っていないか
- [ ] 外部API/サービスはNetwork APIでモックしているか
- [ ] CIでTrace Viewerが有効か（`on-first-retry`）
- [ ] テスト名が「何のフロー_どの条件で_何が起きるか」を表しているか

## よくある落とし穴
- CSSセレクタ（`.btn-primary`）に依存してリファクタで全壊する
- `page.waitForTimeout(3000)` でCI環境の速度差を吸収しようとする（不安定の根本原因）
- テスト間でログイン状態を共有し、順序依存でCI上でだけ失敗する
- E2Eテストを大量に書いてCI実行時間が数十分になり、開発サイクルが遅くなる
- スクリーンショット比較がフォントレンダリングの差で誤検知する（閾値設定が必要）
- Playwrightのバージョンが古く、最新ブラウザの挙動変更でテストが壊れる
