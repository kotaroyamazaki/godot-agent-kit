# godot-agent-kit

**AI エージェントが Godot のゲームを、撮って、押して、初見で遊んで確かめる。**
Claude Code 用のプラグインです。何も教えていない AI にゲームを遊ばせて、初めての人がどこで迷うかを報告させます。

![何も教えていない AI が猫のゲームを遊ぶと「分からなかった」。直したあと、別の AI はルールを正しく言えた](docs/demo/demo.ja.gif)

*[サンプルのゲーム](examples/sleepy-cat)で実際に回した結果です。[AI の実況つきの長い動画（英語）](docs/demo/demo.mp4)*

[English README](README.md)

## なぜ要るのか

Claude Code は GDScript をいくらでも書けますが、ゲームの画面を見ず、何も押しません。「できました」と言って、誰にも使えない画面を渡してきます。しかも画面を見られたとしても、AI はゲームの仕組みを知っているので、初めての人に伝わるかどうかは判断できません。作ったあなたも同じです。

## 何ができるか

1. **画面を撮る**: `godot-kit shot out.png --after 3` で、ゲームを起動して 3 秒後の画面を保存します。AI がその画像を読んで、表示崩れ・文字のはみ出し・真っ黒な画面に自分で気づきます。
2. **押す**: `--tap=360,800,2`（2 秒後にこの位置をタップ）のほか、長押し・スワイプ・クリック・ホバー・キー入力を、動いているゲームに流し込みます。ボタンが本当に効くかを AI が自分で確かめます。`godot-kit record` で動画も撮れます。
3. **初見プレイテスト**（`playtest` スキル。これが一番の売り）: ゲームのことを何も知らない別の AI に 1 と 2 だけを渡して遊ばせます。何を押したか、何を期待したか、どこで迷ったかが返ってきます。

ほかに、上の全部が最初から動くひな形、スクリプトエラーの確認、UI 部品を同じ画風で作る画像生成、作り直しになった経験から来た約 80 行の決まりも入っています。意図して小さくしています。スキル 6 つ、コマンド 1 つ。役職エージェント・フック・工程の関門はありません。

## 初見プレイテストで見つかること

[`examples/sleepy-cat`](examples/sleepy-cat) は、わざと分かりにくく作った小さなゲームです。何も知らされていないエージェント 2 体に、スクショだけで遊ばせました。報告の全文は [`playtests/01.md`](examples/sleepy-cat/playtests/01.md) と [`02.md`](examples/sleepy-cat/playtests/02.md) にあります（英語）。

| | 1 回目（最初に書いた版） | 2 回目（直したあと） |
|---|---|---|
| 目的とルール | 「分からなかった」 | 自分の言葉で正しく言えた |
| 押せるものの発見 | 「押せると確かめられたものはなし」 | 2 つとも、すぐ見つけた |
| いちばん迷った所 | 「fish」を押した直後。「押し損ねたのかも分からない」 | 「ひどく迷うことはなかった」。それでも 1 つ見つけた:「赤になってから、どれだけ余裕があるのか分からない」 |

注目したいのは 1 回目です。「fish」は**ちゃんと効いていました**。3 回あげた猫は 15 秒でも目が開いていて、あげないと閉じます（[画像](docs/demo/plain_fed_vs_unfed.png)）。でもエージェントには、押しても何も変わらないように見え、効いたのかどうかも分かりませんでした。原因は、エサで変わる数字が誰にも見えなかったことです。答えを知っている作り手には、気づけない不具合です。

自分のゲームでも「初めての人に伝わる？」と頼めば、`playtest` スキルが読み込まれます。

## 入れ方

