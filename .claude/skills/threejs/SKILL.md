---
name: threejs
category: tech
user-invocable: false
description: Three.js（WebGL/3D表現）のScene-Camera-Renderer三位一体と手動メモリ管理を軸に、ウェブ3Dの設計・実装・パフォーマンス最適化を整理する。doc/input/rdd.md に「Three.js」「WebGL」「R3F」がある場合や、ウェブ3D表現の相談で使う。
---

# Three.js WebGL/3D Skill

## 参照（公式）
- [Three.js公式](https://threejs.org/)
- [Three.js Fundamentals](https://threejsfundamentals.org/)
- [Discover three.js](https://discoverthreejs.com/)
- [React Three Fiber](https://r3f.docs.pmnd.rs/)

## 発火条件
- `doc/input/rdd.md` に `Three.js` / `WebGL` / `R3F` / `React Three Fiber` が書かれている場合に適用する。
- ウェブ上の3D表現、WebGLレンダリング、3Dシーン構築の相談で適用する。

## このSkillの基本方針
- 構造: Scene-Camera-Rendererの三位一体がすべての出発点。
- メモリ管理: GPUリソースは自動GCされない。dispose()は義務。
- 最適化: 描画コール削減（バッチング/インスタンシング/LOD）と圧縮テクスチャ（KTX2）が鍵。
- R3F: React環境ではReact Three Fiberを第一候補とする（Three.jsの完全なラッパー、オーバーヘッドなし）。

## 思想（判断ルール）
1. Scene-Camera-Renderer — すべてはこの3要素から始まる。省略しない。
2. GPUメモリは手動管理 — geometry/material/texture/renderTargetは明示的にdispose()する。
3. 描画コールを減らす — 個別メッシュの大量生成はバッチング/インスタンシングで回避する。
4. テクスチャは圧縮する — PNG/JPEGはGPUで完全展開される（200KB PNG → 20MB+ VRAM）。KTX2/Basis Universalで約1/10に。
5. 静的オブジェクトは手動更新 — `matrixAutoUpdate = false` + 変更時に `updateMatrix()` を呼ぶ。
6. R3Fは薄いラッパー — Three.jsで動くものはR3Fでもそのまま動く。新バージョンの機能も即座に利用可能。

## 出力フォーマット（必ずこの順）
1. 推奨方針（1〜3行）
2. 理由（パフォーマンス / メモリ / 保守性）
3. 設計案（シーン構造 / メモリ戦略 / レンダリング最適化 / R3F活用）
4. チェックリスト（実装前に確認）
5. 落とし穴（避けるべき）
6. 次アクション（小さく試す順）

## チェックリスト
- [ ] dispose()漏れがないか（geometry/material/texture/renderTarget）
- [ ] `renderer.info.memory` でリソース数を監視しているか（数値が増え続けるならリーク）
- [ ] 静的オブジェクトに `matrixAutoUpdate = false` を設定しているか
- [ ] テクスチャは圧縮フォーマット（KTX2/Basis）を使っているか
- [ ] 大量の同一メッシュはインスタンシングを使っているか
- [ ] アニメーションループの停止処理（cleanup）があるか
- [ ] ウィンドウリサイズ時にカメラのaspect ratioとrenderer.setSizeを更新しているか

## よくある落とし穴
- dispose()忘れによるメモリリーク（最大の落とし穴）
- 毎フレームで `new THREE.Vector3()` などのオブジェクト生成（ループ外で再利用する）
- CSS transitionとThree.jsアニメーションの競合
- `requestAnimationFrame` を複数箇所で呼び出す
- PNG/JPEGテクスチャの濫用によるVRAM浪費
- すべてを1ファイルに詰め込む（Scene管理はモジュール分割する）
- イベントリスナー（resize等）のcleanup忘れ
