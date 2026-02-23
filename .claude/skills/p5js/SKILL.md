---
name: p5js
category: tech
user-invocable: false
description: P5.js（クリエイティブコーディング）のProcessing由来「コードでスケッチ」思想を軸に、setup/drawループ・座標系・インタラクション・パフォーマンス最適化を整理する。クリエイティブコーディング/ジェネラティブアート/インタラクティブ表現の相談で使う。
---

# P5.js Creative Coding Skill

## 参照（公式）
- [P5.js公式](https://p5js.org/)
- [P5.js About](https://p5js.org/about/)
- [P5.js Reference](https://p5js.org/reference/)
- [最適化ガイド](https://p5js.org/tutorials/how-to-optimize-your-sketches/)
- [WebGL最適化](https://p5js.org/tutorials/optimizing-webgl-sketches/)

## 発火条件
- `doc/input/rdd.md` に `P5.js` / `Processing` / `クリエイティブコーディング` が書かれている場合に適用する。
- ジェネラティブアート、インタラクティブ表現、ビジュアルプログラミングの相談で適用する。

## このSkillの基本方針
- 思想: 「コードでスケッチする」— ブラウザ全体がスケッチブック。
- 構造: setup()で初期化、draw()で毎フレーム描画（最大60FPS）のループが基本。
- アクセシビリティ: P5.jsの根幹は包摂性。「新機能はアクセスを増やすもの以外は追加しない」。
- パフォーマンス: 2Dはデフォルト、重い処理はWebGLモード + Framebuffer + シェーダーを検討。

## 思想（判断ルール）
1. スケッチから始める — 小さな実験スケッチで動作確認してから統合する。
2. setup/draw/preloadの3関数が骨格 — preloadでリソース読み込み、setupで初期化、drawで描画。
3. 座標系は左上原点 — (0,0)は左上、+xが右、+yが下。
4. インタラクションは組み込み変数 — mouseX/mouseY/keyPressedなどがフレームごとに自動更新される。
5. ピクセル操作はコストを意識 — get()/set()は簡単だが遅い。速度が必要ならpixels[]配列かシェーダー。
6. WebGLモードは別世界 — Framebuffer（GPU完結）やbuildGeometry()で再計算回避が可能。

## 出力フォーマット（必ずこの順）
1. 推奨方針（1〜3行）
2. 理由（表現 / パフォーマンス / アクセシビリティ）
3. 設計案（描画戦略 / インタラクション / 最適化 / アドオンライブラリ）
4. チェックリスト（実装前に確認）
5. 落とし穴（避けるべき）
6. 次アクション（小さく試す順）

## チェックリスト
- [ ] preload/setup/drawのスペルは正確か（大文字小文字厳密、preLoad NG）
- [ ] createCanvas()のサイズはターゲット環境に適切か
- [ ] frameRate()で適切な上限を設定しているか（不要なら60FPSのまま）
- [ ] pixelDensity()を意識しているか（Retinaディスプレイで2倍になる）
- [ ] loadPixels()をget()/set()/pixels[]の前に呼んでいるか
- [ ] 重い処理はdraw()の外に出しているか（setup()や条件分岐で制御）
- [ ] WebGLモードの場合、FramebufferやbuildGeometry()で最適化しているか

## よくある落とし穴
- preload()のスペルミス（`preLoad()` と書くと静かに失敗する）
- 変数のスコープ問題（JavaScriptは大文字小文字を厳密に区別する）
- print()の非同期タイミング（配列の内容が変わった後に表示されることがある）
- JavaScriptの寛容性（Processing/Javaよりエラーが見つかりにくい）
- ピクセル操作のパフォーマンス（JSのループは遅い、シェーダーなら並列処理可能）
- WebGLモードでp5.Graphicsを毎フレームGPU転送する（.get()で画像化して回避）
- ブラウザ間のpixelDensity不整合（明示的にpixelDensity(1)で統一を検討）
