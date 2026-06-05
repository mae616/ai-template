# personal-env: グローバル設定の個人環境バックアップ

`~/.claude/settings.json`（グローバル設定）をプロジェクトローカルへ移行・削除するにあたり、
**グローバルにしか存在しなかった個人環境設定**をここに退避・記録する。

> 配置理由: `meta/` は `apply_template.sh` の配布対象外（`INCLUDES` に含まれない）。
> テンプレ適用先プロジェクトには流れない＝ai-template 自身の個人環境としてだけ復元できる。

## 🎵 サウンドフック（音で作業状態を知らせる仕組み）

`~/.claude/settings.json` の `hooks` に定義していた、作業状態を音で通知する仕組み。

### 仕組み（settings.json 断片）

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "afplay ~/.claude/sounds/pick.mp3 &" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "afplay ~/.claude/sounds/cat7.mp3 &" }
        ]
      }
    ]
  }
}
```

- `UserPromptSubmit` → `pick.mp3`: プロンプト送信時に鳴らす
- `Stop` → `cat7.mp3`: 応答完了時に鳴らす
- `afplay` は macOS 標準コマンド。`&` でバックグラウンド再生（応答をブロックしない）

### 音源（mp3）

`meta/personal-env/sounds/` に5ファイル保全。

| ファイル | 用途 |
|---|---|
| `pick.mp3` | プロンプト送信時（UserPromptSubmit） |
| `cat7.mp3` | 応答完了時（Stop） |
| `cat20.mp3` | 予備 |
| `startsound.mp3` | 予備（起動音想定） |
| `tousen.mp3` | 予備 |

> ⚠️ **再配布注意**: これらは無料配布サイト由来のため再配布ライセンスが不明。
> `meta/personal-env/sounds/` は `.gitignore` 済み＝**公開リポジトリにはコミットしない**。
> 再配布可能な形にしたい場合は、自作音源に差し替えること。

### 復元手順（グローバル削除後に音を戻したい場合）

```bash
# 1. 音源を ~/.claude/sounds/ へ戻す
mkdir -p ~/.claude/sounds
cp meta/personal-env/sounds/*.mp3 ~/.claude/sounds/

# 2. 上記の hooks 断片を使う側の settings.json にマージする
#    （グローバル ~/.claude/settings.json か、各プロジェクトの .claude/settings.json）
```

## 📋 その他グローバル専用だった設定（削除前の記録）

音以外にも、グローバル `~/.claude/settings.json` にしかなかった設定を記録する。
プロジェクトローカルへ移すか、不要なら破棄するかを後で判断するための備忘。

- `statusLine`: claude-hud プラグインによるステータス表示
- `enabledPlugins`: typescript-lsp / example-skills / rust-analyzer-lsp / figma / claude-hud
- `extraKnownMarketplaces`: claude-hud（github: jarrodwatts/claude-hud）
- `language`: "Japanese"
- `effortLevel`: "high"
- `voice` / `voiceEnabled`: 音声入力設定（mode: hold）
- `remoteControlAtStartup`: true
- `agentPushNotifEnabled`: true
- `autoMemoryEnabled`: false
- `env`: `IS_DEMO` / `CLAUDE_CODE_NO_FLICKER`

> これらは個人環境・プラグイン依存のため、テンプレ本体（配布物）には含めない判断。
> 必要になったら使う側の settings.json に個別追加する。
