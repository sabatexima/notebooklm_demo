# 必要なライブラリをインポート
from flask import Blueprint, render_template, request, jsonify, session
from sqlalchemy import text
import database_acces as da


# エンジン取得
engine = da.connect_with_connector()

# Blueprintを作成
# 'select'という名前のBlueprintを定義し、関連するテンプレートや静的ファイルの場所を指定します。
select = Blueprint("select", __name__,
                    template_folder='templates',
                    static_folder='static',
                    static_url_path='/select/static')

cards = []

# '/'パスへのGETリクエストを処理
# home.htmlテンプレートをレンダリングし、カードデータを渡します。
@select.route("/")
def index():
    print(session["user_id"] )
    with engine.connect() as conn:
        result = conn.execute(text("""SELECT * FROM folder WHERE userid = :user_id
            """), {
                "user_id": session["user_id"] 
            })
    rows = result.fetchall()  # 全行取得
    cards = []
    for row in rows:
        cards.append({
            "id": row.folderid,
            "emoji": row.title,
            "title": row.content,
            "date": row.created_at
        })
    return render_template("home.html", cards=cards)

# '/api/cards'パスへのPOSTリクエストを処理
# 新しいカードを作成し、cardsリストに追加します。
@select.route("/api/cards", methods=["POST"])
def create_card_api():
    data = request.get_json()
    emoji = data["emoji"]
    title = data["title"]
    import datetime
    print(session["user_id"])
    today = datetime.date.today().strftime("%Y/%m/%d")
    with engine.begin() as conn:
        conn.execute(text("""
            INSERT INTO folder ( userid, title, content, created_at)
            VALUES ( :userid, :title, :content, :created_at)
        """), {
            "userid": session["user_id"],
            "title": emoji,
            "content": title,
            "created_at": today,
        })
    with engine.connect() as conn:
        result = conn.execute(text("""SELECT * FROM folder WHERE userid = :user_id
            """), {
                "user_id": session["user_id"] 
            })
    rows = result.fetchall()  # 全行取得
    print(rows)
    row = rows[0]
    new_card={
        "id": row.folderid,
        "emoji": row.title,
        "title": row.content,
        "date": row.created_at
    }
    return jsonify(new_card), 201
