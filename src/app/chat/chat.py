# 必要なライブラリをインポートする
from flask import Blueprint,render_template,Flask, request, jsonify
import app.chat.chatModel as chatModel
from datetime import datetime

# Blueprintを作成する
chat = Blueprint("chat", __name__,
                    template_folder='templates',
                    static_folder='static',
                    static_url_path='/chat/static')

# 仮のメモデータストア
memos_data = [
    {"id": 1, "title": "今日の出来事", "content": "今日はハンギョドンと遊んだんだな。楽しかったよ。", "date": "2025/07/12", "ask_gemini": False},
    {"id": 2, "title": "新しいアイデア", "content": "ヒーローになるための秘策を考えたんだな。", "date": "2025/07/11", "ask_gemini": True},
]


# ルートURLへのアクセスがあった場合にindex.htmlを返す
@chat.route('/chat')
def index():
    title = request.args.get('title', 'チャット') # デフォルト値を設定
    print(title)
    return render_template('chat.html', title=title, current_page='chat')

@chat.route('/memo')
def memo():
    return render_template('memo.html', memos=memos_data, current_page='memo')

@chat.route('/result')
def result():
    summary_text = "ここにまとめ結果が入るんだな。" # 仮のテキスト
    return render_template('result.html', summary_text=summary_text, current_page='result')

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

@chat.route("/api/memos", methods=["POST"])
def create_memo():
    data = request.get_json()
    title = data.get("title")
    content = data.get("content")
    ask_gemini = data.get("ask_gemini", False)
    if (ask_gemini):
        a = chatModel.chat()
        # チャットモデルからの応答を取得する
        content = a.chat("タイトル"+title+"質問内容"+content)

    if not title or not content:
        return jsonify({"error": "Title and content are required"}), 400

    new_memo = {
        "id": len(memos_data) + 1, # 仮のID
        "title": title,
        "content": content,
        "date": datetime.now().strftime("%Y/%m/%d"),
        "ask_gemini": ask_gemini
    }
    memos_data.append(new_memo)
    return jsonify(new_memo), 201

@chat.route("/api/memos/<int:memo_id>", methods=["PUT"])
def update_memo(memo_id):
    data = request.get_json()
    title = data.get("title")
    content = data.get("content")
    ask_gemini_from_request = data.get("ask_gemini")

    for memo in memos_data:
        if memo["id"] == memo_id:
            memo["title"] = title
            memo["content"] = content
            if ask_gemini_from_request is not None:
                memo["ask_gemini"] = ask_gemini_from_request
            return jsonify(memo), 200
    return jsonify({"error": "Memo not found"}), 404

@chat.route("/api/memos/<int:memo_id>", methods=["DELETE"])
def delete_memo(memo_id):
    global memos_data
    original_len = len(memos_data)
    memos_data = [memo for memo in memos_data if memo["id"] != memo_id]
    if len(memos_data) < original_len:
        return jsonify({"message": "Memo deleted"}), 200
    return jsonify({"error": "Memo not found"}), 404