# 必要なライブラリをインポート
from flask import Blueprint, render_template, request, jsonify
import app.chat.chatModel as chatModel
from datetime import datetime

# Blueprintを作成
# 'chat'という名前のBlueprintを定義し、関連するテンプレートや静的ファイルの場所を指定します。
chat = Blueprint("chat", __name__,
                    template_folder='templates',
                    static_folder='static',
                    static_url_path='/chat/static')

# 仮のメモデータストア
# アプリケーションが実行されている間だけデータを保持する、一時的なメモのリストです。
# 実際のアプリケーションではデータベースを使用します。
memos_data = [
    {"id": 1, "title": "今日の出来事", "content": "今日はハンギョドンと遊んだんだな。楽しかったよ。", "date": "2025/07/12", "ask_gemini": False},
    {"id": 2, "title": "新しいアイデア", "content": "ヒーローになるための秘策を考えたんだな。", "date": "2025/07/11", "ask_gemini": True},
]

# '/chat'パスへのGETリクエストを処理
# chat.htmlテンプレートをレンダリングして返します。
@chat.route('/chat')
def index():
    return render_template('chat.html', current_page='chat')

# '/memo'パスへのGETリクエストを処理
# URLのクエリパラメータから'title'を取得し、memo.htmlテンプレートをレンダリングして返します。
@chat.route('/memo')
def memo():
    title = request.args.get('title', 'メモ') # デフォルト値を設定
    print(title)
    return render_template('memo.html', memos=memos_data, current_page='memo', title=title)

# '/result'パスへのGETリクエストを処理
# result.htmlテンプレートをレンダリングして返します。
@chat.route('/result')
def result():
    summary_text = "ここにまとめ結果が入るんだな。" # 仮のテキスト
    return render_template('result.html', summary_text=summary_text, current_page='result')

# '/chatAI'パスへのPOSTリクエストを処理
# ユーザーからのメッセージを受け取り、チャットモデルでAIの応答を生成し、JSON形式で返します。
@chat.route('/chatAI', methods=['POST'])
def chatting():
    user_message = request.json.get('message')
    all_text = "\n".join(f"{memo['title']}: {memo['content']}" for memo in memos_data)
    a = chatModel.chat("キャラ2")
    ai_message = a.chat(user_message,all_text)
    return jsonify({'reply': ai_message})

# '/api/memos'パスへのPOSTリクエストを処理
# 新しいメモを作成し、memos_dataリストに追加します。
@chat.route("/api/memos", methods=["POST"])
def create_memo():
    data = request.get_json()
    title = data.get("title")
    content = data.get("content")
    ask_gemini = data.get("ask_gemini", False)
    if (ask_gemini):
        a = chatModel.chat("キャラ")
        content = a.chat(title+"："+content,"")

    if not title or not content:
        return jsonify({"error": "Title and content are required"}), 400

    new_memo = {
        "id": len(memos_data) + 1,
        "title": title,
        "content": content,
        "date": datetime.now().strftime("%Y/%m/%d"),
        "ask_gemini": ask_gemini
    }
    memos_data.append(new_memo)
    return jsonify(new_memo), 201

# '/api/memos/<int:memo_id>'パスへのPUTリクエストを処理
# 指定されたIDのメモを更新します。
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

# '/api/memos/<int:memo_id>'パスへのDELETEリクエストを処理
# 指定されたIDのメモを削除します。
@chat.route("/api/memos/<int:memo_id>", methods=["DELETE"])
def delete_memo(memo_id):
    global memos_data
    original_len = len(memos_data)
    memos_data = [memo for memo in memos_data if memo["id"] != memo_id]
    if len(memos_data) < original_len:
        return jsonify({"message": "Memo deleted"}), 200
    return jsonify({"error": "Memo not found"}), 404