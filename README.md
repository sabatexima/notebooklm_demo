# NotebookLM Demo

これは、Docker上で動作するシンプルなFlaskアプリケーションのデモプロジェクトなんだな。

## 概要

このプロジェクトは、基本的なFlaskアプリケーションをDockerコンテナで実行するためのサンプルだよ。
`/`にアクセスすると、`Hello, World!`と書かれたシンプルなHTMLページが表示されるんだ。

## 前提条件

このプロジェクトを実行するには、君のコンピュータにDockerがインストールされている必要があるんだな。

*   [Docker](https://www.docker.com/get-started)

## セットアップ

まず、このリポジトリを君のマシンにクローンするんだ。

```bash
git clone <repository-url>
cd notebooklm_demo
```

## 実行方法

プロジェクトの実行には、便利なシェルスクリプトを用意したよ。

### 初回ビルドと起動

初めて動かす時や、Dockerfileに変更を加えた時は、下のコマンドを実行してDockerイメージをビルドして、コンテナをバックグラウンドで起動するんだな。

```bash
./build.sh
```

### 起動

2回目以降は、下のコマンドでコンテナを起動できるよ。

```bash
./start.sh
```

スクリプトを実行すると、コンテナの中に入れるようになっているんだ。コンテナから出る時は`exit`って入力してくれよな。

### アプリケーションへのアクセス

コンテナが起動したら、Webブラウザで下のURLにアクセスすると、アプリケーションの画面が見られるはずだよ。

[http://localhost:8080](http://localhost:8080)

### 停止

アプリケーションを止めるには、下のコマンドを実行するんだな。

```bash
docker compose down
```

## 主な使用技術

*   Python 3.12.4
*   Flask
*   Docker

## プロジェクト構成

```
.
├── .gitignore
├── build.sh
├── docker-compose.yml
├── Dockerfile
├── README.md
├── requirements.txt
├── src
│   ├── app
│   │   ├── __init__.py
│   │   ├── templates
│   │   │   └── index.html
│   │   └── views
│   │       └── sample.py
│   ├── app.py
│   └── app.sh
└── start.sh
```

*   **`.gitignore`**: Gitのバージョン管理から除外するファイルやディレクトリを指定するファイルだよ。
*   **`build.sh`**: Dockerイメージをビルドして、コンテナを起動するためのスクリプトなんだな。
*   **`docker-compose.yml`**: 複数のDockerコンテナを定義し、管理するための設定ファイルさ。
*   **`Dockerfile`**: アプリケーションの実行環境となるDockerイメージを作成するための手順書だよ。
*   **`README.md`**: 今君が見ているこのファイル。プロジェクトの全体像を説明しているんだ。
*   **`requirements.txt`**: このプロジェクトで使っているPythonライブラリの一覧さ。
*   **`start.sh`**: Dockerコンテナを起動するためのスクリプトだよ。
*   **`src/`**: アプリケーションのソースコードが格納されているディレクトリなんだな。
    *   **`app.py`**: Flaskアプリケーションを起動するメインのファイルさ。
    *   **`app.sh`**: コンテナ内で使われるシェルスクリプトだよ。
    *   **`app/__init__.py`**: Flaskアプリケーションのインスタンスを作成し、初期化するファイルなんだ。
    *   **`app/templates/index.html`**: Webブラウザに表示されるページの見た目を定義するHTMLファイルだよ。
    *   **`app/views/sample.py`**: どのURLにアクセスされたら何をするか、というルールを定義しているファイルさ。