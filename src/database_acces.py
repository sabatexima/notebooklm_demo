import os

from google.cloud.sql.connector import Connector, IPTypes
import pytds

import sqlalchemy
import json


def connect_with_connector() -> sqlalchemy.engine.base.Engine:
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "august-bot-462013-g2-66f3fafcd249.json"
    """
    Initializes a connection pool for a Cloud SQL instance of SQL Server.

    Uses the Cloud SQL Python Connector package.
    """
    # Note: Saving credentials in environment variables is convenient, but not
    # secure - consider a more secure solution such as
    # Cloud Secret Manager (https://cloud.google.com/secret-manager) to help
    # keep secrets safe.
    with open("db.json", "r") as f:
        DB_setting = json.load(f)

    instance_connection_name = DB_setting.get("instance_connection_name")
    db_user = DB_setting.get("db_user")
    db_pass = DB_setting.get("db_pass")
    db_name = DB_setting.get("db_name")

    ip_type = IPTypes.PRIVATE if os.environ.get("PRIVATE_IP") else IPTypes.PUBLIC

    # initialize Cloud SQL Python Connector object
    connector = Connector(ip_type=ip_type, refresh_strategy="LAZY")

    connect_args = {}
    # If your SQL Server instance requires SSL, you need to download the CA
    # certificate for your instance and include cafile={path to downloaded
    # certificate} and validate_host=False. This is a workaround for a known issue.
    if os.environ.get("DB_ROOT_CERT"):  # e.g. '/path/to/my/server-ca.pem'
        connect_args = {
            "cafile": os.environ["DB_ROOT_CERT"],
            "validate_host": False,
        }

    def getconn() -> pytds.Connection:
        conn = connector.connect(
            instance_connection_name,
            "pymysql",
            user=db_user,
            password=db_pass,
            db=db_name,
            **connect_args
        )
        return conn

    pool = sqlalchemy.create_engine(
        "mysql+pymysql://",
        creator=getconn,
        # ...
    )
    return pool

from sqlalchemy import text

# エンジン取得
engine = connect_with_connector()

# 接続テスト（例: 現在のユーザー名を取得）
try:
    with engine.connect() as conn:
        result = conn.execute(text("SELECT CURRENT_USER()"))
        print("✅ 接続成功：", result.fetchone()[0])
except Exception as e:
    print("接続失敗 ❌：", e)