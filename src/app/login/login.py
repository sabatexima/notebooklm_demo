from flask import Flask, Blueprint, redirect, request, session, url_for
from google.oauth2 import id_token
from google_auth_oauthlib.flow import Flow
import google.auth.transport.requests
import os
from sqlalchemy import text
import database_acces as da
import json


# エンジン取得
engine = da.connect_with_connector()


# Blueprintを作成
# 'chat'という名前のBlueprintを定義し、関連するテンプレートや静的ファイルの場所を指定します。
login = Blueprint("login", __name__,
                    template_folder='templates',
                    static_folder='static',
                    static_url_path='/login/static')



with open("auth.json", "r") as f:
    auth_setting = json.load(f)

GOOGLE_CLIENT_ID = auth_setting.get("client_id")

os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"


flow = Flow.from_client_secrets_file(
    "auth.json",
    scopes=["https://www.googleapis.com/auth/userinfo.email", "openid"],
    redirect_uri="https://notelm-90502666611.asia-northeast1.run.app/callback"
)

@login.route("/")
def index():
    if "user_email" in session:
            # DBセッションを取得して処理
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT * FROM user WHERE usernum = :user_id
            """), {
                "user_id": session["user_id"] 
            }).fetchone()

            if not result:
                conn.execute(text("""
                    INSERT INTO user (usernum, email)
                    VALUES (:user_id, :email)
                """), {
                    "user_id": session["user_id"] ,
                    "email": session["user_email"] ,
                })
                conn.commit()
        return redirect(url_for("select.index"))
    return '<a href="/loging">Googleでログイン</a>'
    # return redirect(url_for("select.index"))

@login.route("/loging")
def loging():
    authorization_url, state = flow.authorization_url()
    session["state"] = state
    return redirect(authorization_url)

@login.route("/callback")
def callback():
    flow.fetch_token(authorization_response=request.url)

    if session["state"] != request.args["state"]:
        return "State mismatch", 400

    credentials = flow.credentials
    request_session = google.auth.transport.requests.Request()
    id_info = id_token.verify_oauth2_token(
        credentials._id_token, request_session, GOOGLE_CLIENT_ID
    )

    session["user_email"] = id_info.get("email")
    session["user_id"] = id_info.get("sub")  # GoogleアカウントID（一意）

    return redirect(url_for("select.index"))

@login.route("/logout")
def logout():
    session.clear()
    return redirect("/")

