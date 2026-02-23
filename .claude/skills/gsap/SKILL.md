---
name: gsap
category: tech
user-invocable: false
description: GSAP（GreenSock Animation Platform）のTween/Timeline/ScrollTrigger/Easingを軸に、ウェブアニメーションの設計・実装・パフォーマンス最適化を整理する。doc/input/rdd.md に「GSAP」「GreenSock」がある場合や、ウェブアニメーション/スクロール連動の相談で使う。
---

# GSAP Animation Skill

## 参照（公式）
- [GSAP公式](https://gsap.com/)
- [GSAP Docs](https://gsap.com/docs/v3/)
- [Easing Visualizer](https://gsap.com/docs/v3/Eases/)
- [Common Mistakes](https://gsap.com/resources/mistakes/)
- [React & GSAP](https://gsap.com/resources/react-basics/)
- [ScrollTrigger](https://gsap.com/docs/v3/Plugins/ScrollTrigger/)

## 発火条件
- `doc/input/rdd.md` に `GSAP` / `GreenSock` / `ScrollTrigger` が書かれている場合に適用する。
- ウェブアニメーション、スクロール連動、タイムライン制御、イージングの相談で適用する。

## このSkillの基本方針
- ツール選択: CSSで足りるシンプルなアニメーションにはCSSを使う。複雑なシーケンス/インタラクション/制御が必要ならGSAP。
- 構造: Tween（単発）→ Timeline（シーケンス）→ ScrollTrigger（スクロール連動）の段階で設計する。
- パフォーマンス: requestAnimationFrame前提。CSS transitionとの併用は厳禁。
- ライセンス: 2024年Webflow提携で全機能無料化（独自ライセンス、商用OK）。
- React: `useGSAP()` Hook（@gsap/react）が公式推奨。useEffect/useLayoutEffectのドロップイン代替。

## 思想（判断ルール）
1. CSSかGSAPかを先に判断する — ホバー等のシンプルなエフェクトはCSSで十分。シーケンス/制御/インタラクションが必要ならGSAP。
2. Timelineでシーケンスを一元管理 — delayの手計算ではなく、Timelineの相対タイミングで制御する。
3. CSS transitionとGSAPは併用しない — ブラウザの割り込みでパフォーマンス最悪。
4. デフォルトease（power1.out）を理解する — イージングがアニメーションの「人格」を決める。
5. ScrollTriggerは1対1 — 1つのScrollTriggerに1つのアニメーション（複数はTimelineにまとめる）。
6. クリーンアップは義務 — scroll/resizeリスナー、タイマー、イベントハンドラを必ず解除する。

## 出力フォーマット（必ずこの順）
1. 推奨方針（1〜3行）
2. 理由（表現意図 / パフォーマンス / 保守性）
3. 設計案（Tween/Timeline構成 / Easing選択 / ScrollTrigger設計 / React統合）
4. チェックリスト（実装前に確認）
5. 落とし穴（避けるべき）
6. 次アクション（小さく試す順）

## チェックリスト
- [ ] CSSで実現できないか先に検討したか（GSAPはオーバーキルの場合がある）
- [ ] アニメーション対象要素にCSS transitionが当たっていないか（競合チェック）
- [ ] Timelineは事前作成しているか（必要時に都度作るよりパフォーマンス良好）
- [ ] ScrollTriggerをネストされたTimeline内のTweenに個別適用していないか
- [ ] `will-change` CSSプロパティで事前最適化ヒントを出しているか
- [ ] React環境では `useGSAP()` + `contextSafe()` を使っているか
- [ ] アンマウント時のクリーンアップ（gsap.context().revert()）があるか

## よくある落とし穴
- CSS transitionとGSAPの併用（パフォーマンス最悪、ブラウザが常に割り込む）
- 完了済みTimelineへのTween追加（再実行しない限り呼ばれない）
- `.from()` の誤解（指定値→現在値へのアニメーション。未完了時は意図した終点に達しない）
- ScrollTriggerをネストTimeline内の個別Tweenに適用（親Timelineとスクロールバーの制御が矛盾）
- アニメーションの過剰使用（印象的だが、多すぎるとUXが混沌とする）
- モジュール環境でのインポートミス（公式インストールガイドを参照）
- React環境でcontextSafe()なしのイベントハンドラ（クリーンアップが効かない）
