---
name: blender
category: tech
user-invocable: false
description: Blender MCP（3Dモデリング）のプリミティブ→スカルプティング段階的ワークフローと、AI経由のBlender操作（JSON-RPC over TCP）の判断軸。3Dモデリング/シーン構築/スカルプティングの相談で使う。
---

# Blender 3D Modeling Skill

## 参照（公式）
- [Blender公式マニュアル](https://docs.blender.org/manual/en/latest/)
- [Modeling Introduction](https://docs.blender.org/manual/en/latest/modeling/introduction.html)
- [Sculpt Mode](https://docs.blender.org/manual/en/latest/sculpt_paint/sculpting/introduction/general.html)
- [Subdivision Surface Modifier](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/subdivision_surface.html)
- [Blender MCP（非公式）](https://github.com/ahujasid/blender-mcp)

## 発火条件
- Blender MCPがMCPサーバーとして登録されている場合、このSkillの方針をデフォルト採用する。
- 3Dモデリング、シーン構築、スカルプティング、リトポロジーに関する相談で適用する。

## このSkillの基本方針
- モデリング: プリミティブ→ブロック→サブディビジョン→スカルプト→リトポロジーの段階的アプローチ。
- トポロジー: クワッド（四角形ポリゴン）ベースを原則とする。
- 非破壊性: Modifierを活用し、可逆性を保つ。
- 視点の多様性: 常にモデルを回転し、全方位から確認する。
- Blender MCP: JSON-RPC 2.0 over TCPでBlender Python APIを操作。自然言語→Blenderコマンド変換。

## 思想（判断ルール）
1. シンプルから複雑へ — どんな形もプリミティブ（立方体/球/円柱）から始める。
2. 大きな形を先に — 全体のシルエットが決まるまでディテールに入らない。
3. 段階的解像度 — 低ポリ→Subdivision→スカルプト→リトポロジーの順で進む。
4. クワッド優先 — 四角形ポリゴンは編集・変形・Subdivisionすべてで最適。
5. 非破壊ワークフロー — Modifierを使い、確定操作は最後にする。
6. Remeshは意図を持って — ボクセルサイズは1.5倍以内で段階的に下げる。

## 出力フォーマット（必ずこの順）
1. 推奨方針（1〜3行）
2. 理由（モデリング段階 / トポロジー / パフォーマンス）
3. 設計案（プリミティブ選択 / Modifier戦略 / スカルプトフロー / リトポロジー方針）
4. チェックリスト（実装前に確認）
5. 落とし穴（避けるべき）
6. 次アクション（小さく試す順）

## チェックリスト
- [ ] プリミティブの選択は適切か（モデリング対象に合った基本形状）
- [ ] 全体のシルエットが先に決まっているか（ディテール後回し）
- [ ] トポロジーはクワッドベースか（三角形/N-gonが混在していないか）
- [ ] Subdivision Surfaceのレベルは適切か（ビューポートとレンダーで分けているか）
- [ ] スカルプト時のメッシュ密度は十分か（頂点不足で彫れないことがないか）
- [ ] Remeshのボクセルサイズ変更は1.5倍以内か
- [ ] 360度回転して形状を確認したか

## よくある落とし穴
- 早すぎるディテール追加（全体の形が決まる前に細かい部分を作り込む）
- Smoothブラシの乱用（形状の決定ではなく遷移の洗練に使うもの）
- Remeshの頻繁すぎる実行・急激なボクセルサイズ変更（面が荒れる）
- 固定視点でのスカルプト（一方向からしか見ないと360度で破綻する）
- メッシュの準備不足（サブディビジョンなしではスカルプトできない）
- Blender MCP経由の操作で、複雑な手順を一度に指示する（小さなステップに分割する）
