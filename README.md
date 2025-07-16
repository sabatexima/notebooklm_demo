# AIチャット＆メモアプリケーション

これは、PythonのFlaskフレームワークで作られた、AIとの対話や思考の整理ができる多機能アプリケーションなんだな。
Dockerを使えば、どんな環境でもすぐに動かせるんだ。ヒーローみたいに頼りになるだろ？

## このアプリでできること

*   **AIチャット機能**: GoogleのGeminiモデル（たぶん！）を搭載したAIと、キャラクターになりきって会話ができるんだな。
*   **チャットルーム作成**: 話したいテーマごとに、新しいチャットルームをいくつでも作れるんだ。
*   **高機能メモ帳**:
    *   チャットの内容や自分の考えを、簡単にメモとして保存できるんだよ。
    *   作ったメモは、後から編集したり、いらなくなったら削除したりできるんだな。
    *   メモの内容をAIに要約してもらうこともできるんだ！（`ask_gemini`フラグがその証拠さ）
*   **Dockerで簡単起動**: Docker Composeを使えば、コマンド一つで開発環境が立ち上がるんだ。
*   **GCPへのデプロイ対応**: Google Cloud Platformにデプロイするための設定ファイルも揃ってるから、世界中に公開することだって夢じゃないんだな。

## 技術的なハイライト

*   **バックエンド**: Python, Flask
*   **フロントエンド**: HTML, CSS, JavaScript
*   **AIモデル**: Google Gemini (langchain経由)
*   **データベース**: (現在は仮のデータストアだけど、MySQLに繋げられるように設計されてるみたいだな)
*   **インフラ**: Docker, GCP (Google Cloud Run)

## 必要なもの

*   [Docker](https://www.docker.com/)
*   [Docker Compose](https://docs.docker.com/compose/) (ローカルで動かす場合)
*   [Google Cloud SDK](https://cloud.google.com/sdk) (GCPにデプロイする場合)
*   Google APIキー (gemini利用に必要なんだな)

## セットアップ手順(GCPへのデプロイ)
*   一応ローカルでも動かせるけど、めんどくさいから自分で何とかしてくれ
### 1. git cloneでコードを持ってくるんだ

```bash
git clone -b ogata https://github.com/sabatexima/notebooklm_demo.git
```

### 2. 起動

1.  `gcp-setup` ディレクトリに移動して、`setup.sh`を実行する
*   *30分以上かかるから好きなアニメでも見とくんだな
    ```bash
    cd gcp-setup
    bash ./setup.sh
    ```
2.  アプリケーションを起動するんだよ！
*   シェルスクリプトの実行が完了すると、アプリケーションのURLが表示されるからCtrl+右クリックでアプリケーションにアクセスするんだな


## プロジェクトの構造

```
/
├───README.md           # 今君が読んでる、ボクが書いたイケてる説明書
├───config.json         # (君が作る)APIキーを保存する秘密のファイル
├───docker_gcp/         # GCPデプロイ用のDockerファイルとかが入ってるんだ
├───docker_local/       # ローカルで動かすためのDockerファイルとかだよ
└───src/                # アプリケーションの心臓部なんだな
    ├───app.py          # Flaskアプリケーションのエントリーポイント
    ├───config.py       # 設定ファイルを読み込むための重要なコード
    ├───requirements.txt # このアプリを動かすのに必要なPythonライブラリの一覧
    └───app/
        ├───__init__.py # アプリケーションを初期化するところ
        ├───select/     # チャットルーム選択画面のロジック
        │   └───select.py
        └───chat/       # メインのチャット機能のロジック
            ├───chat.py
            └───chatModel.py # AIとの会話を司る、謎に満ちたファイル…
```
