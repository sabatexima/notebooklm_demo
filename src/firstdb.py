from sqlalchemy import text
import database_acces as da
# エンジン取得
engine = da.connect_with_connector()

# 接続テスト（例: 現在のユーザー名を取得）
try:
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS memo"))
        conn.execute(text("DROP TABLE IF EXISTS folder"))
        conn.execute(text("DROP TABLE IF EXISTS user"))

        conn.execute(text("""CREATE TABLE memo (
            memoid INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            userid TEXT,
            folderid INT,
            title VARCHAR(50),
            content TEXT,
            gemini BOOL,
            created_at TEXT
        );"""))
        
        conn.execute(text("""CREATE TABLE  folder(
            folderid INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            userid TEXT,
            title VARCHAR(50),
            content TEXT,
            created_at TEXT
        );"""))

        conn.execute(text("""CREATE TABLE user (
            userid INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            usernum TEXT,
            email VARCHAR(50)
        );"""))

        print("✅ 接続成功")
except Exception as e:
    print("接続失敗 ❌：", e)





