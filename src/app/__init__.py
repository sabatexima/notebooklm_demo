# FlaskとBlueprintをインポートする
from flask import Flask
from app.chat.chat import chat
from app.select.select import select


# アプリケーションのインスタンスを生成する
def get_app():
    # Flaskアプリケーションのインスタンスを生成する
    app = Flask(__name__)
    # Blueprintを登録する
    _register_blueprint(app)
    # アプリケーションのインスタンスを返す
    return app


# Blueprintを登録する
def _register_blueprint(app):
    # sample Blueprintを登録する
    app.register_blueprint(select,url_prefix='/')
    app.register_blueprint(chat,url_prefix='/chat')
