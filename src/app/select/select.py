# 必要なライブラリをインポートする
from flask import Blueprint,render_template,Flask, request, jsonify

# Blueprintを作成する
select = Blueprint("select", __name__)


# ルートURLへのアクセスがあった場合にindex.htmlを返す
@select.route('/')
def index():
    return render_template('index.html')

