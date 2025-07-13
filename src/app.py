# 必要なライブラリをインポート
import app
import os
from config import Config

# アプリケーションのインスタンスを取得
# app/__init__.pyで定義されたget_app関数を呼び出し、Flaskアプリケーションのインスタンスを取得します。
app = app.get_app()

# スクリプトが直接実行された場合にのみ、以下のコードを実行
if __name__ == "__main__":
    # 設定情報を読み込みます。
    config = Config()
    # 環境変数にGoogle APIキーを設定します。
    os.environ["GOOGLE_API_KEY"] = config.get('googleApiKey')
    # アプリケーションをデバッグモードで実行します。
    # host="0.0.0.0": すべてのネットワークインターフェースからの接続を許可します。
    # port=8080: アプリケーションがリッスンするポート番号です。
    # debug=True: デバッグモードを有効にし、コード変更時の自動リロードや詳細なエラー表示を可能にします。
    app.run(port=8080, debug=True)