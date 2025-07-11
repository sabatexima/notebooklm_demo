# 必要なライブラリをインポート
from flask import Blueprint, render_template, request, jsonify

# Blueprintを作成
# 'select'という名前のBlueprintを定義し、関連するテンプレートや静的ファイルの場所を指定します。
select = Blueprint("select", __name__,
                    template_folder='templates',
                    static_folder='static',
                    static_url_path='/select/static')

# カードデータ（仮データ）
# アプリケーションが実行されている間だけデータを保持する、一時的なカードのリストです。
# 実際のアプリケーションではデータベースを使用します。
cards = [
    {"id": 1, "emoji": "👻", "title": "新情報源", "date": "2025/07/11", "source_count": 1},
    {"id": 2, "emoji": "💻", "title": "オフラインアップ<br>グレード手順", "date": "2025/07/09", "source_count": 1},
    {"id": 3, "emoji": "💻", "title": "オフラインアップ<br>グレード手順", "date": "2025/07/09", "source_count": 1},
]

# 次に割り当てるカードID
# 既存のカードのIDの最大値に基づいて、新しいカードに割り当てるIDを決定します。
next_card_id = max([card["id"] for card in cards]) + 1 if cards else 1

# '/'パスへのGETリクエストを処理
# home.htmlテンプレートをレンダリングし、カードデータを渡します。
@select.route("/")
def index():
    return render_template("home.html", cards=cards)

# '/api/cards'パスへのPOSTリクエストを処理
# 新しいカードを作成し、cardsリストに追加します。
@select.route("/api/cards", methods=["POST"])
def create_card_api():
    global next_card_id
    data = request.get_json()
    emoji = data["emoji"]
    title = data["title"]
    source_count = 1 # ソース数を1に固定
    import datetime
    today = datetime.date.today().strftime("%Y/%m/%d")

    new_card = {
        "id": next_card_id,
        "emoji": emoji,
        "title": title,
        "date": today,
        "source_count": source_count
    }
    cards.append(new_card)
    next_card_id += 1
    return jsonify(new_card), 201
