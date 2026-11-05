# godot-agent-kit

**AI エージェントは Godot のコードを書くけれど、ゲームを遊ばない。それを遊べるようにして、さらに「何も知らない人」に遊ばせて報告させる。**

![初見のサブエージェントが猫のゲームを遊ぶ。直す前と直したあと](docs/demo/demo.gif)

*何も知らされていないサブエージェントが、スクショだけでゲームを遊び、どこで迷ったかを報告します。直したあと、別の初見エージェントがもう一度遊びます。どれも実際の結果と発言です。[動画](docs/demo/demo.mp4)*

[English README](README.md)

エージェントは GDScript をいくらでも書けますが、ゲームを見ず、何も押さないので、誰にも使えない画面を平気で渡してきます。godot-agent-kit はその欠けている部分を足します。

- **見る**: 実際の窓でゲームを開き、スクショや連番の一覧を撮って、それを読む。
- **触る**: 動いているゲームに本物の入力を流す（タップ・長押し・スワイプ・クリック・ホバー・キー）。
- **初めての人に聞く**: ゲームのことを何も知らないサブエージェントが、スクショだけを頼りに遊び、どこで迷ったかを報告する。
- **絵を作る**: UI 部品・キャラ・背景を、画像生成モデルで同じ画風に揃えて作る。
- **きれいに始める**: 上の全部が最初から動くひな形。
- **決まり**: 作り直しになった経験から来た約 80 行（手触り・チュートリアル・Godot の落とし穴・Git の安全）。

意図して小さくしています。スキル 6 つ、コマンド 1 つ。役職エージェント・フック・工程の関門はありません。

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
