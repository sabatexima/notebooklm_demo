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
*   Google APIキー (`config.json`に設定が必要なんだな)

## セットアップ手順

### 1. APIキーの設定

プロジェクトのルートに `config.json` というファイルを作って、中にGoogleのAPIキーを書くんだ。

```json
{
  "googleApiKey": "ここに君のAPIキーを入れるんだな"
}
```

### 2. ローカル環境での起動

1.  このリポジトリを自分のマシンに持ってくるんだな。(クローン)
2.  `docker_local` ディレクトリに移動して、コンテナをビルドするんだ。
    ```bash
    cd docker_local
    ./local_build.sh
    ```
3.  アプリケーションを起動するんだよ！
    ```bash
    ./local_start.sh
    ```
4.  ブラウザで `http://localhost:8080` を開けば、君だけのAIチャット基地にアクセスできるんだな。

### 3. Google Cloud Platform (GCP) へのデプロイ

1.  GCPプロジェクトで、Artifact RegistryとCloud Runを有効にしておくんだな。
2.  `docker_gcp/gcp_pull.sh` の中の環境変数を、君のGCP環境に合わせて書き換えるんだ。
3.  次のコマンドで、DockerイメージをビルドしてGCPにプッシュするんだ。
    ```bash
    cd docker_gcp
    ./gcp_pull.sh
    ```
4.  最後に、このコマンドでCloud Runにデプロイするんだな！
    ```bash
    gcloud run deploy (君のサービス名) --image (gcp_pull.shで設定したイメージ名) --platform managed --region (君のリージョン) --allow-unauthenticated
    ```

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