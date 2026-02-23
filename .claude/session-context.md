# セッションコンテキスト

## 前回の作業
- **日時**: 2026-02-23
- **ブランチ**: fix_skills_insights
- **最後のコミット**: 835bc83 - feat: 判断軸スキル5種を新規作成（blender/threejs/p5js/gsap/animation-principles）

## 完了したこと
- design-split スキルを廃止し、design-html に統合
- デザイン起点の自動判断ルールを CLAUDE.md に追加（Figma/Pencil/Mock の3分岐をAIが自動選択）
- design_workflow.md をフロー全体で整理（Pencilルート追加）
- UI/UX系5スキルの使い分けガイド（早見表）を design_workflow.md に追加
- グローバル CLAUDE.md にも同じ変更を反映
- 判断軸スキル5種を新規作成:
  - blender: Blender MCP + プリミティブ→スカルプティング段階的ワークフロー
  - threejs: Scene-Camera-Renderer三位一体 + 手動メモリ管理
  - p5js: Processing由来「コードでスケッチ」+ setup/drawループ
  - gsap: Tween/Timeline/ScrollTrigger/Easing + CSS transition併用禁止
  - animation-principles: ディズニー12原則のUI適用 + ジブリ的自然運動

## 未完了（次回継続の候補）
- mainへのマージ・push（fix_skills_insights ブランチの全変更）
- エージェントチームの実地テスト（`claude --teammate-mode tmux` で実行）

## 再開用プロンプト
> fix_skills_insights ブランチで作業中。スキル統合・自動判断ルール・使い分けガイド・判断軸5種作成が完了。
> 残タスク: mainマージ・push、エージェントチーム実地テスト。
> マージする場合は `git log main..fix_skills_insights --oneline` で全コミットを確認してから実施。
