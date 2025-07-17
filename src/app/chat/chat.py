# 必要なライブラリをインポート
from flask import Blueprint, render_template, request, jsonify, session
import app.chat.chatModel as chatModel
from datetime import datetime
from sqlalchemy import text
import database_acces as da

# エンジン取得
engine = da.connect_with_connector()

# Blueprintを作成
# 'chat'という名前のBlueprintを定義し、関連するテンプレートや静的ファイルの場所を指定します。
chat = Blueprint("chat", __name__,
                    template_folder='templates',
                    static_folder='static',
                    static_url_path='/chat/static')

# 仮のメモデータストア
# アプリケーションが実行されている間だけデータを保持する、一時的なメモのリストです。
# 実際のアプリケーションではデータベースを使用します。


folderid = 0
# '/chat'パスへのGETリクエストを処理
# chat.htmlテンプレートをレンダリングして返します。
@chat.route('/chat')
def index():
    return render_template('chat.html', current_page='chat')

# '/memo'パスへのGETリクエストを処理
# URLのクエリパラメータから'title'を取得し、memo.htmlテンプレートをレンダリングして返します。
@chat.route('/memo')
def memo():
    folderid_ = request.args.get('title', 'メモ') # デフォルト値を設定
    global folderid
    if(folderid_.isnumeric()):
        folderid = int(folderid_)
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT * FROM memo WHERE folderid = :folderid and userid = userid"),
            {"folderid": folderid,"userid": session["user_id"]}
        )
        memos = result.fetchall()
        # 必要に応じて整形

    memo_list = []
    for row in memos:
        memo_list.append({
            "id": row.memoid,
            "title": row.title,
            "content": row.content,
            "date": row.created_at,
            "ask_gemini": row.gemini
            # 他のカラムも必要に応じて
        })
        
    return render_template('memo.html', memos = memo_list, current_page='memo')

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
    with engine.connect() as conn:
        result = conn.execute(text("""
            SELECT GROUP_CONCAT(CONCAT(title, ': ', content) SEPARATOR '\n\n') AS all_text
            FROM memo
            WHERE folderid = :folderid and userid = :userid
        """), {"folderid": folderid, "userid": session["user_id"]})

        row = result.fetchall()
        all_text = str(row)
    a = chatModel.chat("チャット")
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
        a = chatModel.chat("チャット")
        content = a.chat(title+"："+content,"")

    if not title or not content:
        return jsonify({"error": "Title and content are required"}), 400
    
    today = datetime.now().strftime("%Y/%m/%d")

    with engine.begin() as conn:
        global folderid
        conn.execute(text("""
            INSERT INTO memo (userid, folderid, title, content, gemini, created_at)
            VALUES (:userid, :folderid, :title, :content, :gemini, :created_at)
        """), {
            "userid": session["user_id"],
            "folderid": folderid,
            "title": title,
            "content": content,
            "gemini": ask_gemini,
            "created_at": today,
        })
    with engine.connect() as conn:
        result = conn.execute(text("""SELECT * FROM memo where userid = :user_id
            """), {
                "user_id": session["user_id"] 
            })
    rows = result.fetchall()  # 全行取得
    row = rows[-1]
    new_memo = {
        "id": row.memoid,
        "title": row.title,
        "content": row.content,
        "date": row.created_at,
        "ask_gemini": row.gemini
    }
    return jsonify(new_memo), 201

# '/api/memos/<int:memo_id>'パスへのPUTリクエストを処理
# 指定されたIDのメモを更新します。
@chat.route("/api/memos/<int:memo_id>", methods=["PUT"])
def update_memo(memo_id):
    data = request.get_json()
    title = data.get("title")
    content = data.get("content")
    ask_gemini_from_request = data.get("ask_gemini")

    with engine.connect() as conn:
        conn.execute(text("""
            UPDATE memo
            SET title = :title, content = :content
            WHERE memoid = :memoid
        """), {
            "title": title,
            "content": content,
            "memoid": memo_id
        })
        conn.commit()  # 明示的にコミットが必要な場合（DBによる）
    
    with engine.connect() as conn:
        result = conn.execute(text("SELECT * FROM memo WHERE memoid = :memoid"), {"memoid": memo_id})
        row = result.fetchone()  # 一件だけ取得
    memo = {
        "id": row.memoid,
        "title": row.title,
        "content": row.content,
        "date": row.created_at,
        "ask_gemini": row.gemini
    }

    return jsonify(memo), 200

    # return jsonify({"error": "Memo not found"}), 404

# '/api/memos/<int:memo_id>'パスへのDELETEリクエストを処理
# 指定されたIDのメモを削除します。
@chat.route("/api/memos/<int:memo_id>", methods=["DELETE"])
def delete_memo(memo_id):
    with engine.connect() as conn:
        conn.execute(text("DELETE FROM memo WHERE memoid = :memoid"), {
            "memoid": memo_id
        })
        conn.commit()


    global folderid
    with engine.connect() as conn:
        result = conn.execute(
            text("SELECT * FROM memo WHERE folderid = :folderid and userid = :userid"),
            {"folderid": folderid,"userid": session["user_id"]}
        )
        memos = result.fetchall()
        # 必要に応じて整形

    memo_list = []
    for row in memos:
        memo_list.append({
            "id": row.memoid,
            "title": row.title,
            "content": row.content,
            "date": row.created_at,
            "ask_gemini": row.gemini
            # 他のカラムも必要に応じて
        })

    
    return jsonify({"message": "Memo deleted"}), 200