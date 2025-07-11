# 必要なライブラリをインポートする
import os
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.schema import (
    AIMessage,
    HumanMessage,
    SystemMessage
)

import json

# チャット機能を提供するクラス
class chat:

    # 安全にモデルを呼び出す
    def safe_invoke(self,model, messages):
        try:
            # モデルを呼び出す
            response = model.invoke(messages)
            return response
        except Exception as e:
            # エラーが発生した場合はエラーメッセージを返す
            return {"error": str(e)}

    # LLMモデルを設定する
    def setLlm(self,name):
        # model="gemini-1.5-pro"
        llm = ChatGoogleGenerativeAI(
            model=name,
            temperature=0,
            max_tokens=None,
            timeout=None,
            max_retries=2,
        )
        return llm
    # キャラクターを設定する
    def setChara(self,name):
        # JSONファイルを開いて読み込む
        with open("app/views/chara.json", "r", encoding="utf-8") as file:
            chara_data = json.load(file)

        # "user" のデータを取得
        # キャラクターの情報を取得
        user = chara_data.get("てぃま", {}) 
        return user

    # チャットを実行する
    def chat(self,text):
        # キャラクターを設定する
        user = self.setChara("aa")
        # LLMモデルを設定する
        llm = self.setLlm("gemini-2.5-flash")

        # メッセージを作成する
        messages = [
            SystemMessage(content=json.dumps(user, ensure_ascii=False)),
            HumanMessage(content=text)
        ]

        # モデルを呼び出す
        response = self.safe_invoke(llm, messages)


        # 応答のコンテンツを取得する
        chat_con = response.content

        # 応答を返す
        return chat_con
# chatlog.write(chat_log)