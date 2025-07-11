import os
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.schema import (
    AIMessage,
    HumanMessage,
    SystemMessage
)

import json

class chat:

    def safe_invoke(self,model, messages):
        try:
            # モデルを呼び出す
            response = model.invoke(messages)
            return response
        except Exception as e:
            # エラーが発生した場合はエラーメッセージを返す
            return {"error": str(e)}

    def setLlm(self,name):
        # model="gemini-2.5-pro"
        llm = ChatGoogleGenerativeAI(
            model=name,
            temperature=0,
            max_tokens=None,
            timeout=None,
            max_retries=2,
        )
        return llm
    def setChara(self,name):
        # JSONファイルを開いて読み込む
        with open("app/views/chara.json", "r", encoding="utf-8") as file:
            chara_data = json.load(file)

        # "user" のデータを取得
        # キャラクターの情報を取得
        user = chara_data.get("てぃま", {}) 
        return user

    def chat(self,text):
        user = self.setChara("aa")
        llm = self.setLlm("gemini-2.5-flash")

        messages = [
            SystemMessage(content=json.dumps(user, ensure_ascii=False)),
            HumanMessage(content=text)
        ]

        response = self.safe_invoke(llm, messages)


        chat_con = response.content

        return chat_con
# chatlog.write(chat_log)