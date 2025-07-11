# 必要なライブラリをインポートする
import app
import os
from config import Config

# アプリケーションのインスタンスを取得する
app = app.get_app()

# このスクリプトが直接実行された場合にのみ、以下のコードを実行する
if __name__ == "__main__":
    # 設定情報を読み込む
    config = Config()
    # 環境変数にGoogle APIキーを設定する
    os.environ["GOOGLE_API_KEY"] = config.get('googleApiKey')
    # アプリケーションをデバッグモードで実行する
    app.run(host="0.0.0.0", port=8080, debug=True)
