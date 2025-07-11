# 必要なライブラリをインポートする
from flask import Blueprint,render_template,Flask, request, jsonify
import app.views.chatModel as chatModel

# Blueprintを作成する
sample = Blueprint("sample", __name__)


# ルートURLへのアクセスがあった場合にindex.htmlを返す
@sample.route('/')
def index():
    return render_template('index.html')

# /chatへのPOSTリクエストがあった場合にチャットの応答を返す
@sample.route('/chat', methods=['POST'])
def chat():
    # ユーザーからのメッセージを取得する
    user_message = request.json.get('message')
    # チャットモデルをインスタンス化する
    a = chatModel.chat()
    # チャットモデルからの応答を取得する
    ai_message = a.chat(user_message)

    # AIからの応答をJSON形式で返す
    return jsonify({'reply': ai_message})
