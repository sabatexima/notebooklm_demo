# My Flask App

これは Flask を使って作られたシンプルなWebアプリケーションだよ。

## 概要

"こんにちは、世界！" と表示するだけの簡単なWebページなんだ。
Dockerを使って環境を構築できるようになっているよ。

## 使い方

### Dockerを使う場合

1. **Dockerイメージをビルドする**

   ```bash
   sh start.sh build
   ```

2. **コンテナを実行する**

   すでにイメージがある場合は、`build` なしで実行できるよ。

   ```bash
   sh start.sh
   ```

   ブラウザで `http://localhost:8080` にアクセスすると、ページが見れるはずだよ。

### ローカルで動かす場合

1. **必要なライブラリをインストールする**

   ```bash
   pip install -r requirements.txt
   ```

2. **アプリケーションを起動する**

   ```bash
   python app.py
   ```

   ブラウザで `http://localhost:8080` にアクセスしてね。

## ファイル構成

```
.
├── app.py              # アプリケーションのエントリポイント
├── Dockerfile          # Dockerの設定ファイル
├── README.md           # このファイル
├── requirements.txt    # Pythonの依存ライブラリ
├── start.sh            # 起動用スクリプト
└── app/
    ├── __init__.py
    ├── templates/
    │   └── index.html  # 表示するHTML
    └── views/
        └── sample.py   # FlaskのBlueprintを使ったルーティング
```
