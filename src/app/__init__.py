# FlaskとBlueprintをインポート
from flask import Flask
from app.chat.chat import chat
from app.select.select import select
from app.login.login import login

# アプリケーションのインスタンスを生成
# Flaskアプリケーションのインスタンスを作成し、Blueprintを登録する関数です。
def get_app():
    app = Flask(__name__)
    app.secret_key = "Saibaiki1161"
    _register_blueprint(app)
    return app

# Blueprintを登録
# アプリケーションに各Blueprintを登録するヘルパー関数です。
def _register_blueprint(app):
    app.register_blueprint(login,url_prefix='/')
    # select BlueprintをルートURL('/')に登録します。
    app.register_blueprint(select,url_prefix='/select')
    # chat Blueprintを'/chat'というURLプレフィックスで登録します。
    app.register_blueprint(chat,url_prefix='/chat')