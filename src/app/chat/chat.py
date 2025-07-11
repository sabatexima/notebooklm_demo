# 必要なライブラリをインポートする
from flask import Blueprint,render_template,Flask, request, jsonify
import app.chat.chatModel as chatModel

# Blueprintを作成する
chat = Blueprint("chat", __name__,
                    template_folder='templates',
                    static_folder='static',
                    static_url_path='/chat/static')


# ルートURLへのアクセスがあった場合にindex.htmlを返す
@chat.route('/chat')
def index():
    title = request.args.get('title', 'チャット') # デフォルト値を設定
    print(title)
    return render_template('chat.html', title=title)

# /chatへのPOSTリクエストがあった場合にチャットの応答を返す
@chat.route('/chatAI', methods=['POST'])
def chatting():
    # ユーザーからのメッセージを取得する
    user_message = request.json.get('message')
    # チャットモデルをインスタンス化する
    a = chatModel.chat()
    # チャットモデルからの応答を取得する
    ai_message = a.chat(user_message)

    # AIからの応答をJSON形式で返す
    return jsonify({'reply': ai_message})