必要なもの: [Claude Code](https://code.claude.com)、Godot 4（`godot` が PATH にあること）、Python 3、Perl。Pillow と ffmpeg は任意。

```bash
claude plugin marketplace add kotaroyamazaki/godot-agent-kit
claude plugin install godot-agent-kit@godot-agent-kit
```

入れたら、Claude Code のセッションで:

```
> godot-kit doctor を実行して
```

`doctor` は、この環境で何が使えて何が足りないかを機能ごとに出します。`godot` が PATH にあれば設定は要りません。画像生成には `OPENAI_API_KEY` が要ります（下の「設定」）。

## 使い方

ふつうの言葉で Claude に頼めば、合うスキルが読み込まれます。

| 頼み方 | スキル | 起きること |
|---|---|---|
| 「cat-patrol という新しいゲームを始めて」 | `godot-agent-kit:new` | ひな形から作り、先に設計を埋める |
| 「タイトル画面が崩れていないか見て」 | `godot-agent-kit:check` | スクリプトエラー確認、スクショ、Claude が画像を読む |
| 「スタートを押して店が開くか確かめて」 | `godot-agent-kit:check` | 本物の入力を流し、前後を撮る |
| 「初めての人に伝わる？」 | `godot-agent-kit:playtest` | 何も知らされていないサブエージェントが遊んで報告 |
| 「コインのアイコンを作って」 | `godot-agent-kit:assets` | 画像を作り、縮め、透過を確かめる |
| 「コアの遊びを設計して」「分かりにくいと言われた」 | `godot-agent-kit:rules` | 決まりを読み込む |
| 「Steam のタグを見直して」 | `godot-agent-kit:steam-tags` | 似たゲームと比べて 20 個を選んで並べ、タグウィザードで設定する |

### コマンド

プラグインを入れると、Claude のシェルで `godot-kit` が使えます。自分のターミナルでも使うなら `godot-kit setup --link`。

```bash
godot-kit new cat-patrol "ねこパトロール" --lang ja   # --landscape で 1280x720 の PC 向け
godot-kit check                                # ゲームの tools/check.sh、無ければスクリプトエラー確認
godot-kit shot shots/title.png --after 2
godot-kit shot shots/play.png --after 1 --every 1 --count 8 -- --tap=360,1100,2 --key=Enter,4
godot-kit record 45                            # 自動プレイ 45 秒を mp4 に
godot-kit image _src/coin.png "金貨、リソグラフ風" --transparent --resize 128x128
godot-kit doctor
```

### 既にあるゲームで使う

`check`・`parse`・`image` は、どの Godot 4 プロジェクトでもそのまま動きます。スクショと入力の再生にはファイルが 1 つ要ります。`template/scripts/shot.gd` をゲームにコピーし、`Shot` という名前のオートロードに登録してください。`--shot=...` や入力の引数を付けて起動したときだけ働くので、入れたままで問題ありません。

## 設定

全部任意です。`godot-kit setup` がいくつか質問して `~/.config/godot-kit/config.env` を作ります（[`config.env.example`](config.env.example)）。

API キーはこのリポジトリには置きません。次の順に探します。

1. 環境変数（`OPENAI_API_KEY`。代替の `GEMINI_API_KEY` は任意）
2. `~/.config/godot-kit/secrets.env`（`KEY=value` の行。`chmod 600` にする）
3. `config.env` の `GODOT_KIT_SECRETS_FILE` に書いたファイル（既に鍵を置いている場所があるとき）

ゲームごとの値は、ゲームの直下の `kit.env`（任意）に書きます: `GAME_ID`、`GAME_TITLE`、`GAME_DIR`（Godot プロジェクトがサブフォルダにあるとき）、`GODOT_CMD`（決まった Godot 本体を使うとき）。

## 決まりを常に読ませる

`rules` スキルは必要なときに `RULES.md` を読みます。毎回読ませたいなら、ゲーム置き場の上にある `CLAUDE.md` から読み込みます。

```
@/godot-kit rules が出したパス/RULES.md
```

日本語で読みたいなら `RULES.ja.md` を指してください。マーケットプレイス経由で入れた場合は更新のたびにパスが変わるので、この使い方ではリポジトリを `git clone` して `claude plugin marketplace add ./godot-agent-kit` とするほうが安定します。

## 対応環境

macOS と Godot 4.6 / 4.7 で作り、確かめています。中身は bash と Python なので Linux（画面あり、または xvfb）でも動くはずですが、まだ試していません。Windows は WSL 経由以外は対象外です。

## これは何ではないか

スタジオごっこではありません。プロデューサー役やデザイナー役のエージェント、承認の関門、フックはありません。そういうものが欲しければ Claude Code Game Studios のような大きなテンプレートがあります。godot-kit が扱うのは、エージェントが助けなしにはできない部分だけです。ゲームを見ること、押すこと、既に分かっている失敗を繰り返さないこと。

## 貢献

何かを足す基準は「2 本目のゲームでも要った」です。決まりは 1〜2 行で、実際に起きた失敗を名指しするものにしてください。[RULES.ja.md](RULES.ja.md)。

## ライセンス

MIT
