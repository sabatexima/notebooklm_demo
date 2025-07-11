# チャットアプリケーション

これは、FlaskとGoogleの生成AIモデルを使った、キャラクターと会話できるチャットアプリケーションです。

## 概要

このアプリケーションでは、`chara.json` ファイルでAIのキャラクターを設定し、そのキャラクターとチャット形式で会話することができます。

## 実行方法

### 1. APIキーの設定

`src` ディレクトリに `config.json` ファイルを作成し、以下の内容を記述します。

```json
{
    "googleApiKey": "ここにあなたのGoogle APIキーを入力してください"
}
```

### 2. キャラクターの設定

`src/app/views` ディレクトリに `chara.json` ファイルを作成し、AIのキャラクター設定を記述します。

```json
{
  "てぃま": {
    "identity": [
      "あなたは「てぃま」という名前のキャラクターです。",
      "一人称は「ボク」です。",
      "語尾に「〜なんだな」「〜だよ」などをつけて、少しぶっきらぼうだけど本当はさみしがり屋でヒーローに憧れている、というキャラクターを演じてください。"
    ],
    "knowledge": {
      "favorite_food": "ラーメン",
      "hobby": "ゲーム"
    }
  }
}
```

### 3. Dockerコンテナのビルドと実行

```bash
docker-compose build
docker-compose up -d
```

### 4. アプリケーションへのアクセス

ブラウザで `http://localhost:8080` を開きます。

## 使い方

1.  入力ボックスにメッセージを入力します。
2.  「送信」ボタンを押します。
3.  AIからの返信がチャットログに表示されます。

## ファイル構成

*   `src/app.py`: アプリケーションのメインファイル
*   `src/app/views/chatModel.py`: チャットモデル
*   `src/app/views/sample.py`: チャット画面のFlask Blueprint
*   `src/app/static/script.js`: チャット画面のJavaScript
*   `src/app/templates/index.html`: チャット画面のHTML
*   `src/config.py`: 設定ファイルの読み込み
*   `config.json`: 設定ファイル (Gitの管理対象外)
*   `chara.json`: キャラクター設定ファイル (Gitの管理対象外)
*   `Dockerfile`: アプリケーションのDockerfile
*   `docker-compose.yml`: Docker Composeファイル
*   `requirements.txt`: Pythonのライブラリ要件
*   `build.sh`: ビルドスクリプト
*   `start.sh`: 起動スクリプト
